# K16 AmneziaWG links

K16_112 ↔ vds1 and K16_112 ↔ vds8 were migrated on 2026-10-11.
The requested transport subnet is **10.255.2.0/24**. The existing VDS-to-VDS
AmneziaWG mesh continues to use 10.250.2.0/24.

| Link | K16 interface/address | Native VDS interface/address | OSPF cost |
| --- | --- | --- | --- |
| K16 ↔ vds1 | wg_vds1, 10.255.2.112/32, peer network 10.255.2.1 | wg3, 10.255.2.1/24 | 1000 |
| K16 ↔ vds8 | wg_vds8, 10.255.2.112/32, peer network 10.255.2.8 | wg3, 10.255.2.8/24 | 30000 |

RouterOS keeps its existing WireGuard interfaces and identities. Their local
peers point to the two ARM64 framing proxies, while the public uplink uses
AmneziaWG to the VDSes' native kernel module. K16's container package and
device-mode permission were already enabled. Both containers start on boot.

- `k16-awg-vds1`: veth 172.31.71.2/30, router gateway 172.31.71.1;
  upstream 45.141.102.72:56708.
- `k16-awg-vds8`: veth 172.31.71.6/30, router gateway 172.31.71.5;
  upstream 194.113.106.136:56708.
- Both proxies listen on UDP 51820 inside their separate containers.
- Image: timbrs/amneziawg-mikrotik-c v1.4.2, `awg-proxy-arm64.tar.gz`.
  SHA-256: `b8345723922f2cfb25f7dfb698eadfa0e4ed77db6a870203971a82d71da65d55`.
- Parameters match the CHR setup: Jc=4, Jmin=40, Jmax=80, S1=65, S2=107,
  H1/H2/H3/H4=1723456781/1723456782/1723456783/1723456784. MTU is 1340.
- OSPF is point-to-point with BFD default timers and 60/240 hello/dead timers.
  SSTP remains cost 60000. Existing mesh, CHR, L2TP and other site links remain
  available, and their costs continue to determine the cheapest total path.

The cutover stops the superseded live Linux peer and resets the RouterOS peer
before checking the new handshake. Otherwise the old public WireGuard path can
reclaim the learned peer endpoint, or an old encryption session can prevent
native initialization. Each link is verified before its old peer is removed
from the persistent Linux configuration. Private original files are preserved
under `/root/before-k16-awg-20261011/` for initial-cutover rollback.

## Configuration and rebuild

`k16-amneziawg.yml` is the serial migration playbook. It has automatic rollback
if native OSPF/BFD verification fails. Run it with vds1/vds8 inventories and a
trusted `router_proxy_command` when router management requires a jump. This is
the cutover workflow; use the recovery playbooks for rebuilding machines.

The desired state is recorded in the VDS/K16 host variables, FRR/firewall
and MikroTik OSPF/BFD templates, the current K16 full-router capture and the
encrypted VDS recovery manifests. Ordinary K16 client playbooks skip these
migrated links and Linux ordinary peer lists exclude K16. Existing service
restore lists enable `awg-quick@wg3`. MikroTik `apply.yml` stages the verified
ARM64 image before restoring K16's containers; environment lists are created
before containers. Follow [the rebuild guide](restore-proxies-ospf.md) for OS,
SSH, device-mode and router bootstrap requirements.

WireGuard peer permissions on each dedicated AWG link allow routed 10/8 and
OSPF multicast; `Table = off` leaves destination choice to OSPF. Site BFD tables
and UDP/3784 rules use the new transport addresses. Loopbacks stay in
10.255.0.0/24 and are advertised passively.

Validation after cutover: both AWG handshakes are established, both native
OSPF adjacencies are Full and both BFD sessions are Up. All 90 directed
loopback checks among the ten OSPF nodes pass. Generated FRR policy matches
the live configuration; migration tests and existing MikroTik tests pass.
