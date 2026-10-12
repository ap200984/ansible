# Misha host egress through VDS8

Misha routes all routed IPv4 traffic from `192.168.0.190/32` through VDS8
(`10.255.0.8`) using the existing `wg_vds8` native AWG/container link. The
`misha_vds8` routing table has a default via `10.255.0.8@main` and a blackhole
fallback. A main-table `/32` pins that loopback to `wg_vds8`, so recursive
resolution cannot send internet packets to another VDS next hop.

The first two prerouting mangle rules match only the source address. They mark
the connection and route with `passthrough=no`; destination address lists,
protocol, port, connection state and local/private destination exceptions are
not used. Google, Telegram, Meta, ChatGPT and the old host-specific SSTP rule
cannot take precedence. The former host-specific SSTP mangle rule is disabled.
Forward and return accepts precede FastTrack, and TCP SYN MSS is clamped to the
tunnel MTU.

Misha source-NATs this host to `10.255.2.24` on `wg_vds8`, which is already
permitted by VDS8's authenticated Misha peer. The router peer permits all IPv4
destinations. VDS8 forwards tunnel traffic and established replies, then
masquerades public destinations on its WAN `net0`. Its private-network NAT
exemptions remain applicable to private destinations.

`misha-vds8-host.yml` installs/enables `misha-vds8-firewall.service` on VDS8,
applies the router policy and resets only host sessions retaining an obsolete
NAT path. Supply the usual VDS8 SSH port/key and pinned router jump transport:

```sh
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local \
ansible-playbook -i inventory/vds8 -i localhost, misha-vds8-host.yml \
  -e @/path/to/connection.yml
```

`network-policy.yml` and `restore-vds-routing.yml` reinstall the VDS8 helper.
Google/service GRE deployment reapplies the host override last, preserving its
priority when service rules are reordered. Misha AWG cutover preserves the
expanded VDS8 peer destinations. Full Misha capture and encrypted restore
manifest contain the router policy.

Validation on 2026-10-12: the source rules are the first prerouting rules;
the default is active with `immediate-gw=10.255.0.8%wg_vds8`. The VDS8 loopback
answered three of three pings. A temporary router-originated HTTPS probe
through this table returned VDS8's public address `194.113.106.136`; its
probe rule was removed afterward. The firewall service is active and enabled,
and all seven VDS8 BFD peers, including Misha, are Up. The host itself did not
answer ping and its ARP entry was failed, so live client behavior could not be
verified during this deployment.
