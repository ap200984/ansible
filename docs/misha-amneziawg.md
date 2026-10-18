# Misha AmneziaWG links

Misha ↔ vds1 and Misha ↔ vds8 use container-backed AmneziaWG, with transport
10.250.6.0/24. Loopbacks remain 10.255.0.N/32 and the existing inter-VDS mesh
remains 10.250.2.0/24.

| Link | Router interface/address | Native VDS interface/address | OSPF cost |
| --- | --- | --- | --- |
| Misha ↔ vds1 | wg_vds1, 10.250.6.24/32, peer network 10.250.6.1 | wg4, 10.250.6.1/24 | 1000 |
| Misha ↔ vds8 | wg_vds8, 10.250.6.24/32, peer network 10.250.6.8 | wg4, 10.250.6.8/24 | 30000 |

Misha is a hAP ac² with 32-bit ARM, RouterOS 7.24.5 and the container package
and device-mode permission enabled. Its USB disk `usb1` holds the image and
both container root directories; ensure this disk is mounted before deployment
or restoration. Internal flash has insufficient space for container storage.
Both containers start on boot. No disk formatting is performed by deployment.

- `misha-awg-vds1`: veth 172.31.72.2/30, gateway 172.31.72.1,
  upstream 45.141.102.72:56709.
- `misha-awg-vds8`: veth 172.31.72.6/30, gateway 172.31.72.5,
  upstream 194.113.106.136:56709.
- Both proxies listen on UDP 51820 inside their separate containers.
- Official image: [amneziawg-mikrotik-c v1.4.2](https://github.com/timbrs/amneziawg-mikrotik-c/releases/tag/v1.4.2),
  `awg-proxy-arm.tar.gz`, checksum
  `acd0338297dc445b56a32a9b8be4a91632015d7adee08059a286e4b2fa63acf6`.
- Parameters match K16/CHR: Jc=4, Jmin=40, Jmax=80, S1=65, S2=107,
  H1/H2/H3/H4=1723456781/1723456782/1723456783/1723456784; MTU 1340.
- OSPF is point-to-point with default BFD parameters, hello/dead 60/240.
  SSTP cost 60000 and L2TP cost 100 are retained.

Misha preserves its original key and RouterOS interface names. Native Linux
`wg4` is separate from K16's `wg3`; explicit peer /32 routes and interface-bound
OSPF separate their shared server addresses. AllowedIPs cover routed 10/8 and
OSPF multicast 224.0.0.5/32; `Table = off` leaves routing to OSPF.
Misha uses CGNAT and may change public addresses, so dedicated VDS UDP port
56709 accepts roaming endpoints; only its configured cryptographic peer can
authenticate. Container source NAT applies only to that public uplink.

## Deployment and recovery

`misha-amneziawg.yml` deploys vds1 then vds8. It prepares native interfaces and
USB containers, switches one router link, resets its old session, then requires
Full OSPF, Up BFD and loopback pings before removing the old persistent peer.
On failed verification it restores ordinary WireGuard and FRR. Original files
are saved in `/root/before-misha-awg-20261011/` during each run.

Run with the vds1/vds8 inventories, pinned SSH host keys and the management
`router_proxy_command` documented in [the MikroTik guide](../mikrotik/README.md).
For new machines use [the recovery guide](restore-proxies-ospf.md). Host variables,
shared OSPF/BFD policy, full Misha capture and encrypted VDS manifests preserve
the desired state. Linux recovery starts `awg-quick@wg4`; MikroTik `apply.yml`
stages the verified ARM image on `usb1` before restoring containers. Ordinary
WireGuard client playbooks skip the migrated Misha links.

Validation on 2026-10-11: both native handshakes established, both OSPF
adjacencies Full, both BFD sessions Up. All 90 directed loopback checks among
ten routing nodes passed after the final cutover. Both proxy containers are
running at approximately 1 MB each. The first vds8 verification attempt rolled
back; a subsequent retry established bidirectional data traffic and passed the
same checks. The playbook allows longer convergence time before rollback.
Generated FRR configurations pass native validation on all five Linux VDSes.

During cutover, RouterOS temporarily uses a 5-second persistent keepalive to
keep the local proxy and NAT path active while OSPF converges. Once BFD is Up,
keepalive returns to zero; BFD traffic keeps the active path warm. Misha has a
short UDP conntrack timeout, so this also avoids waiting for a 60-second OSPF
hello to initiate the new handshake.

Six pre-existing orphaned bridge/interface/table records are omitted from the
desired YAML because their deleted object IDs cannot be restored on a new
router. The public raw export and encrypted sensitive export retain them.

Misha's `192.168.0.190/32` now has a source-only internet policy through the
VDS8 link, overriding service address-list routing. See
[host VDS8 egress](misha-vds8-host.md) for deployment, restoration and validation.
