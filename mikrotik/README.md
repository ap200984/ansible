# MikroTik configuration

## OSPF on existing tunnels

`ospf.yml` configures OSPFv2 area `0.0.0.0` on the existing SSTP and L2TP
links and hub-bound WireGuard links of the five main MikroTiks. It does not create tunnel interfaces.
SSTP costs 10 and L2TP costs 100. Active links use 60-second Hellos and a
240-second dead interval, with BFD disabled. Loopbacks and other existing WireGuard interface addresses are advertised
passively; links to vds1/vds8 run active OSPF. Public uplinks and unrelated
LANs are excluded. Only K16_112 originates `10.9.0.0/16`, and only
3Ekipazhnyi64 originates `10.10.0.0/16`, through explicit discard summaries
and exact external export filters. More-specific local LAN routes take
precedence over the discard routes.

Both `10.250.0.0/16` and `10.255.0.0/16` are trusted in existing MikroTik
lists and allowed in input/forward chains. NAT exceptions preserve addresses
between the configured tunnel, loopback and LAN networks. The old LAN static
routes become distance-250 fallbacks only after OSPF advertisements exist.

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/ospf.yml
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/wireguard-trust.yml
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i inventory/vds1 -i inventory/vds8 ospf.yml
```

The WireGuard trust playbook updates only existing single-peer MikroTik
interfaces to `allowed-address=10.250.0.0/16,10.255.0.0/16`. It never creates
interfaces or peers. Direct WireGuard OSPF is enabled with unicast neighbors on existing
interfaces: vds1 costs 1,000 and vds8 costs 30,000. Linux hub peer permissions
are preserved by default (`ospf_wireguard_manage_peers: false`). Shared Linux
`wg0` interfaces require distinct destination ownership, so both `/16`
prefixes must not be assigned to every hub peer. The MikroTik single-peer
interfaces retain exactly the two broad prefixes above. These prefixes do
not include the `10.9.0.0/16` and `10.10.0.0/16` LANs: their advertisements
can cross WireGuard OSPF, but their data traffic is permitted only on PPP
unless WireGuard permissions are expanded explicitly.

Direct WireGuard OSPF uses unicast point-to-multipoint neighbors. The existing hub-bound addresses use `/24` prefixes (`10.250.1.0/24`) so FRR and RouterOS can bind those neighbors. No new addresses or tunnels are created. Linux keeps explicit peer transport `/32` routes alongside the connected prefix; OSPF advertises point-to-multipoint addresses as host routes. Peer AllowedIPs are preserved by default.


Management targets in `mikrotik/host_vars` use these loopbacks for the five main routers. The two Logia routers retain their LAN management addresses because they have no configured loopbacks.

The five main routers use a dedicated `loopback` bridge with stable `/32`
addresses: `10.255.0.7` (vds7_CHR), `10.255.0.112` (K16_112),
`10.255.0.64` (3Ekipazhnyi64), `10.255.0.21` (k16_21), and `10.255.0.24`
(Misha). Apply them with:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/loopback.yml
```

vds1's `wg0` listens on UDP `56685` and uses `10.250.1.1/32` for the four
main routers. Each router uses `wg_vds1` with its own `/32`: `10.250.1.112`
(K16_112), `10.250.1.64` (3Ekipazhnyi64), `10.250.1.21` (k16_21), and
`10.250.1.24` (Misha). Apply the server first and then the clients:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i inventory/vds1 wireguard-vds1.yml
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/wireguard-vds1.yml
```

vds8's existing `wg0` listens on UDP `56699` and uses `10.250.1.8/32`
for the four main routers. Each router uses `wg_vds8` with its own `/32`:
`10.250.1.112` (K16_112), `10.250.1.64` (3Ekipazhnyi64),
`10.250.1.21` (k16_21), and `10.250.1.24` (Misha).
K16_112 uses public endpoint `86.110.170.70:37973` and has no persistent
keepalive on either end. The other router peers send keepalives every 25 seconds.
The additional vds8 addresses for existing peers are preserved.
New router private keys are encrypted in `vault/common.yml`; 3Ekipazhnyi64
retains its existing key in its router vault.

Apply the server and clients using these focused playbooks:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i inventory/vds8 wireguard-vds8.yml
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/wireguard-vds8.yml
```

The main L2TP clients connect to K16_112 (`86.110.170.70`) with their existing
MPPE128 encryption and `use-ipsec=no`. The server endpoint is
`10.250.3.112/32` on each tunnel; clients are `10.250.3.64/32`
(`3Ekipazhnyi64`), `10.250.3.21/32` (`k16_21`), and `10.250.3.24/32` (`Misha`).
Their shared password is the encrypted `l2tp_k16_password` variable in
`vault/common.yml`. Ansible uses these client addresses for management.

To reapply these settings sequentially:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/l2tp-k16.yml
```

For an initial migration from the old `10.9.255.*` addresses, add
`-e migrate_from_old=true`. Each run reconnects the selected L2TP interfaces.

The four main SSTP clients connect to `62.60.216.73` using the common
`sstp_vds7_password` encrypted variable in `vault/common.yml`. vds7 uses
`10.251.0.7/32` on each tunnel. Client addresses are `10.250.0.64/32`
(`3Ekipazhnyi64`), `10.250.0.21/32` (`k16_k21` on `k16_21`),
`10.250.0.112/32` (`k16_k112` on `K16_112`), and `10.250.0.24/32` (`Misha`).

To apply only these SSTP settings and verify each tunnel sequentially:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/sstp-vds7.yml
```

This operation reconnects each SSTP interface. Existing PPP LAN routes are
preserved. It does not reconcile unrelated exported configuration.

Each router has a directory under `routers/<identity>/`: `Logia_Kitchen` is
10.9.0.2, `Logia_SouthRoom` is 10.9.0.3, and `K16_112` is 10.9.0.1.
`vds7_CHR` is 62.60.216.73 and uses SSH port 20022. Connection settings for
every router are stored in `host_vars/<identity>.yml`, including an explicit
`router_port` of either 22 or 20022.
`3Ekipazhnyi64` is 10.250.3.64, `k16_21` is 10.250.3.21, and `Misha` is
10.250.3.24; all three use SSH port 20022.
`<identity>.yml` contains its desired settings and `<identity>.rsc` is the export
with sensitive fields hidden. The matching `vault/secrets_<identity>.yml` holds secret values and the
complete `show-sensitive` export. The repository already ignores `vault/`
directories. The delivered secrets file is Ansible Vault encrypted using the
repository's configured Vault password and has mode 0600.

Run from the repository root:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/apply.yml --check
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/apply.yml
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/apply.yml -e router_identity=Logia_SouthRoom --check
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/apply.yml -e router_identity=Logia_SouthRoom
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/apply.yml -e router_identity=K16_112 --check
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/apply.yml -e router_identity=K16_112
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/apply.yml -e router_identity=vds7_CHR --check
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/apply.yml -e router_identity=vds7_CHR
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/apply.yml -e router_identity=k16_21 --check
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook -i localhost, mikrotik/apply.yml -e router_identity=Misha --check
```

Use `-e router_identity=Logia_Kitchen` to select a configuration. The playbook
loads its address, user, port, and key from `host_vars/Logia_Kitchen.yml`; SSH
also uses your existing OpenSSH ProxyJump configuration.
Edit the YAML records and secrets to change desired settings. Each record has
a RouterOS menu `path`, a stable `selector` for list entries, and `values`.
`create: true` allows adding missing entries; built-in entries must exist.
The LCD page uses its exported numeric index. Export order is preserved.
Repeated matching entries use an `occurrence` index in export order. Firewall
entries without a unique name use their captured identifying properties.
Review selectors when changing those properties; selector changes can create
new entries, and firewall/routing rule order is not enforced. Check mode does
not prove replacement-router restore behavior.
The transient `/system keymat-provider` QKD artifact is excluded because
RouterOS may export it briefly and then remove it without a configuration change.

The local `routeros_ssh` Ansible module uses a shared `module_utils` parser,
reads the live sensitive export, compares
configured properties, and uses guarded add/set commands for differences. It
supports check mode and reports changes only when needed. It refuses ambiguous
selectors and suppresses sensitive diagnostics. Extra unmanaged entries are
preserved. Removing a YAML record does not delete a router entry. Changing a
selector can add a new entry: remove the old entry explicitly after review.
Rule order and factory reset/replacement provisioning are not managed here.

No additional Ansible collection or pip package is required for applying this
configuration: it uses ansible-core and OpenSSH. `capture.py` additionally uses
PyYAML (already present with this Ansible installation). A RouterOS command
module alone does not provide reconciliation; the bundled module implements it.

`python3 mikrotik/capture.py 10.9.0.3` refreshes both exports and generated YAML
in the directory named after the router identity and writes connection details
to `host_vars/<identity>.yml`. `--user`, `--key`, and `--port` override SSH
credentials. The default SSH key is `~/.ssh/priv/ansible`, expanded against the
local user's home on Ubuntu or macOS. Captures also store explicit keys under
the current user's home using `~/` to avoid machine-specific path changes.
This overwrites local desired state and secrets; only run it
when intentionally taking a fresh snapshot.
Secret references are matched by record identity rather than export position,
so unrelated additions or removals do not renumber existing references. New
references use a stable identity hash. Export timestamps are omitted while the
RouterOS version is retained. Existing Vault snapshots stay encrypted during
refresh, and their ciphertext is preserved when their contents are unchanged.
Review the generated selectors
before using captures from other routers. The parser covers this router's
export syntax, not every possible RouterOS script or command.
Use `python3 mikrotik/capture.py 62.60.216.73 --port 20022` for a router on a
non-default SSH port. Captures save the selected port in `host_vars`.
Script `source` and scheduler `on-event` values are always stored in secrets,
including bodies that RouterOS leaves visible in a non-sensitive export. The
public `.rsc` replaces them with placeholders; use the encrypted original for
an intact text export. Run syntax regression tests using
`python3 -m unittest discover -s mikrotik/tests`.

RouterOS text exports omit user passwords, installed certificates/private keys,
SSH keys, files, and runtime state. The sensitive export is therefore a full
text configuration export, not a complete disaster recovery backup. RouterOS
also omits unchanged defaults; this configuration manages the captured settings,
not every factory default. Sensitive get operations require sufficient account
permissions. Write-only values cannot be compared reliably over SSH.

After refreshing a capture, encrypt its new plaintext secrets file using the
configured Vault password:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-vault encrypt mikrotik/routers/Logia_SouthRoom/vault/secrets_Logia_SouthRoom.yml
```

The playbook loads either plaintext or Vault-encrypted secrets and uses
`no_log: true`. Do not use `--diff` or print the sensitive export.

WireGuard router addresses are consolidated in `10.250.1.0/24`: Linux vds1/vds2/vds5/vds6/vds8 use `.1/.2/.5/.6/.8`, vds7 uses `.7`, and MikroTik clients use `.21/.24/.64/.112`. Active OSPF interfaces use `/24`; the existing vds2/vds5/vds6 links use `/32` addresses. Run `wireguard-network.yml` with all five Linux inventories and localhost to migrate the existing links. The obsolete vds5 wg0 mesh and K16 legacy WireGuard interfaces are retired; the phone VPN is disabled and its old range removed. PPP address ranges remain separate.
