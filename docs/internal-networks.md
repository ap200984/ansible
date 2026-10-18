# Routed internal networks

`internal-networks.yml` fixes transport-address ownership on the existing AWG
mesh, applies the shared internal network policy to Linux and MikroTik, and
advertises existing GRE endpoints. Every infrastructure change uses Ansible.

The common `internal_networks` list covers:

| Purpose | Prefix |
| --- | --- |
| OSPF loopbacks | `10.255.0.0/24` |
| SSTP | `10.250.0.0/24` |
| WireGuard | `10.250.1.0/24` |
| AWG / mesh | `10.250.2.0/24` |
| L2TP | `10.250.3.0/24` |
| GRE | `10.250.4.0/24` |
| K16 main and Kubernetes LANs | `10.9.0.0/23` |
| Ekipazhnyi LAN | `10.10.0.0/24` |
| K16_21 LAN | `10.11.0.0/24` |

The existing `10.250.6.0/24` transport permissions remain
available where already used, but they are not part of the general trusted set.

## Cause and corrections

OSPF had valid routes from VDS2/VDS6 to K16, but the shared AWG peer on VDS1
permitted their loopbacks while omitting their transit `10.250.1.N` and
`10.250.2.N` source addresses. WireGuard validates incoming source addresses
against the peer's AllowedIPs; its destination lookup also needs a peer owner
for leaf hosts hidden by a connected mesh `/24`. The route manager now assigns
explicit transport `/32` aliases to the current owner of each node's advertised
loopback. This preserves direct neighbor and explicit route ownership, and
moves aliases with the loopback's OSPF next hop. The same rule covers router
SSTP, L2TP and GRE endpoint addresses used on asymmetric paths.

On VDS1/VDS8 the connected mesh `/24` always sends leaf mesh addresses
`10.250.2.2` and `10.250.2.6` through `wg1`. Their peer ownership is therefore
fixed to their actual mesh hub VDS5, independently of loopback SPF changes.
This preserves the existing tunnel addressing and OSPF adjacencies. These
connected transport addresses still depend on the VDS5 mesh link; loopback
routes retain their existing OSPF alternate paths.

The remaining shared ordinary `wg0` interfaces on VDS1 and VDS8 also reconcile
AllowedIPs against OSPF. Static per-site ownership previously dropped new GRE
destinations and the L2TP server address when OSPF selected another site as
next hop. Existing site permissions remain a fallback; explicit OSPF routes
take precedence, and direct peer addresses remain fixed.

The Linux firewall's trusted set also omitted the Ekipazhnyi LAN. Captured ICMP
headers showed replies entering VDS1 from the Ekipazhnyi router and being
dropped before forwarding to VDS5. The expanded set permits these replies.
The trusted policy now uses the exact `10.10.0.0/24` and `10.11.0.0/24`
site prefixes. MikroTik receives an explicit internal-prefix list, input/forward permits and
source-NAT exemption before existing rules. Existing single-peer WireGuard
interfaces gain missing internal prefixes additively.

GRE addresses had no OSPF advertisements. Passive point-to-multipoint OSPF
interfaces now advertise each endpoint's own `/32`, with no GRE adjacencies.
Each GRE endpoint retains a direct `/32` route to its opposite peer. This keeps
GRE next-hop resolution and the existing internet egress return path on GRE
when the same endpoint is also learned over the underlay. The GRE startup
configuration persists these direct routes. Existing OSPF costs, established
tunnels, and PPP routes are preserved.

## Apply and verify

Run from the repository root, using the same explicit transport as central
logging when the controller cannot use its normal SSH configuration:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local \
ANSIBLE_REMOTE_TEMP=/tmp/ansible-remote-local \
ANSIBLE_SSH_CONTROL_PATH_DIR=/tmp/ansible-cp \
ansible-playbook -i inventory -i localhost, internal-networks.yml \
  --private-key ~/.ssh/priv/ansible -e @vars/logging-transport.example.yml
```

The tags `internal_awg`, `internal_wireguard`, `internal_firewall`, `internal_gre`, and
`internal_mikrotik` select stages. The focused playbook reloads the AWG permission
manager and applies FRR commands without restarting OSPF or established tunnels.

Run the read-only endpoint matrix with the same connection arguments:

```sh
ansible-playbook -i inventory internal-networks-verify.yml \
  --private-key ~/.ssh/priv/ansible -e @vars/logging-transport.example.yml
```

It probes nineteen assigned endpoints from VDS2 and VDS6 using automatic source
selection, the loopback address, and each WG/mesh transport address. It also
checks TCP port 10514 on ELK with every source. Each ICMP case sends three
packets and records packet counts and partial loss as well as reachability.
Detailed bounded JSON results
are saved under `/tmp/internal-network-verify/` on the controller. Unassigned
addresses, such as the retired K16 `10.250.1.112`, are excluded.

The reverse matrix verifies LAN, loopback, SSTP and GRE sources on the four
routed site routers against all six VDS2/VDS6 loopback and transport addresses:

```sh
ansible-playbook -i inventory -i localhost, mikrotik/internal-networks-verify.yml \
  -e @vars/logging-transport.example.yml
```

RouterOS probes use a one-second interval, which also controls the reply
deadline. A shorter interval than the actual WAN RTT produces false failures.
The verifier also checks direct GRE peer routes, the existing Google GRE
default routes, peer responses, and absence of GRE OSPF adjacencies.

After transport recovery, `logging-verify.yml` tests actual syslog/auth file
shipping and RouterOS warning/debug delivery into Elasticsearch.
