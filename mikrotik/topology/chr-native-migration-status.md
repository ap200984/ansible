# Native Linux CHR migration — completed 2026-10-05

## Completed deployment

vds2 pilot completed at 19:10 local time; serial vds5/vds6/vds8/vds1 rollout
completed at 19:19. Final independent verification passed on all five hosts:
native AWG active and boot-enabled, authenticated CHR transport, keepalive 0,
CHR OSPF Full on wg2, all original wg1 mesh and wg0 site adjacencies Full,
routed CHR/K16 main/K16 Kubernetes/k16_21/3Ekip loopbacks reachable, internal
10/8 no-SNAT guard present, and no Linux proxy unit, executable or process.
CHR independently showed five VDS and four SSTP neighbors Full and all five
C containers running with start-on-boot enabled. vds1 recovered from its
earlier external outage and was included in the successful rollout.

Linux now uses official kernel AmneziaWG directly:

`CHR native WG → CHR C container → Internet AWG → Linux native AWG wg2`

No Linux Docker container or C proxy remains. Existing native wg1 mesh is
unchanged. Ordinary site peers remain on wg0; the CHR peer was removed only
from wg0 and moved to wg2. Its original private identity stays on its own
Linux host and is preserved in the 0600 native configuration. Public UDP
56707 is accepted only from CHR. Native AWG uses MTU 1340, numbered
10.250.1.N/24, Table=off, no static routed destinations except the transport
neighbor /32, and keepalive disabled. CHR and wg2 use point-to-point OSPF
with matching 60/240 timers and original costs (1000, vds5 1001, vds8 30000).
OSPF multicast 224.0.0.5/32 is allowed only on the dedicated peer. CHR return
transport /32s are pinned to their respective VDS interfaces. The preserved
Linux source address also exists on wg0; OSPF is explicitly interface-bound.

Official installed packages identify module build `202609061402+4569c4c`
and tools build `202608130144+ee0f0a9` (Ubuntu suffix varies by OS). No kernel
upgrade, machine reboot or RouterOS container replacement was required.
Superseded C service/binary/helper/marker and proxy-only firewall rules were
removed only after each successful native routing check.
Two superseded automation-owned transport pins (old vds1/vds8 interface-only
routes) were removed after confirming their validated native replacements;
the five native /32 pins are active without duplicate ECMP entries.

## Backups and automation

- Linux private originals: `/root/before-chr-native-awg-20261005/` on every
  migrated VDS, including original WG/FRR/firewall and C service/binary/helper.
- CHR checkpoints: `before-native-awg-20261005.backup/.rsc` and
  `after-native-awg-20261005.backup/.rsc`, also retained off-router under
  Git-ignored `.local-backups/chr-20261005/`, directory 0700 and files 0600.
- Root deployment: `chr-amneziawg-native.yml`; verification:
  `chr-amneziawg-native-verify.yml` (also invoked by generic CHR verification).
- `chr_native_awg_hosts` includes all five VDSes. Ordinary WG templates,
  FRR templates, tunnel permissions and MikroTik OSPF reapplication preserve
  native peer ownership and multicast permissions. Legacy renumbering and
  C-proxy deployment are guarded against undoing the migration.
- Local checks: 10 CHR/native tests, 4 ordinary WG tests, 8 mesh route-owner
  tests; Ansible syntax validation and SVG XML validation.

## Initial interrupted pilot (historical)

User requested replacing Linux C proxy services with the official AmneziaWG
kernel package while keeping RouterOS C containers. User subsequently asked
to continue later; no deployment process remains running.

Only vds2 was attempted. Native wg2 reused the original wg0 private identity,
UDP 56707 and transport address 10.250.1.2/32. CHR's existing container required
no key or obfuscation changes. Authenticated native handshake and direct pings
passed before OSPF convergence. Point-to-point OSPF reached Full on both ends,
but transport/loopback pings failed after convergence. Do not roll out further
hosts until return-path behavior is understood. Linux/CHR source-address and
connected-prefix ownership need examination. FRR treats wg2 /32 as unnumbered.

The pilot playbook stopped on a privilege-escalation timeout classified as
UNREACHABLE, so Ansible did not execute its rescue block. Manual rollback
completed: wg2 and native-firewall startup disabled, original wg0 and FRR
configuration restored, live wg0 peer restored with syncconf, CHR host route
restored to wg0, firewall restored, FRR restarted, Linux C proxy enabled and
started. CHR vds2 peer permissions restored exactly and OSPF type restored to
ptmp. No proxy files were removed. Newly installed native migration helper,
wg2 configuration and disabled firewall unit remain for later investigation.
The CHR vds2 peer was toggled off/on to clear its stale native AWG session;
CHR-to-vds2 direct transport pings then passed 3/3 through the restored proxy.

Private vds2 backups: `/root/before-chr-native-awg-20261005/`.
Additional CHR checkpoint: `before-native-awg-20261005.backup` and `.rsc`.
Other VDSes and all RouterOS containers were not migrated. vds1 remained
unreachable via public SSH; no changes were attempted there.

On resumption, MTU mismatch on the restored ordinary vds2 link and CHR's
alternate return route through vds5 were confirmed. The corrected native
configuration uses /24 (not unnumbered /32) plus an explicit CHR transport
return route. Verification now uses independent public SSH commands so
verification connection failures trigger the rescue block instead of being
classified as unreachable Ansible hosts. A subsequent verification-only bug
expected `off` rather than native AWG's numeric `0` for keepalive; the safe
automatic rollback worked, and accepting both formats resolved that check.
The corrected pilot and full rollout then completed successfully.
# Superseded in part: selective ordinary WireGuard rollback

On 2026-10-05 CHR links to vds2/vds5/vds6 and mesh vds5↔vds2/vds6
were converted back to ordinary WireGuard. AWG packages were removed from
vds2/vds6 and those three CHR containers were deleted. Requested local
VPN/routing backup configurations on vds2/vds5/vds6 and CHR were deleted.
Workstation copies remain. See [current topology](current-tunnels.md).
The earlier migration report above is historical.
