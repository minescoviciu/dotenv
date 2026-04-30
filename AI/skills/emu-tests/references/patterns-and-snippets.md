# Patterns and Snippets

## Class-Level Interface and DHCP Server

Use class-level objects for frequently reused topology.

```python
GE100 = DC0_DHCP.dnos_itf
GE101 = DC1_NDVRF_DHCP.dnos_itf
GE104 = DC4.dnos_itf

DHCP_SERVER_DC0 = DHCPv6Server(
    netns=DC0_DHCP.dc,
    dhcp_options=DHCPv6ServerOptions(
        subnets=[DC0_DHCP.dtest_itf.ipv6_itf, DC0_123_DHCP.dtest_itf.ipv6_itf],
        interfacesv6=[DC0_DHCP.dtest_itf.name, DC0_123_DHCP.dtest_itf.name],
    ),
    radvd_options=RadvdServerOptions(
        interfaces={
            DC0_DHCP.dtest_itf.name: DC0_DHCP.dtest_itf.ipv6_itf.network,
            DC0_123_DHCP.dtest_itf.name: DC0_123_DHCP.dtest_itf.ipv6_itf.network,
        }
    ),
)
```

## Function Fixture for Specialized DHCP Profile

When only a subset of tests needs a special DHCP profile.

```python
@pytest.fixture(scope="function")
def dhcp_server_dc2(self):
    ge102 = InterfaceData(name=DC2_DHCP.dnos_itf.name, ipv6='dhcp', ndvrf=DC2_DHCP.dnos_itf.ndvrf)
    dhcp_server_dc2_short_lease = DHCPv6Server(
        netns=DC2_DHCP.dc,
        dhcp_options=DHCPv6ServerOptions(
            subnets=[DC2_DHCP.dtest_itf.ipv6_itf],
            lease_time=5,
            max_lease=10,
            interfacesv6=[DC2_DHCP.dtest_itf.name],
        ),
        radvd_options=RadvdServerOptions(
            interfaces={DC2_DHCP.dtest_itf.name: DC2_DHCP.dtest_itf.ipv6_itf.network},
            min_interval=5,
            max_interval=10,
        ),
    )
    with dhcp_server_dc2_short_lease as dhcp_utils, InterfaceContext([ge102], cli=self.cli):
        wait(lambda: self.dhcp.get_show_interfaces_ipv6(ge102) != "", sleep_seconds=2, timeout_seconds=30)
        yield dhcp_utils, ge102
```

## Sniffer (Use tests.utils.sniffer)

Do not use `tests.mw.utils.sniffer` in new/updated tests.

```python
from tests.utils.sniffer import Sniffer

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

## Route Matching with Multiple Default Routes

- If you only need existence for a specific next-hop/source-lladdr, do not require selected-route marker `>`.
- Good pattern: `X.*::/0.*<source_lladdr>`
- Use `X>...` only when route selection is explicitly required.

## Prefer DHCPv6Dnos Checks for CLI Output

Use these helpers before adding custom parsing:

- `check_show_interfaces`
- `check_show_interfaces_interface_name`
- `check_show_interfaces_dhcp`
- `check_show_interfaces_ip`
- `check_show_interfaces_ip_interface_name`
- `get_show_interfaces_ipv6`
