# Linux standard file logging

The role uses the distribution's `rsyslog` and its `imfile` module on Debian and
Ubuntu. It sends newline-delimited JSON over TCP to `10.9.0.90:10514`; normal local
logging and rotation remain enabled. The supported distribution packages provide
rsyslog 8.1905 or newer, required for a dedicated imfile state directory. Package
installation and APT cache refresh run only when `/usr/sbin/rsyslogd` is absent;
hosts already running rsyslog do not contact unrelated package repositories.

Default inputs are the exact active text files `syslog`, `auth.log`, `kern.log`,
`daemon.log`, `messages`, `debug`, `user.log`, `mail.log`, `mail.err`, `mail.warn`,
`mail.info`, `cron.log`, `dpkg.log`, `alternatives.log`, `boot.log`,
`apt/history.log`, `apt/term.log`, `cloud-init.log`, and `cloud-init-output.log`
under `/var/log`. Missing files can appear later. Rotated archives, journal files,
`wtmp`, `btmp`, and `lastlog` are excluded.

Each event contains the raw file line in `message`, the inventory name in
`host.name`, the exact source in `log.file.path`, a `linux.*` dataset, and
`event.module: system`. The input marker is `log_source: linux`. Inputs use their
own ruleset so reading local rsyslog files cannot write those events back to the
same files.

Existing active-file content is read once on the initial deployment. imfile
persists offsets every 100 records and on normal shutdown, follows rename/create
rotation and truncation, and resumes after restart. A disk-assisted output queue
buffers retries when ELK is unavailable; its default disk limit is 1 GB per host.
The queue is saved on orderly shutdown. This is ordinary TCP forwarding rather
than transactional delivery, so it does not promise exactly-once ingestion.

`inotify` is the default file monitor. On vds3, Ubuntu's AppArmor profile permits
the log files but denies directory watches on `/var/log/` and its parents. After
rotation, imfile kept reading the old inode. Its host variables select `polling`
with a two-second interval to discover replacement files while preserving the
distribution security profile. The small list of exact paths bounds the work.

`syslog` receives `adm` membership when the distribution drops daemon privileges.
The state and queue directory belongs to the daemon's configured account. Before
any restart, Ansible validates the entire `/etc/rsyslog.conf`; a failed validation
restores the previous managed drop-in and leaves the running daemon in place.

Override these variables in inventory as needed:

```yaml
linux_log_shipping_host: 10.9.0.90
linux_log_shipping_port: 10514
linux_log_shipping_state_directory: /var/spool/rsyslog/elk-files
linux_log_shipping_queue_max_disk_space: 1g
linux_log_shipping_queue_size: 10000
linux_log_shipping_state_interval: 100
linux_log_shipping_file_mode: inotify
linux_log_shipping_polling_interval: 2
linux_log_shipping_files:
  - path: /var/log/syslog
    dataset: linux.syslog
  - path: /var/log/auth.log
    dataset: linux.auth
```

The combined playbook configures ELK, every VDS, and every managed MikroTik:

```bash
ansible-playbook -i inventory logging.yml
ansible-playbook -i inventory logging-verify.yml
```

Verification emits a unique marker through both VDS syslog facilities and through
MikroTik warning/debug logging, then requires Elasticsearch to contain every VDS
in both `syslog` and `auth.log` and every router at both levels. It also checks
probe parsing failure counts. Elasticsearch responses contain aggregations only,
never log documents. An explicit marker can be passed with
`-e logging_test_marker=ansible-elk-check-20261017`.

Expected sources can be overridden with the list variables
`logging_expected_linux_hosts` and `logging_expected_mikrotik_hosts` when testing
an intentionally smaller inventory. The default lists cover all six VDS and
seven MikroTik devices currently managed by this repository.

Additional standard OS files include `dmesg`, `ufw.log` and the three active
`unattended-upgrades` logs. They are watched when present.
