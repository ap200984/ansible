# Restore HTTPS proxies and OSPF

The desired configuration was reconciled with the live devices on 2026-10-11.
HTTPS proxies run on vds1, vds2, vds3, vds5, vds6 and vds8. OSPF/BFD runs on
vds1, vds2, vds5, vds6, vds8 and the five main MikroTiks.

## Configuration sources

- `host_vars/vds*.yml`: proxy selection, port, credentials referenced from
  Vault, certificate path, DNS overrides, VDS3 forwarding, BFD enablement,
  loopback and ordered routing services.
- `certificates/`: public CA/server certificates valid until 2036-10-11.
  `group_vars/all/https_proxy_tls.yml`: encrypted existing private keys.
- `vars/ospf-restore/vds*.vault.yml`: encrypted active tunnel configurations,
  including keys, peer permissions, bootstrap routes and required firewall/
  routing helpers. These avoid the old migration playbooks' dependencies on
  previously installed files. Update these manifests when tunnel identities,
  endpoints or persistent firewall helpers change.
- `roles/ospf/templates/frr.conf.j2`: current OSPF policy. Recovery generates
  FRR from host/shared vars rather than overwriting policy with captured FRR.
- `mikrotik/host_vars/`: management access and BFD/SSTP policy.
  `mikrotik/routers/<identity>/`: current declarative full-router records,
  redacted export and encrypted credentials/sensitive export.
- `mikrotik/vars/ospf-topology.yml` and `mikrotik/ospf*.yml`: reapply OSPF, passive loopbacks, BFD defaults and site
  interface-specific BFD routing. SSTP cost is 60000; WireGuard costs remain
  1000/1001/30000, mesh links 200, L2TP 100.

Every active OSPF interface uses BFD without a custom timer profile. The site
BFD routing rules affect only UDP/3784, preventing packets from leaving through
the wrong WireGuard interface when both interfaces share a local IP. CHR uses
peer-specific `/32` interface networks. Loopback destinations use OSPF routes.
GRE remains disabled and is not part of the routing rebuild.

## Bootstrap requirements

Provide a supported Debian/Ubuntu x86_64 OS, reachable management SSH,
`ansible` credentials/key and sudo access; update inventory public IPs after
recreating machines. Update tunnel endpoint manifests and certificate SANs if
public addresses change. The checked-in proxy certificate covers the existing
six public endpoints. VDS3 also requires its LAN and the K16 public uplink.
Vault password and SSH private keys remain outside Git.

On a replacement MikroTik, install a compatible RouterOS version and packages,
provide an SSH management address and the authorized `ansible` key. CHR also
needs the container package, container device-mode permission and sufficient
storage. RouterOS device-mode activation can require console/physical access.
The capture does not include OS images, private SSH keys or uploaded files.
The apply playbook stages the pinned CHR image or verified K16 ARM64 AWG image before container creation;
environment lists are reconciled before containers. RouterOS `start-on-boot`
starts the restored containers at boot; reboot the rebuilt CHR after applying.

Run commands from this repository root. `mikrotik/known_hosts` contains the
recorded device host keys. Verify and update the relevant key after replacing a
router. Provide a trusted SSH jump with `router_proxy_command` when needed;
that jump must also verify its host key.

## Restore routers

For each rebuilt router, reconcile its captured config using its bootstrap
management address (the saved loopback cannot work until routing exists):

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, \
  mikrotik/apply.yml -e router_identity=K16_112 \
  -e router_host=BOOTSTRAP_IP -e router_port=22
```

Repeat for `vds7_CHR`, `3Ekipazhnyi64`, `k16_21` and `Misha` with their bootstrap
addresses/ports. Optional `-e @connection.yml` can supply a trusted SSH jump.
This applies the full router configuration, including SSTP/L2TP/WireGuard,
loopbacks, BFD, firewall and VDS3's HTTPS proxy forwarding. It does not remove
unrelated existing records; use it on a clean, bootstrapped replacement.

## Restore VDS routing and proxies

Once the routers have their base configuration and management access:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook \
  -i inventory/vds1 -i inventory/vds2 -i inventory/vds3 \
  -i inventory/vds5 -i inventory/vds6 -i inventory/vds8 -i localhost, \
  restore-proxies-ospf.yml --private-key ~/.ssh/priv/ansible \
  --ssh-common-args="-F /dev/null"
```

This installs native AWG where required, restores ordinary/native tunnel
identities and required services, generates FRR/BFD, reconciles MikroTik OSPF,
and deploys only the HTTPS proxy container service through the existing Docker
role. It preserves default BFD timers. Use `restore-vds-routing.yml` for the
Linux routing part alone, or the existing `02_deploy_services.yaml --tags
https_proxy` command for a proxy-only rollout.

Recovery starts restored interfaces but does not restart already running
interfaces merely because their files changed. Use the focused tunnel rollout
playbooks when intentionally changing live tunnel identities or endpoints.
This rebuild workflow has been syntax checked and its generated routing policy
compared with live configuration; no machine was destroyed/recreated to test it.

## Verification

After both ends have been restored, use `vtysh -c 'show ip ospf neighbor'` and
`vtysh -c 'show bfd peers'` on the VDSes. On RouterOS use
`/routing ospf neighbor print detail` and `/routing bfd session print detail`.
Expect Full OSPF neighbors and Up BFD sessions, then ping every loopback from
another loopback. Linux loopbacks are .1/.2/.5/.6/.8 and router loopbacks are
.7/.21/.24/.64/.112 under `10.255.0.0/24`.

Verify proxies with the renewed CA and your Vault-backed credentials. Import
`certificates/vds-proxy-ca.crt` into browsers' trusted CA store. The server
certificate is deployed to the proxy, not to browser client-certificate stores.

Validation completed on 2026-10-11: all five generated FRR configurations pass
`vtysh -C` on the live VDSes and match the captured OSPF policy. Read-only
MikroTik checks match OSPF, BFD and routing-table records on all five main
routers (zero changes). The 11 existing MikroTik regression tests pass, as do
both recovery playbooks' syntax checks and certificate-chain verification.

The K16 ↔ vds1/vds8 links were subsequently migrated to AmneziaWG on
`10.250.6.0/24`. Their current encrypted identities and `awg-quick@wg3` units
are included in recovery. See [the K16 migration](k16-amneziawg.md).

Misha also uses two USB-backed ARM proxy containers to vds1/vds8 native `wg4`.
Restore its mounted `usb1` storage before router configuration. See
[Misha AWG deployment and recovery](misha-amneziawg.md).

Google IPv4 egress through VDS6 uses four persistent GRE services over OSPF
loopbacks, plus forwarding/NAT. The VDS6 restore manifest and MikroTik captures
include these settings. See [Google GRE deployment](google-gre.md).

OSPF loopback routes now prefer each node's own loopback as the source for
locally generated traffic. The shared FRR template and MikroTik OSPF play
restore this policy. See [loopback reachability](loopback-reachability.md) for
the focused existing-node rollout and verification.
