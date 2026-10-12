# Loopback reachability and local source selection

The ten routed loopbacks are 10.255.0.{1,2,5,6,7,8,21,24,64,112}/32.
Linux VDSes and MikroTik routing nodes use dynamically learned OSPF routes.

Before the 2026-10-12 fix, VDS6's ordinary ping to 10.255.0.112 selected
10.250.2.6 as its source. The packet passed VDS5 but VDS1's shared AmneziaWG
interface did not assign that transport source to its VDS5 peer. Binding the
ping to VDS6's loopback worked, because that loopback prefix was assigned to
the correct peer by the dynamic route reconciler. Similar default-source
failures occurred on VDS2 and MikroTiks reaching VDS8/CHR through other nodes.

## Persistent policy

Linux FRR's `LOOPBACK-SOURCE` route-map matches OSPF destinations within
10.255.0.0/24 and sets the preferred source to the host's existing
`ospf_router_id`. Its second permit clause leaves other OSPF destinations
accepted and unchanged. The source policy is included in the shared FRR
configuration template used by normal deployment and machine restoration.

FRR does not immediately update this attribute on every pre-existing kernel
route. The focused deployment helper seeds the preferred source on existing
OSPF /32 loopback routes, retaining their OSPF protocol, kernel nexthop group
(or gateway/interface) and metric. It does not create static forwarding paths.
It refuses to replace routes whose forwarding information cannot be preserved.

Each MikroTik uses import chain `tunnel-ospf-source`. For loopback /32
routes it sets `pref-src` to that router's loopback before accepting the route;
other imported routes are accepted as before. The normal MikroTik OSPF play
includes this policy, and full router captures retain it.

No internal source-NAT exemption, peer permission, OSPF cost or BFD timer is
changed by this policy. GRE and Internet service routing retain their existing
routing tables and egress.

## Apply to existing nodes

Run root `loopback-reachability.yml` with the VDS inventory and localhost,
your private SSH key, pinned host keys and the trusted router jump connection.
For example, from the repository root:

```sh
ANSIBLE_LIBRARY="$PWD/mikrotik/library" \
ANSIBLE_MODULE_UTILS="$PWD/mikrotik/module_utils" \
ansible-playbook -i inventory loopback-reachability.yml \
  --private-key /home/user/.ssh/priv/ansible \
  -e @/path/to/router-connection.yml
```

The connection file defines `router_proxy_command` and
`ansible_ssh_common_args` with strict host checking. Costs and next hops remain
under OSPF control; the play does not restart FRR or tunnel interfaces.

On VDS6, plain commands now choose source 10.255.0.6:

```sh
ip route get 10.255.0.112
ping -c 3 10.255.0.112
traceroute -n 10.255.0.112
```

## Verification on 2026-10-12

All 180 directed checks passed: from each of ten routing nodes to the other
nine loopbacks, once with the default source and once explicitly bound to its
loopback. After OSPF import-filter reconvergence, all 50 BFD endpoints were Up.
VDS2 was reachable again during this run and passed all 18 checks.

Changing the MikroTik OSPF import filter can briefly reconverge adjacencies;
wait for neighbors/BFD to return before assessing the primary paths. The
source helper's four tests verify preservation of nexthops/protocol/metrics,
exclusion of unrelated destinations and refusal to lose route information.
