#!/bin/sh
set -eu
ipset create ospf-routed hash:net -exist
for prefix in 10.250.0.0/16 10.251.0.0/24 10.255.0.0/16 10.9.0.0/16 10.10.0.0/16; do
    ipset add ospf-routed "$prefix" -exist
done
iptables -C INPUT -i wg0 -p ospf -s 10.250.0.0/16 -j ACCEPT 2>/dev/null ||
    iptables -I INPUT 1 -i wg0 -p ospf -s 10.250.0.0/16 -j ACCEPT
iptables -C INPUT -i wg0 -m set --match-set ospf-routed src -m set --match-set ospf-routed dst -j ACCEPT 2>/dev/null ||
    iptables -I INPUT 1 -i wg0 -m set --match-set ospf-routed src -m set --match-set ospf-routed dst -j ACCEPT
iptables -C FORWARD -i wg0 -o wg0 -m set --match-set ospf-routed src -m set --match-set ospf-routed dst -j ACCEPT 2>/dev/null ||
    iptables -I FORWARD 1 -i wg0 -o wg0 -m set --match-set ospf-routed src -m set --match-set ospf-routed dst -j ACCEPT
iptables -t nat -C POSTROUTING -m set --match-set ospf-routed src -m set --match-set ospf-routed dst -j ACCEPT 2>/dev/null ||
    iptables -t nat -I POSTROUTING 1 -m set --match-set ospf-routed src -m set --match-set ospf-routed dst -j ACCEPT

for prefix in 10.250.0.0/16 10.255.0.0/16; do
    for chain in INPUT FORWARD; do
        iptables -C "$chain" -s "$prefix" -j ACCEPT 2>/dev/null ||
            iptables -I "$chain" 1 -s "$prefix" -j ACCEPT
    done
done
