# MikroTik configuration

Each router has a directory under `routers/<identity>/`: `Logia_Kitchen` is
10.9.0.2, `Logia_SouthRoom` is 10.9.0.3, and `K16_112` is 10.9.0.1.
`vds7_CHR` is 62.60.216.73 and uses SSH port 20022. Connection settings for
every router are stored in `host_vars/<identity>.yml`, including an explicit
`router_port` of either 22 or 20022.
`3Ekipazhnyi64` is 10.9.255.27, `k16_21` is 10.9.255.3, and `Misha` is
10.9.255.23; all three use SSH port 20022.
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
