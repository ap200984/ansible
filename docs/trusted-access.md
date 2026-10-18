# Trusted access and SSH protection

`trusted-access.yml` is the canonical Ansible entry point for the shared trust
policy. It manages Linux firewalls on `vds1`, `vds2`, `vds5`, `vds6`, and
`vds8`; RouterOS firewalls on `vds7_CHR`, `K16_112`, `3Ekipazhnyi64`, `k16_21`,
and `Misha`; and SSH protection on every published Linux SSH endpoint.

The `trusted_networks` set/list contains these exact prefixes:

| Purpose | Prefix |
| --- | --- |
| Loopbacks | `10.255.0.0/24` |
| SSTP | `10.250.0.0/24` |
| WireGuard | `10.250.1.0/24` |
| AmneziaWG | `10.250.2.0/24` |
| L2TP | `10.250.3.0/24` |
| GRE | `10.250.4.0/24` |
| K16_112 | `10.9.0.0/23` |
| 3Ekipazhnyi64 | `10.10.0.0/24` |
| k16_21 | `10.11.0.0/24` |

`trusted_hosts` contains the seven public `/32` addresses declared in
`group_vars/all/main.yml`. Trusted networks may reach the router/host itself and
may be forwarded. Trusted public hosts may reach the router/host itself, but do
not receive a general forwarding permit. Both Linux and RouterOS put these
rules before their terminal drop rules. Source NAT exemptions apply only to
traffic between trusted networks.

The playbook removes the older `tunnel_networks`, broad `10.250.0.0/16` and
`10.255.0.0/16` permits, old RouterOS shared-network rules, and the obsolete
trusted-host FORWARD permit. It also removes source-specific `/32` INPUT
accepts when that address is already covered by `trusted_networks` or
`trusted_hosts`; a boot service runs after the tunnel firewall helpers to keep
the rule set compact. The service also fixes the first six INPUT rules in this
order: loopback, established/related, trusted hosts, trusted networks, SSH
blacklist, and the public SSH listener. It removes the obsolete `allowed_hosts`
permit, TCP 56685 permit, redundant echo-request DROP and broad WireGuard UDP
permit. Existing public service permits and non-ACCEPT safeguards
remain intact. Machines without a public edge policy do not receive the
general trusted firewall. `vds3` and `k16_k112_server` receive only the SSH
blacklist rule because their SSH services are published through K16_112 NAT.

The `ssh_bruteforce` role protects SSH with fail2ban. Failed attempts from three
distinct addresses in one `/24` within ten minutes trigger a two-week prefix
entry in the `Blacklist` ipset. The DROP rule is the
first INPUT rule and is restored at boot. The local protected port is `19022`
on the public VDS hosts and `22` on NAT targets `vds3` and
`k16_k112_server`. The fail2ban database retention exceeds the ban duration.

Apply and verify from the repository root:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local \
ANSIBLE_SSH_CONTROL_PATH_DIR=/tmp/ansible-cp \
ansible-playbook -i inventory -i localhost, trusted-access.yml \
  --private-key ~/.ssh/priv/ansible -e @vars/logging-transport.example.yml

ANSIBLE_LOCAL_TEMP=/tmp/ansible-local \
ANSIBLE_SSH_CONTROL_PATH_DIR=/tmp/ansible-cp \
ansible-playbook -i inventory trusted-access-verify.yml \
  --private-key ~/.ssh/priv/ansible
```

The verifier asserts exact ipset membership and firewall scope. It also checks
the active SSH listener and fail2ban thresholds, then briefly bans and unbans
the documentation address `192.0.2.123` to exercise the real ipset action.
