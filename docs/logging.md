# Central OS and RouterOS logging

`logging.yml` configures the ELK receiver first, all six VDS from `inventory/`
(`vds1`, `vds2`, `vds3`, `vds5`, `vds6`, `vds8`) second, and all seven routers
from `mikrotik/host_vars/` last. All remote changes use Ansible.

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local ansible-playbook \
  -i inventory -i localhost, logging.yml --private-key ~/.ssh/priv/ansible
```

The ELK host uses the workstation's normal SSH configuration. The custom
RouterOS module uses its pinned `mikrotik/known_hosts` and does not read SSH
configuration. If private router addresses need a jump, also supply
`router_proxy_command`, as described in `mikrotik/README.md`. For example:

```sh
-e '{"router_proxy_command":"ssh -F /dev/null -p 19020 -i ~/.ssh/priv/user -o BatchMode=yes -W %h:%p user@86.110.170.70"}'
```

For the current controller, a reusable explicit SSH transport example is supplied
in `vars/logging-transport.example.yml`. It sends only ELK and the routers through
the existing jump host and checks the jump host against the repository's pinned
key. For example, from the repository root:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local \
ANSIBLE_REMOTE_TEMP=/tmp/ansible-remote-local \
ANSIBLE_SSH_CONTROL_PATH_DIR=/tmp/ansible-cp \
ansible-playbook -i inventory -i localhost, logging.yml \
  --private-key ~/.ssh/priv/ansible -e @vars/logging-transport.example.yml
```

Run `logging-verify.yml` with the same options to generate and verify probes.

Tags `logging_server`, `logging_linux`, and `logging_mikrotik` select deployment
stages. `--check` previews changes; actual service validation runs on application.
To limit routers, set `mikrotik_logging_routers` to a list of their inventory names.
Linux hosts can be selected with `--limit` (include `elk` and `localhost` when
also running the receiver/router stages).

## Sources and transport

Debian/Ubuntu use the distribution's rsyslog `imfile` module. Explicit active
text files include syslog, auth, kernel, daemon, messages, debug, user, mail,
cron, dpkg, apt history/terminal, alternatives, boot, dmesg, UFW, unattended-upgrades
and cloud-init logs.
The list is configurable with `linux_log_shipping_files`.
Missing files are watched for later creation. Binary journals, wtmp/btmp/lastlog,
compressed files and old rotated names are excluded. Existing active-file
contents are shipped once; persistent offsets continue after daemon restarts
and normal rename rotation. Overlapping local syslog files can contain the
same event; each file remains identifiable by `log.file.path`.
The default monitor uses inotify. vds3 selects a two-second polling interval:
its Ubuntu AppArmor profile permits log file reads but denies parent directory
watches, so imfile had kept following the old inode after rotation. Polling
detects replacement files and keeps the distribution security profile intact.

Logia_SouthRoom also uses the existing managed NTP service `10.9.1.70` before
logging verification. Its previous server `10.9.0.1` had no NTP listener, leaving
the router clock nearly five days behind. Ansible adds the working time source
and waits for synchronization; existing source records are retained.

Each line is JSON with inventory `host.name`, `log.file.path`, `event.dataset`
and the raw message, sent to `10.9.0.90:10514/TCP`. An isolated ruleset avoids
writing harvested messages back into the watched local files. The sender uses
an asynchronous disk-assisted queue and retries while ELK is unavailable.
Queue/state files are in `/var/spool/rsyslog/elk-files`. Full rsyslog configuration
is validated before restart; an invalid managed drop-in is restored.

RouterOS 7.18+ uses native CEF over `10.9.0.90:5514/TCP`, with newline framing,
ISO8601 timestamps and a dedicated `ansibleelk` action. Complementary `!debug`
and `debug` rules deliver every topic once to that action. Existing local and
remote logging actions are preserved. RouterOS TCP buffering is in RAM and is
lost on reboot; its finite queue does not provide durable delivery.

The new Docker published ports bind only to the ELK private address. Traffic
uses the private routed/tunnel network. The logging playbook adds no public
listener. The corresponding internal routing and firewall corrections are
documented in [internal-networks.md](internal-networks.md). Linux queue size, receiver ports and
server bind address can be overridden through their role defaults.

## Parsing and storage

Logstash handles Debian/Ubuntu ISO8601 and BSD syslog envelopes, process/PID,
SSH authentication outcomes/user/source, dpkg actions, apt history fields,
alternatives, cloud-init and unattended-upgrades timestamps. Unstructured text is retained.
RouterOS CEF is decoded with the bundled codec into structured host, router,
source/destination, interface, protocol, user and outcome fields when provided
by the router. Topics and original CEF severity labels are retained; ECS
severity is numeric. Raw records are stored as `event.original`.

Daily indices are selected using parsed event time in UTC:

- `linux-logs-yyyy.MM.dd`
- `mikrotik-logs-yyyy.MM.dd`

The managed composable Elasticsearch template defines date/IP/number types and
searchable message text. No automatic deletion policy is configured. Parse
failures stay indexed with failure tags and their original record. BSD syslog
without a year uses Logstash's date inference; OS timestamps without an offset
use UTC, matching the repository's Linux timezone role. RouterOS ISO8601 offsets
are preferred; BSD fallback follows the recorded UTC/Moscow router settings.
Auditbeat and other Beats continue using port 5044 and their existing daily
index families. ILM automatic rollover is disabled in this output so daily
index names are honored.

The receiver stages and tests the pipeline with the actual Logstash Docker
image before replacing the running configuration. A persisted Logstash queue
is mounted at `/opt/elk/logstash/data`. Elasticsearch and Kibana retain the
repository's existing deployment settings.

For end-to-end verification, use `logging-verify.yml`; it emits test events
through Ansible and checks source/level/file aggregations without displaying
potentially sensitive log records. The parser fixture playbook is under
`tests/logging/`.
