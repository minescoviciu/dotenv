# CI Jira Bug Search Reference

Use this reference when the user asks for CI bugs or asks for CI similarity analysis.

## CI Scope

- Base filter: https://drivenets.atlassian.net/issues/?filter=34158
- Keep component-aware filtering when the user provides a component.
- If searching vulnerability/CWE/polaris topics inside CI bugs, prefer component `Vulnerability`.

## Env Failure Pattern

- For env CI failures, prioritize issues whose summary starts with `Test EnvFailure_`.
- Do not depend on JQL-only matching for this prefix if it is unreliable.
- Fetch candidates from the CI filter and perform client-side prefix filtering.

## Similarity Heuristics

When asked for similar CI bugs, compare these signals in order:

1. Summary pattern and failing test name
2. Description overlap (error signature, topology, setup)
3. Newest comments first (stack traces, repeated logs, reproducer details)

Rank higher when multiple signals align.

## Suggested Component List

If component is requested but missing, propose:

`AAA`, `Certificates`, `DHCP_IB`, `DNS`, `NTP`, `IPTABLES`, `SCP`, `SSH`, `SNMP_TRAPS`, `CLI`, `Management`, `SZTP`, `TCP_RATE_LIMITER`, `TELNET`, `TALLY`
