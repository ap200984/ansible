# CHR AmneziaWG migration — 2026-10-05

Historical C-proxy-on-both-ends rollout. Superseded by the completed
[native Linux migration](chr-native-migration-status.md): Linux C proxies are
removed and CHR containers now connect directly to native kernel AWG wg2.
vds1's external connectivity recovered before the native migration.

## Completed preparation

- Pre-change binary backup: CHR `before-awg-chr-20261005.backup`.
- Pre-change non-sensitive export: CHR `before-awg-chr-20261005.rsc`.
- Both copied to `/private/tmp/chr-before-awg.wVVuBt/` on the workstation, permissions 0600. Keep the CHR copies; the workstation temporary directory is not permanent storage.
- Persistent off-router copies are kept in the Git-ignored `.local-backups/chr-20261005/` directory (0700 directory, 0600 files), including the post-migration checkpoint.
- Official RouterOS `container` 7.24.5 installed using the available-package mechanism. Installation reboot completed; SSH returned and installed package version was verified.
- Submitted `/system device-mode update container=yes activation-timeout=1d`. RouterOS explicitly requires power off within 24 hours to activate. Other device-mode settings remain unchanged.
- Post-migration CHR checkpoint: `after-awg-chr-20261005.backup` and `.rsc`.

## Migration completed; external vds1 reachability issue

The operator's cold power-cycle activated `container: yes`. All five VDS
and all four SSTP OSPF neighbors recovered to Full before migration.

The vds1 pilot passed authenticated proxy handshake, direct transport pings in
both directions, OSPF Full and routed Linux-to-CHR loopback pings. Proxy-only
transport enforcement and configuration are persisted for boot, keepalive off.
The remaining vds2/vds5/vds6/vds8 peers were migrated sequentially and each
passed the same validation. All five containers were running, all five VDS
OSPF neighbors Full and all four SSTP neighbors Full immediately after rollout.

The final audit corrected inherited Linux-side keepalive 25 on vds2/vds5/vds6
to zero and persisted only those peer settings. vds1/vds8 already had it off.
Root `chr-amneziawg-keepalive.yml` provides the focused correction; the main
deployment and native WireGuard template also retain keepalive off.

During the final check, vds1 public address 45.141.102.72 became unreachable.
Independent pings from vds2, vds5 and vds8 received TTL-exceeded replies from
upstream 154.54.x.x/130.117.x.x routers, suggesting an external routing loop.
Its loopback became unreachable as well. This prevents a fresh final audit of
vds1; its migration had already passed the pilot before this outage.

OSPF withdrew vds1. vds8 switched its preferred CHR route to vds5, and the
complete final verification passed on vds2/vds5/vds6/vds8: services active and
boot-enabled, authenticated loopback proxy endpoints, no keepalive, no plain
WG fallback, OSPF Full, direct transport pings and routed reachability of CHR,
both K16 gateways and k16_21/3Ekip loopbacks. These checks do not claim the
unavailable vds1 is currently healthy. Re-run `chr-amneziawg-verify.yml` on all
five after its public connectivity recovers.

CHR-to-vds8 was independently verified with 5/5 loopback pings after failover;
CHR FIB uses `10.250.1.5%vds5_interface`. All four remaining VDS and all four
SSTP OSPF neighbors are Full. vds1's neighbor was withdrawn as expected.

## Transport-only implementation

Root `chr-amneziawg.yml` uses checksum-pinned upstream C release v1.4.2.
CHR runs one normal-mode container per migrated peer. Linux runs the same C
binary in server mode as `chr-awg-proxy.service`, wrapping its existing native
`wg0`. Existing keys, inner addresses (10.250.1.N), AllowedIPs, OSPF costs and
neighbors are preserved. The independent kernel AmneziaWG `wg1` mesh
(10.250.2.N) is not altered. No extra Linux tunnel interface is necessary.

Public proxy UDP port: 56707, accepted only from CHR's 62.60.216.73.
Container private /30: 172.31.70.(4*N)/30, router .(4*N+1), container .(4*N+2).
The container changes UDP framing only; native WireGuard retains encryption.
Only the encrypted outer proxy traffic uses existing WAN masquerade. Internal
10/8 traffic is not NATed. Persistent keepalive is zero.

Backends keep private pre-change VPN/FRR/firewall copies under
`/root/before-chr-awg-20261005/`. Plain CHR WireGuard frames are blocked at
cutover so validation cannot silently use the original transport. The C proxy
is enabled on boot, and successful migration removes only that peer's original
public endpoint line from wg0.conf; the native peer learns its authenticated
localhost proxy endpoint. CHR's unicast OSPF traffic initiates the tunnel.

Validation requires an authenticated localhost endpoint, direct transport
pings in both directions, OSPF Full and routed loopback pings before proceeding.
Failures restore the original endpoint/MTU and remove the transport guards.

Public CHR SSH is used through the vds1 jump host so management does not depend
on the very link under test. RouterOS scripts are sent as one scoped line;
7.24 container state is read from JSON `print as-value` boolean flags.

If vds1 is unavailable, use vds2 (SSH 19022) as the jump host instead:
`ssh -p 19022 -i ~/.ssh/priv/ansible -o BatchMode=yes -W %h:%p ansible@38.247.137.237`.
