#!/usr/bin/env python3

"""Token and cost statistics for local Claude Code conversations.

Reads the JSONL transcripts under ~/.claude/projects and reports token usage,
estimated cost at public list API rates, and a per-day / per-month breakdown.

Accounting notes, all of which matter for the numbers to be right:

* Assistant messages are deduplicated by `message.id`. A single message is
  written once per content block, and resuming or forking a session copies the
  earlier history into a new file, so the raw line count roughly doubles the
  real traffic.
* Usage is summed from `usage.iterations` rather than the top-level `usage`
  fields. The top-level figures describe only the attempt that produced the
  returned message, so on turns that consulted the advisor tool they omit the
  advisor's input and output tokens entirely. Advisor iterations are priced at
  the record's `advisorModel`.
* Subagent transcripts live in a nested directory but carry their parent's
  `sessionId`, so their tokens are folded into the session that spawned them
  rather than counted as sessions of their own.
* Cache writes are split by TTL: 1.25x base input for the 5-minute cache and
  2x for the 1-hour cache. Claude Code uses the 1-hour cache, which is the
  single largest cost term, so a flat multiplier is badly wrong.

The cost is an estimate at Anthropic's published list API rates. It is what the
same traffic would have cost through the API, not what a Claude subscription
was actually billed.
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone

DEFAULT_ROOT = os.path.expanduser('~/.claude/projects')

# USD per million tokens: (input, output). Anthropic first-party API list
# rates. Current models serve their full context window at these rates; there
# is no long-context tier to model.
RATES = {
    'claude-fable-5': (10.0, 50.0),
    'claude-mythos-5': (10.0, 50.0),
    'claude-mythos-preview': (10.0, 50.0),
    'claude-opus-5': (5.0, 25.0),
    'claude-opus-4-8': (5.0, 25.0),
    'claude-opus-4-7': (5.0, 25.0),
    'claude-opus-4-6': (5.0, 25.0),
    'claude-opus-4-5': (5.0, 25.0),
    'claude-opus-4-1': (15.0, 75.0),
    'claude-opus-4-0': (15.0, 75.0),
    'claude-3-opus': (15.0, 75.0),
    'claude-sonnet-5': (3.0, 15.0),
    'claude-sonnet-4-6': (3.0, 15.0),
    'claude-sonnet-4-5': (3.0, 15.0),
    'claude-sonnet-4-0': (3.0, 15.0),
    'claude-3-7-sonnet': (3.0, 15.0),
    'claude-haiku-4-5': (1.0, 5.0),
    'claude-3-5-haiku': (0.8, 4.0),
    'claude-3-haiku': (0.25, 1.25),
}

# Fast mode runs the same model at premium rates.
FAST_RATES = {
    'claude-opus-5': (10.0, 50.0),
    'claude-opus-4-8': (10.0, 50.0),
}

CACHE_WRITE_5M = 1.25
CACHE_WRITE_1H = 2.00
CACHE_READ = 0.10

# Models that never reach the API and so are never billed.
SYNTHETIC = {'<synthetic>', None, ''}

# A session that touched any of these produced edits, so it counts as coding.
EDIT_TOOLS = {'Edit', 'Write', 'MultiEdit', 'NotebookEdit'}

# Sessions started by something other than a person at a terminal: permission
# gatekeepers, title generation, hooks. They are billable but they are not work.
INTERACTIVE_ENTRYPOINT = 'cli'

DATE_SUFFIX = re.compile(r'-\d{8}$')


class Usage:
    """Token counters plus the cost they imply."""

    __slots__ = ('messages', 'input', 'write_5m', 'write_1h', 'read', 'output',
                 'cost', 'unpriced')

    def __init__(self):
        self.messages = 0
        self.input = 0
        self.write_5m = 0
        self.write_1h = 0
        self.read = 0
        self.output = 0
        self.cost = 0.0
        self.unpriced = 0

    def add(self, other):
        self.messages += other.messages
        self.input += other.input
        self.write_5m += other.write_5m
        self.write_1h += other.write_1h
        self.read += other.read
        self.output += other.output
        self.cost += other.cost
        self.unpriced += other.unpriced

    @property
    def total_tokens(self):
        return self.input + self.write_5m + self.write_1h + self.read + self.output

    @property
    def total_input(self):
        return self.input + self.write_5m + self.write_1h + self.read


def normalize_model(model):
    """Strip the decorations that keep a model id out of the rate table."""
    if not model:
        return model
    name = model.strip()
    name = name.replace('[1m]', '')
    if name.endswith('-fast'):
        name = name[:-len('-fast')]
    # Bedrock ids carry a provider prefix.
    if name.startswith('anthropic.'):
        name = name[len('anthropic.'):]
    name = DATE_SUFFIX.sub('', name)
    return name


def rates_for(model, speed):
    name = normalize_model(model)
    if speed == 'fast' and name in FAST_RATES:
        return FAST_RATES[name]
    return RATES.get(name)


def iter_records(root):
    """Yield (path, record) for every JSONL line under root."""
    for dirpath, _, filenames in os.walk(root):
        for filename in sorted(filenames):
            if not filename.endswith('.jsonl'):
                continue
            path = os.path.join(dirpath, filename)
            with open(path, encoding='utf-8', errors='replace') as handle:
                for line in handle:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        yield path, json.loads(line)
                    except ValueError:
                        continue


def local_day(timestamp):
    """Bucket an ISO-8601 UTC timestamp into a local calendar day."""
    if not timestamp:
        return None
    try:
        parsed = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone().strftime('%Y-%m-%d')


def price(entry, model, speed, stats):
    """Add one usage iteration to stats, priced at model's rates."""
    cache = entry.get('cache_creation') or {}
    write_5m = cache.get('ephemeral_5m_input_tokens', 0)
    write_1h = cache.get('ephemeral_1h_input_tokens', 0)
    if not cache:
        # Older transcripts omit the split; the harness uses the 1h cache.
        write_1h = entry.get('cache_creation_input_tokens', 0)

    fresh = entry.get('input_tokens', 0)
    read = entry.get('cache_read_input_tokens', 0)
    output = entry.get('output_tokens', 0)

    stats.input += fresh
    stats.write_5m += write_5m
    stats.write_1h += write_1h
    stats.read += read
    stats.output += output

    rates = rates_for(model, speed)
    if rates is None:
        if normalize_model(model) not in SYNTHETIC:
            stats.unpriced += fresh + write_5m + write_1h + read + output
        return

    rate_in, rate_out = rates
    stats.cost += (
        fresh * rate_in
        + write_5m * rate_in * CACHE_WRITE_5M
        + write_1h * rate_in * CACHE_WRITE_1H
        + read * rate_in * CACHE_READ
        + output * rate_out
    ) / 1_000_000


def collect(root, since, until):
    """Walk every transcript once and build all the breakdowns."""
    seen = set()
    by_model = defaultdict(Usage)
    by_day = defaultdict(Usage)
    by_session = defaultdict(Usage)
    by_project = defaultdict(Usage)
    session_meta = {}
    coding_sessions = set()
    all_sessions = set()
    unknown_models = defaultdict(int)
    lines_seen = 0
    undated = 0
    first_day = None
    last_day = None

    for path, record in iter_records(root):
        lines_seen += 1
        session = record.get('sessionId') or os.path.basename(path)[:-len('.jsonl')]
        # Subagent transcripts live in a nested directory; bill them to the
        # project they were spawned from, not to the nested directory name.
        project = os.path.relpath(path, root).split(os.sep)[0]
        record_type = record.get('type')

        meta = session_meta.setdefault(
            session, {'project': project, 'title': None, 'entrypoint': None})
        if record_type == 'ai-title' and record.get('aiTitle'):
            meta['title'] = record['aiTitle']
        if meta['entrypoint'] is None and record.get('entrypoint'):
            meta['entrypoint'] = record['entrypoint']

        # Files written through Bash leave no Edit block but do leave a delta.
        if record_type == 'file-history-delta':
            coding_sessions.add(session)
            continue

        if record_type != 'assistant':
            continue

        message = record.get('message') or {}
        message_id = message.get('id')
        if not message_id or message_id in seen:
            continue
        seen.add(message_id)

        day = local_day(record.get('timestamp'))
        if day is None:
            undated += 1
            continue
        if since and day < since:
            continue
        if until and day > until:
            continue

        all_sessions.add(session)
        for block in message.get('content') or []:
            if isinstance(block, dict) and block.get('type') == 'tool_use':
                if block.get('name') in EDIT_TOOLS:
                    coding_sessions.add(session)

        usage = message.get('usage') or {}
        model = message.get('model')
        speed = usage.get('speed')
        advisor_model = record.get('advisorModel') or model

        stats = Usage()
        stats.messages = 1
        iterations = usage.get('iterations')
        if iterations:
            for entry in iterations:
                entry_model = advisor_model if entry.get('type') == 'advisor_message' else model
                price(entry, entry_model, speed, stats)
        else:
            price(usage, model, speed, stats)

        if rates_for(model, speed) is None and normalize_model(model) not in SYNTHETIC:
            unknown_models[model] += 1

        by_model[normalize_model(model) or 'unknown'].add(stats)
        by_day[day].add(stats)
        by_session[session].add(stats)
        by_project[project].add(stats)

        first_day = day if first_day is None or day < first_day else first_day
        last_day = day if last_day is None or day > last_day else last_day

    return {
        'by_model': by_model,
        'by_day': by_day,
        'by_session': by_session,
        'by_project': by_project,
        'session_meta': session_meta,
        'coding_sessions': coding_sessions & all_sessions,
        'all_sessions': all_sessions,
        'unknown_models': unknown_models,
        'lines_seen': lines_seen,
        'undated': undated,
        'first_day': first_day,
        'last_day': last_day,
    }


def split_by_task(data):
    """Split sessions into automation, coding and exploratory work.

    Anything not started from an interactive terminal is automation: the
    permission gatekeeper, title generation and other harness-driven calls.
    Those are billable but they are not tasks anyone sat down to do, so they
    would otherwise swamp the session counts.
    """
    buckets = {'coding': Usage(), 'exploratory': Usage(), 'automation': Usage()}
    counts = {'coding': 0, 'exploratory': 0, 'automation': 0}
    for session, stats in data['by_session'].items():
        meta = data['session_meta'].get(session) or {}
        entrypoint = meta.get('entrypoint')
        if entrypoint is not None and entrypoint != INTERACTIVE_ENTRYPOINT:
            kind = 'automation'
        elif session in data['coding_sessions']:
            kind = 'coding'
        else:
            kind = 'exploratory'
        buckets[kind].add(stats)
        counts[kind] += 1
    return buckets, counts


def months(by_day):
    out = defaultdict(Usage)
    for day, stats in by_day.items():
        out[day[:7]].add(stats)
    return out


def human(n):
    """Compact token counts: 1.2M, 340.5K, 812."""
    if n >= 1_000_000:
        return '%.1fM' % (n / 1_000_000)
    if n >= 1_000:
        return '%.1fK' % (n / 1_000)
    return str(n)


def print_table(title, rows, label_width=28):
    print()
    print(title)
    header = '%-*s %7s %9s %9s %9s %9s %10s' % (
        label_width, '', 'msgs', 'input', 'cache-w', 'cache-r', 'output', 'cost')
    print(header)
    print('-' * len(header))
    for label, stats in rows:
        print('%-*s %7d %9s %9s %9s %9s %10s' % (
            label_width, label[:label_width], stats.messages,
            human(stats.input), human(stats.write_5m + stats.write_1h),
            human(stats.read), human(stats.output), '$%.2f' % stats.cost))


def report(data, args):
    total = Usage()
    for stats in data['by_model'].values():
        total.add(stats)

    tz = datetime.now().astimezone().tzname() or 'local'
    print('Claude Code usage  %s to %s  (days bucketed in %s)'
          % (data['first_day'] or '-', data['last_day'] or '-', tz))
    print('Estimated at public list API rates. Not actual subscription billing.')
    print()
    print('  transcript lines read %12d  (whole archive, before any date filter)'
          % data['lines_seen'])
    print('  assistant messages    %12d  (deduplicated by message id)' % total.messages)
    print('  sessions              %12d' % len(data['all_sessions']))
    if data['undated']:
        print('  skipped, no timestamp %12d  messages, excluded from every total'
              % data['undated'])
    print()
    print('  input, fresh          %12d tokens' % total.input)
    print('  input, cache write    %12d tokens  (5m %s / 1h %s)'
          % (total.write_5m + total.write_1h, human(total.write_5m), human(total.write_1h)))
    print('  input, cache read     %12d tokens' % total.read)
    print('  input, total          %12d tokens' % total.total_input)
    print('  output                %12d tokens' % total.output)
    print('  all tokens            %12d tokens' % total.total_tokens)
    print()
    print('  estimated cost        %12s' % ('$%.2f' % total.cost))
    days = len(data['by_day']) or 1
    print('  average per active day%12s  (%d active days)'
          % ('$%.2f' % (total.cost / days), days))

    if total.unpriced:
        print()
        print('  WARNING: %d tokens had no rate and are excluded from the cost.'
              % total.unpriced)
        for model, count in sorted(data['unknown_models'].items(), key=lambda kv: -kv[1]):
            print('    unpriced model: %s (%d messages)' % (model, count))

    print_table('BY MODEL',
                sorted(data['by_model'].items(), key=lambda kv: -kv[1].cost))

    print_table('BY MONTH',
                sorted(months(data['by_day']).items()))

    if args.days:
        rows = sorted(data['by_day'].items())[-args.days:]
    else:
        rows = sorted(data['by_day'].items())
    print_table('BY DAY', rows)

    buckets, counts = split_by_task(data)
    print_table('BY TASK TYPE', [
        ('%s (%d sessions)' % (kind, counts[kind]), buckets[kind])
        for kind in ('coding', 'exploratory', 'automation')
    ])
    print()
    print('  Interactive sessions count as coding if they used Edit/Write/MultiEdit/')
    print('  NotebookEdit or recorded a file change, and exploratory otherwise. Bash')
    print('  is neutral because it both reads and writes. Automation is everything')
    print('  the harness ran on its own (permission checks, title generation).')

    if args.projects:
        print_table('BY PROJECT',
                    sorted(data['by_project'].items(), key=lambda kv: -kv[1].cost)[:args.projects],
                    label_width=44)

    if args.sessions:
        rows = sorted(data['by_session'].items(), key=lambda kv: -kv[1].cost)[:args.sessions]
        labelled = []
        for session, stats in rows:
            meta = data['session_meta'].get(session) or {}
            labelled.append((meta.get('title') or session[:8], stats))
        print_table('TOP SESSIONS', labelled, label_width=44)


def as_json(data):
    def dump(stats):
        return {
            'messages': stats.messages,
            'input_tokens': stats.input,
            'cache_write_5m_tokens': stats.write_5m,
            'cache_write_1h_tokens': stats.write_1h,
            'cache_read_tokens': stats.read,
            'output_tokens': stats.output,
            'estimated_cost_usd': round(stats.cost, 4),
        }

    buckets, counts = split_by_task(data)

    total = Usage()
    for stats in data['by_model'].values():
        total.add(stats)

    return {
        'first_day': data['first_day'],
        'last_day': data['last_day'],
        'total': dump(total),
        'by_model': {k: dump(v) for k, v in data['by_model'].items()},
        'by_month': {k: dump(v) for k, v in sorted(months(data['by_day']).items())},
        'by_day': {k: dump(v) for k, v in sorted(data['by_day'].items())},
        'by_project': {k: dump(v) for k, v in data['by_project'].items()},
        'by_task_type': {
            kind: dict(dump(buckets[kind]), sessions=counts[kind])
            for kind in ('coding', 'exploratory', 'automation')
        },
        'unpriced_models': dict(data['unknown_models']),
    }


def main():
    parser = argparse.ArgumentParser(
        description='Token and cost statistics for local Claude Code conversations.')
    parser.add_argument('--root', default=DEFAULT_ROOT,
                        help='transcript directory (default: %(default)s)')
    parser.add_argument('--since', metavar='YYYY-MM-DD', help='ignore days before this')
    parser.add_argument('--until', metavar='YYYY-MM-DD', help='ignore days after this')
    parser.add_argument('--days', type=int, metavar='N',
                        help='show only the last N days in the daily table')
    parser.add_argument('--projects', type=int, nargs='?', const=15, metavar='N',
                        help='also break down by project directory (top N, default 15)')
    parser.add_argument('--sessions', type=int, nargs='?', const=15, metavar='N',
                        help='also list the costliest sessions (top N, default 15)')
    parser.add_argument('--json', action='store_true', help='emit JSON instead of a report')
    args = parser.parse_args()

    if not os.path.isdir(args.root):
        sys.exit('no transcript directory at %s' % args.root)

    data = collect(args.root, args.since, args.until)
    if not data['by_day']:
        sys.exit('no assistant messages found in the selected range')

    if args.json:
        json.dump(as_json(data), sys.stdout, indent=2)
        print()
    else:
        report(data, args)


if __name__ == '__main__':
    main()
