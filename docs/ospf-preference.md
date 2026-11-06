# Preferred site uplink

VDS8 is the preferred hub for the physical MikroTiks and VDS7 CHR.
The shared `ospf_wireguard_costs` policy sets VDS8 links to 1000 and VDS1
links to 30000 on both ends. VDS1 remains the backup; SSTP remains 60000.
The VDS-to-VDS mesh stays at 200 and the CHR–VDS5 link stays at 1001 to
avoid an equal-cost fallback through the shared mesh.

The physical sites reach VDS5 through VDS8's mesh link, and VDS7 through
VDS8's CHR link. VDS2 and VDS4 remain reachable through VDS5. A site whose
direct hub tunnel is unavailable can use its L2TP link to K16 and K16's
preferred VDS8 uplink.

Apply only OSPF costs, without restarting tunnels or rewriting firewall rules:

```sh
ansible-playbook -i inventory/vds8 -i inventory/vds1 -i inventory/vds5 \
  ospf-costs.yml
```

The playbook first lowers VDS8's Linux interface costs, then updates the
existing hub templates on CHR and the four physical site routers, and finally
raises VDS1's Linux costs and verifies VDS5's tie breaker. RouterOS management
uses the existing `router_proxy_command` override when direct access is unavailable.

Both the canonical topology and the full-router restore records contain this
policy. Full OSPF/recovery runs therefore preserve the preference.

## Live verification on 2026-11-06

| Physical router | Active exit toward VDS2/VDS4/VDS5/VDS7 |
| --- | --- |
| K16_112 | `wg_vds8`, next hop `10.250.6.8` |
| Misha | `wg_vds8`, next hop `10.250.6.8` |
| 3Ekipazhnyi64 | `wg_vds8`, next hop `10.250.1.8` |
| k16_21 | `wg_vds8`, next hop `10.250.1.8` |

All four sites reached VDS5, VDS7 and VDS4 with 3/3 ping replies.
Initial concurrent VDS2 probes lost packets; subsequent sequential probes
received 5/5 replies from every site. VDS5, VDS1 and VDS8 also reached all
four physical loopbacks in return-path tests. VDS5's site routes changed
from mesh next hop `10.250.2.1` to `10.250.2.8`.

Full OSPF neighbor counts remained unchanged during the cost swap: CHR 9,
K16_112 6, Misha 4, 3Ekipazhnyi64 2 and k16_21 2. The latter two initially
used K16_112 because VDS8's host firewall dropped their WireGuard handshakes.
Restoring UDP 56699 access brought both direct VDS8
adjacencies to Full, replacing the indirect routes with direct next hops.
The VDS1 fallback was checked in the topology cost calculation; no live
tunnels were disabled to test failover.

Both VDS1 and VDS8 set `iptables_input_wireguard_sources` to `0.0.0.0/0`
because physical sites use changing public IP addresses.
The firewall helper installs UDP-only exceptions for the configured WireGuard
listener (VDS1 56685, VDS8 56699) and retains them during boot-time normalization.
VDS1's direct links also form Full adjacencies while its cost remains 30000.
Both sites received 3/3 replies when pinging VDS1's transport address through
`wg_vds1`; their routes to the other VDSes still select VDS8.
The UDP listeners accept any IPv4 source; WireGuard authenticates configured
peer keys. Firewall normalization removes the superseded per-address rules.
