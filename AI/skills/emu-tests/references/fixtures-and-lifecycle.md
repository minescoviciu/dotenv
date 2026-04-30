# Fixtures and Lifecycle

## class_env

- `class_env` discovers class attributes by type and wires them automatically.
- It configures class-level `InterfaceData` through `InterfaceContext`.
- It enters class-level service contexts (for example `DHCPv6Server`).
- It injects `self.cli` (and `self.db`) on the test class.

## restore_class_dnos_config

- Use when test methods mutate configuration and need per-test rollback.
- Saves class config before test and restores after test.
- After restore, waits for DHCPv6 IP reacquisition using `InterfaceContext.wait_for_dhcpv6_ips()`.

## Important Interaction

- Tests can pass but teardown can fail if shared class-level DHCP services were terminated during test and not restarted.
- Typical failure pattern:
  - Test calls `terminate_radvd()` / `terminate_dhcpd()` on class-level server.
  - Teardown restore waits for DHCPv6 IPs.
  - DHCP service is down, so IP wait times out.

## Safe Patterns

- If using shared class-level `DHCPv6Server`, always restart services in `finally` if terminated.
- Prefer function-level fixture/local server for special behavior (short leases, flood RA, targeted failure tests).
- Keep interface state reads non-mutating where possible (`DHCPv6Dnos.get_show_interfaces_ipv6`) instead of mutating interface objects.

## self.cli Rule

- In classes using `class_env`, use `self.cli`.
- Avoid test method signatures like `def test_x(self, cli)` unless there is a specific reason outside class-level fixture flow.
