#!/usr/bin/env python3

"""AWS SSO device-code login, driven from a tmux popup.

Wired up as:

    bind-key A run-shell -b "~/.config/scripts/aws-sso.py --dispatch '#{client_tty}'"

--dispatch runs outside any popup so it can decide whether a popup is needed at all:
no aws binary means a status-line message, a still-valid cached token means a small
self-dismissing notice, and anything else means the real login popup.

The login itself streams `aws sso login` into the popup, copies the device code to the
system clipboard (OSC 52) and opens the verification URL in the desktop browser by
setting WezTerm's `open-web` user var (OSC 1337, consumed in wezterm/wezterm.lua).
Those sequences go straight to the outer client tty, unwrapped, so nothing depends on
tmux forwarding passthrough out of a popup pane.
"""

import base64
import configparser
import hashlib
import json
import os
import re
import select
import shlex
import shutil
import stat
import subprocess
import sys
import termios
import time
import tty
from datetime import datetime, timedelta, timezone

DEBUG = os.environ.get('DEBUG_AWS_SSO') == '1'
LOG_PATH = '/tmp/aws-sso-logs'

SELF = os.path.abspath(__file__)
FALLBACK_SESSION = 'dn'
AWS_FALLBACK = '/usr/local/bin/aws'

# Log in again once the cached token has this little left.
EXPIRY_MARGIN = timedelta(minutes=5)
# The notice popup goes away on a keypress or after this, whichever comes first.
NOTICE_TIMEOUT = 2.0

ANSI_RE = re.compile(r'\x1b\[[0-9;?]*[ -/]*[@-~]')
# Both patterns are line anchored: the URL one must not match the trailing
# "Successfully logged into Start URL: ..." line, and the code one must not match
# us-east-1, ssoins-..., or an account id.
URL_RE = re.compile(r'^[ \t]*(https?://\S+?)[ \t]*$', re.M)
CODE_RE = re.compile(r'^[ \t]*([A-Z0-9]{4}-[A-Z0-9]{4})[ \t]*$', re.M)


def log(msg):
    if not DEBUG:
        return
    try:
        os.makedirs(LOG_PATH, exist_ok=True)
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')
        with open(os.path.join(LOG_PATH, 'debug.log'), 'a') as f:
            f.write('%s %s\n' % (timestamp, msg))
    except Exception as e:
        print('Failed to write log: %s' % e, file=sys.stderr)


def tmux(*args):
    """Run a tmux command. Returns its stripped stdout, or None if it failed."""
    try:
        result = subprocess.run(['tmux'] + list(args),
                                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    except OSError as e:
        log('tmux %s: %s' % (list(args), e))
        return None
    if result.returncode != 0:
        log('tmux %s exited %d' % (list(args), result.returncode))
        return None
    return result.stdout.decode('utf-8', 'replace').strip()


def aws_path():
    found = shutil.which('aws')
    if found:
        return found
    if os.access(AWS_FALLBACK, os.X_OK):
        return AWS_FALLBACK
    return None


def resolve_session(explicit):
    if explicit:
        return explicit
    from_env = os.environ.get('AWS_SSO_SESSION')
    if from_env:
        return from_env
    parser = configparser.RawConfigParser()
    try:
        parser.read(os.path.expanduser('~/.aws/config'))
    except configparser.Error as e:
        log('could not parse ~/.aws/config: %s' % e)
        return FALLBACK_SESSION
    sessions = [s.split(None, 1)[1].strip()
                for s in parser.sections() if s.startswith('sso-session ')]
    if len(sessions) == 1:
        return sessions[0]
    return FALLBACK_SESSION


def token_expiry(session):
    """Expiry of the cached SSO token for `session`, or None if there isn't a usable one.

    The cache file is keyed by sha1 of the sso-session name. It also holds the access
    token, refresh token and client secret: expiresAt is the only field read, and
    nothing else from it is ever printed or logged.
    """
    digest = hashlib.sha1(session.encode('utf-8')).hexdigest()
    path = os.path.expanduser('~/.aws/sso/cache/%s.json' % digest)
    try:
        with open(path) as f:
            raw = json.load(f).get('expiresAt')
    except (OSError, ValueError) as e:
        log('no usable token cache for %s: %s' % (session, e))
        return None
    if not isinstance(raw, str):
        return None
    text = raw.strip()
    if text.endswith('UTC'):
        text = text[:-3] + '+00:00'
    elif text.endswith('Z'):
        text = text[:-1] + '+00:00'
    try:
        expiry = datetime.fromisoformat(text)
    except ValueError as e:
        log('unparseable expiresAt: %s' % e)
        return None
    if expiry.tzinfo is None:
        expiry = expiry.replace(tzinfo=timezone.utc)
    log('token for %s expires %s' % (session, expiry))
    return expiry


def resolve_tty(explicit):
    """Path of the terminal that should receive the escape sequences."""
    candidates = [explicit, os.environ.get('AWS_SSO_TTY')]
    if os.environ.get('TMUX'):
        candidates.append(tmux('display-message', '-p', '#{client_tty}'))
    candidates.append('/dev/tty')

    for path in candidates:
        if not path:
            continue
        try:
            mode = os.stat(path).st_mode
        except OSError:
            continue
        if stat.S_ISCHR(mode) and os.access(path, os.W_OK):
            log('using tty %s' % path)
            return path
    log('no writable tty found')
    return None


def b64(text):
    return base64.b64encode(text.encode('utf-8')).decode('ascii')


def osc52(text):
    return '\x1b]52;c;%s\x07' % b64(text)


def osc_open_web(url):
    return '\x1b]1337;SetUserVar=open-web=%s\x07' % b64(url)


def osc_notify(title, message):
    return '\x1b]777;notify;%s;%s\x1b\\' % (title, message)


def write_tty(tty_path, payload):
    """Write one payload to the terminal. Never fatal - this is a convenience layer."""
    if not tty_path or not payload:
        return False
    try:
        with open(tty_path, 'w') as f:
            f.write(payload)
            f.flush()
    except OSError as e:
        log('write to %s failed: %s' % (tty_path, e))
        return False
    return True


def extract(text):
    """Pull the device code and the plain verification URL out of aws's output."""
    text = ANSI_RE.sub('', text)

    code = None
    match = CODE_RE.search(text)
    if match:
        code = match.group(1)

    url = None
    for match in URL_RE.finditer(text):
        candidate = match.group(1)
        # --no-browser also prints an "autofill the code upon loading" URL. The code
        # belongs in the clipboard, so take the plain one.
        if 'user_code=' in candidate:
            continue
        url = candidate
        break

    return code, url


def announce(tty_path, code, url):
    payload = ''
    if code:
        # Clipboard before the browser, since opening it may steal focus.
        payload += osc52(code)
    if url:
        payload += osc_open_web(url)
    # One write: tmux is writing to this tty too, and a single small write cannot be
    # interleaved mid-sequence.
    write_tty(tty_path, payload)

    if code:
        tmux('set-buffer', '-b', 'aws-sso', code)
    if url:
        tmux('set-buffer', '-b', 'aws-sso-url', url)

    if code and url:
        print('\n  code %s copied - opening browser\n' % code)
    elif code:
        print('\n  code %s copied\n' % code)
    sys.stdout.flush()


def wait_key(timeout=None):
    """Block until a keypress, or `timeout` seconds if given, whichever comes first."""
    if not sys.stdin.isatty():
        if timeout:
            time.sleep(timeout)
        return
    fd = sys.stdin.fileno()
    saved = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        ready, _, _ = select.select([fd], [], [], timeout)
        if ready:
            os.read(fd, 1)
    except KeyboardInterrupt:
        pass
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, saved)


def notice(text):
    print('\n  %s\n' % text)
    sys.stdout.flush()
    wait_key(NOTICE_TIMEOUT)
    return 0


def remaining(expiry):
    """How much of the token is left, as '1h 12m' or '43m'."""
    minutes = int((expiry - datetime.now(timezone.utc)).total_seconds() // 60)
    hours, minutes = divmod(max(minutes, 0), 60)
    if hours:
        return '%dh %02dm' % (hours, minutes)
    return '%dm' % minutes


def popup(client_tty, flags, argv):
    command = ['display-popup']
    if client_tty:
        command += ['-c', client_tty]
    command += flags
    command.append(' '.join(shlex.quote(a) for a in argv))
    log('popup: %s' % command)
    if tmux(*command) is None:
        # A binding that silently does nothing is the worst outcome, so say something.
        tmux('display-message', 'aws-sso: could not open popup (DEBUG_AWS_SSO=1 for details)')


def dispatch(client_tty):
    session = resolve_session(None)

    if not aws_path():
        message = 'aws not found - install the AWS CLI'
        if tmux('display-message', message) is None:
            print(message, file=sys.stderr)
        return 0

    expiry = token_expiry(session)
    if expiry and expiry - datetime.now(timezone.utc) > EXPIRY_MARGIN:
        text = 'AWS SSO token valid for another %s' % remaining(expiry)
        popup(client_tty, ['-E', '-w', '60', '-h', '5'], [SELF, '--notice', text])
        return 0

    argv = [SELF, '--login', '--force', '--wait']
    if client_tty:
        argv += ['--tty', client_tty]
    argv.append(session)
    popup(client_tty, ['-EE', '-w', '80%', '-h', '60%', '-T', ' aws sso '], argv)
    return 0


def login(session, tty_path, force, wait=False):
    if not force:
        expiry = token_expiry(session)
        if expiry and expiry - datetime.now(timezone.utc) > EXPIRY_MARGIN:
            print('AWS SSO token valid for another %s (--force to log in anyway)'
                  % remaining(expiry))
            return 0

    aws = aws_path()
    if not aws:
        print('aws not found (looked for: aws on PATH, %s)' % AWS_FALLBACK,
              file=sys.stderr)
        return 127

    command = [aws, 'sso', 'login',
               '--sso-session', session,
               '--use-device-code',
               '--no-browser',
               '--no-cli-pager']
    log('running: %s' % command)
    # stdin is inherited so C-c reaches aws; stderr is merged so errors are both
    # displayed and parsed off one stream.
    proc = subprocess.Popen(command, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, bufsize=0)
    stdout_fd = proc.stdout.fileno() if proc.stdout else -1

    buffer = ''
    code = url = None
    announced = False
    try:
        while True:
            chunk = os.read(stdout_fd, 4096) if stdout_fd >= 0 else b''
            if not chunk:
                break
            text = chunk.decode('utf-8', 'replace')
            sys.stdout.write(text)
            sys.stdout.flush()
            buffer += text
            if announced:
                continue
            # Parse whole lines only - a read can split a URL mid-token.
            cut = buffer.rfind('\n')
            if cut == -1:
                continue
            code, url = extract(buffer[:cut + 1])
            if code and url:
                announced = True
                announce(tty_path, code, url)
        returncode = proc.wait()
    except KeyboardInterrupt:
        print('\nCancelled.')
        proc.terminate()
        proc.wait()
        # Deliberately 0: a cancel is not a failure, and the popup uses -EE.
        return 0

    if not announced and (code or url):
        announce(tty_path, code, url)

    log('aws exited %d' % returncode)
    if returncode == 0:
        # Also say it out of band, for when the browser has the focus.
        write_tty(tty_path, osc_notify('AWS SSO', 'Logged in to %s' % session))
        if wait:
            # -EE would close the popup the instant aws exits; hold it so the
            # "Successfully logged into..." line is actually readable.
            print('\n  press any key to close')
            sys.stdout.flush()
            wait_key()
    return returncode


def self_test(tty_path):
    print('resolved tty: %s' % tty_path)
    print('TMUX=%s TMUX_PANE=%s stdout tty=%s'
          % (os.environ.get('TMUX'), os.environ.get('TMUX_PANE'), sys.stdout.isatty()))
    print('clients:\n%s' % tmux('list-clients', '-F', '#{client_tty} #{client_session}'))
    sentinel = 'AWS-SSO-SELFTEST-%d' % os.getpid()
    ok = write_tty(tty_path, osc52(sentinel) + osc_notify('AWS SSO', 'self test'))
    print('emitted %s: %s' % (sentinel, 'ok' if ok else 'FAILED'))
    return 0 if ok else 1


def parse_only():
    code, url = extract(sys.stdin.read())
    print('code=%s url=%s' % (code, url))
    return 0 if url else 1


USAGE = """usage: aws-sso.py [--force] [--wait] [--tty PATH] [SESSION]
       aws-sso.py --dispatch [CLIENT_TTY]
       aws-sso.py --notice TEXT
       aws-sso.py --parse-only | --self-test
"""


def main():
    args = sys.argv[1:]
    mode = 'login'
    session = explicit_tty = notice_text = client_tty = None
    force = wait = False

    index = 0
    while index < len(args):
        arg = args[index]
        following = args[index + 1] if index + 1 < len(args) else None
        if arg == '--dispatch':
            mode = 'dispatch'
            if following and not following.startswith('-'):
                client_tty = following
                index += 1
        elif arg == '--notice':
            mode = 'notice'
            notice_text = following
            index += 1
        elif arg == '--login':
            mode = 'login'
        elif arg == '--parse-only':
            mode = 'parse'
        elif arg == '--self-test':
            mode = 'selftest'
        elif arg == '--tty':
            explicit_tty = following
            index += 1
        elif arg == '--force':
            force = True
        elif arg == '--wait':
            wait = True
        elif arg in ('-h', '--help'):
            print(USAGE, end='')
            return 0
        elif arg.startswith('-'):
            print('unknown option: %s\n' % arg, file=sys.stderr)
            print(USAGE, end='', file=sys.stderr)
            return 2
        else:
            session = arg
        index += 1

    log('mode=%s args=%s' % (mode, args))

    if mode == 'parse':
        return parse_only()
    if mode == 'notice':
        return notice(notice_text or '')
    if mode == 'dispatch':
        return dispatch(client_tty)
    if mode == 'selftest':
        return self_test(resolve_tty(explicit_tty))
    return login(resolve_session(session), resolve_tty(explicit_tty), force, wait)


if __name__ == '__main__':
    sys.exit(main())
