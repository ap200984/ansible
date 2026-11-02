# VDS4 standby

`host_vars/vds4.yml` selects the same ten container services as VDS6 after
excluding ejabberd. They use `vds04.space` and VDS4's public address
`2.31.171.214`. Application data is copied separately with the snapshot and restore workflow below,
including GitLab encryption secrets, Jenkins credentials, ownCloud SQLite data,
and runner configuration.

| Link | VDS4 address | Remote address | Public UDP endpoints |
| --- | --- | --- | --- |
| VDS4 wg0 ↔ VDS7 vds4_interface | 10.250.6.4/24 | 10.250.6.7 | 2.31.171.214:56694 ↔ 62.60.216.73:56694 |
| VDS4 wg1 ↔ VDS5 wg-vds4 | 10.250.2.4/24 | 10.250.2.5 | 2.31.171.214:56702 ↔ 217.144.189.206:56714 |

VDS4 advertises `10.255.0.4/32` through OSPF with BFD. Its link costs are 200
through VDS5 and 1000 through VDS7. VDS6 remains reachable through the routed
fabric. Existing GRE egress on VDS6 is not duplicated.

Run from the repository root with the normal SSH and Vault credentials:

```sh
ansible-playbook -i inventory/vds5 -i inventory/vds4 vds4-backup.yml
ansible-playbook -i inventory/vds4 02_deploy_services.yaml
```

The RouterOS step uses its public management address through VDS8. It expects
the previously verified SSH keys in `/tmp/ansible-known-hosts`; set that file up
from trusted device keys before using a new controller. The Linux connection
and Vault defaults can be overridden through the normal Ansible CLI options.

Private tunnel identities are generated once at
`/etc/wireguard/vds4-backup.key` on VDS4 and VDS5. The RouterOS private identity
stays on VDS7. The playbook transfers only public identities between endpoints.
Initial Linux firewall and FRR checkpoints are in `/var/backups/vds4-backup/`.

Jenkins uses the reserved container address `172.20.240.100` so its private
network SNAT rule remains valid when the container restarts.

The HTTPS proxy uses `certificates/vds4-proxy-server.crt`, signed by the existing
proxy CA, with SANs for `vds04.space`, its wildcard, and `2.31.171.214`. The
existing Vault key is used; clients continue to trust the existing proxy CA.

Reg.ru API access is allowlisted for VDS4. Certbot obtains and renews the
wildcard certificate directly from VDS4; no source-host proxy is required.

DNS replacement is separate from deployment:

```sh
ansible-playbook -i inventory/vds5 vds4-dns.yml
```

That playbook changes only A records for `@`, `www`, and `*` in `vds04.space`
to `2.31.171.214`. It adds each desired address before removing superseded
addresses. It preserves other record types and names. The initial replacement of the previous `95.163.244.138` addresses was
explicitly approved before applying the DNS playbook.

## Application snapshots and restore

Run `vds4-data-backup.yml` against VDS6 to create a native GitLab backup and
private filesystem snapshots. Jenkins is paused briefly while archiving its
home; ownCloud enters maintenance mode and stops cleanly while archiving its
data. Both primary containers are resumed in Ansible `always` blocks. A
SQLite backup is created and checked for integrity. Snapshots and GitLab
secrets are stored in root-only `/var/backups/vds4-replication`.

```sh
ansible-playbook -i inventory/vds6 vds4-data-backup.yml
ansible-playbook -i inventory/vds6 -i inventory/vds4 vds4-data-transfer.yml
ansible-playbook -i inventory/vds4 vds4-data-restore.yml \
  -e vds4_restore_acknowledged=true
```

The transfer streams directly between the servers over SSH. A temporary
source-IP-restricted key can run only the receiver for fixed snapshot filenames;
the key and receiver are removed in `always` tasks. No private application data
is saved on the controller. SHA-256 checksums are verified on VDS4. The restore
preserves the initial empty Jenkins, ownCloud, and runner volumes in the
snapshot directory before replacing them. It restores GitLab through the
native same-version restore command and checks encrypted records afterward.
Both sides must use exactly the same GitLab version and ownCloud version.

The restore is intentionally a one-time bootstrap: the preserved `pristine-*`
directories prevent an accidental second overwrite. It is a point-in-time
copy; changes made to VDS6 afterward are not continuously replicated. Retain
or rotate the root-only archives according to the desired recovery window.

Jenkins runs builds normally with two built-in executors. The original
`init.groovy.d/vds4-standby.groovy` restriction was removed at the user's
request, and quiet mode was cancelled. The restore preserves the primary's
executor configuration and does not install that restriction again.

GitLab Sidekiq is disabled through
`gitlab_extra_omnibus_config`; the GitLab runner remains stopped with no
restart policy through `service_standby_containers`. These controls prevent
restored GitLab CI workers from running duplicate work.

For GitLab promotion, coordinate the primary's shutdown first, enable Sidekiq, and remove
the runner from `service_standby_containers` before redeploying services.
Review restored job and integration URLs before enabling workers; application
data can still contain references to the primary's domain.
GitLab WebAuthn registrations are tied to the original domain; users may
need to register security keys again on `gitlab.vds04.space`.
