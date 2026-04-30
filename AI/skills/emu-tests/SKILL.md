---
name: emu-tests
description: Maintain and extend EMU SA inband tests with the project’s fixture model (`class_env`, `restore_class_dnos_config`), class-level test objects, DHCPv6 helpers (`DHCPv6Dnos`, `DHCPv6Server`), and canonical utilities (connections, InterfaceContext, and tests/utils/sniffer). Use when refactoring or adding tests under tests/suites/emu_sa_inband/tests, especially DHCP/inband workflows.
---

# EMU Tests

Use this skill to keep EMU SA inband tests consistent with the existing fixture and helper model.

## Reference Files

- For fixture lifecycle and teardown interactions, read `references/fixtures-and-lifecycle.md`.
- For ready-to-use test patterns and snippets, read `references/patterns-and-snippets.md`.

## Core Rules

- Use `self.cli` in test methods; do not pass `cli` fixture args in test signatures when `class_env` is used.
- Keep class-level setup minimal but explicit: define interfaces/servers that are reused by many tests.
- Prefer existing helpers over duplicating parsing/check logic.
- Keep teardown-safe behavior: if a test terminates shared class-level services, restart them before exit.

## Fixture Model

- Use `@pytest.mark.usefixtures("class_env")` for classes that rely on class-level `InterfaceData`, `DHCPv6Server`, or `BaseDnosApi` objects.
- Use `@pytest.mark.usefixtures("restore_class_dnos_config")` when tests mutate DNOS config and require per-test rollback.
- Understand `class_env` behavior:
  - Discovers class attributes by type.
  - Configures interfaces via `InterfaceContext`.
  - Enters class-level service contexts (including `DHCPv6Server`).
  - Injects `self.cli` and `self.db`.
- Understand `restore_class_dnos_config` behavior:
  - Saves config before test.
  - Restores config after test.
  - Waits for DHCPv6 IP reacquisition using `InterfaceContext.wait_for_dhcpv6_ips()`.

## Preferred Utilities

- Use connections from `tests/suites/emu_sa_inband/tests/utils/connections.py`.
  - Typical constants: `DC0_DHCP`, `DC0_123_DHCP`, `DC1_NDVRF_DHCP`, `DC2_DHCP`, `DC4`.
- Use `DHCPv6Dnos` methods for show checks instead of inline parsing.
  - `check_show_interfaces`
  - `check_show_interfaces_interface_name`
  - `check_show_interfaces_dhcp`
  - `check_show_interfaces_ip`
  - `check_show_interfaces_ip_interface_name`
  - `get_show_interfaces_ipv6`
- Use `tests.utils.sniffer.Sniffer` (new implementation), not `tests.mw.utils.sniffer.Sniffer`.

## Sniffer Pattern (Canonical)

- Construct with callback-based API:
  - `Sniffer(filter=..., namespace=..., callback=...)`
- Start with `start()`.
- Finalize with `check()`.
- Capture packets by appending in callback.

Example:

```python
packets = []
capture = Sniffer(
    filter="port 547",
    namespace=DEFAULT_IN_BAND_NAMESPACE,
    callback=packets.append,
)
capture.start()
# run traffic
capture.check()
```

## Class-Level Setup Pattern

- Define frequently used interfaces at class level from connection objects.
- Name interfaces by DNOS port convention used in tests (`GE100`, `GE101`, `GE104`, etc.).
- Keep static interfaces that are already provisioned by `class_env` as class attributes; do not re-wrap them with redundant `InterfaceContext` unless test-specific reconfiguration is needed.

## DHCPv6 Server Lifecycle Guidance

- Use class-level `DHCPv6Server` for shared baseline topology.
- Use function-level fixture or local server object for special test behavior (short lease, alternate namespace/profile).
- If a test calls `terminate_radvd()` or `terminate_dhcpd()` on a shared server, restart in `finally`:
  - `start_radvd()`
  - `start_dhcpv6()`
- Avoid leaving shared services down, otherwise teardown (`restore_class_dnos_config`) can fail while waiting for DHCPv6 addresses.

## Route Regex Guidance

- When multiple default routes exist, do not require selected-route marker (`>`).
- For existence checks of a specific default route, prefer:
  - `X.*::/0.*<link-local>`
- Use `X>...` only when selection is a strict requirement.

## Editing Checklist

- Keep large historical comments that explain tricky edge cases.
- Keep test changes minimal and scoped.
- Reuse existing fixture/helper patterns before introducing new ones.
- Ensure no stale references to obsolete sniffer utility remain.
- For any service lifecycle change in a test, verify teardown stability.
