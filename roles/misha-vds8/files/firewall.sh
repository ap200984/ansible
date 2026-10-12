#!/bin/sh
set -eu
iptables -C FORWARD -i wg4 -s 10.255.2.24/32 -j ACCEPT 2>/dev/null ||
    iptables -I FORWARD 1 -i wg4 -s 10.255.2.24/32 -j ACCEPT
iptables -C FORWARD -o wg4 -d 10.255.2.24/32 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null ||
    iptables -I FORWARD 1 -o wg4 -d 10.255.2.24/32 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# Remove the initial unrestricted version when upgrading this helper.
if iptables -t nat -C POSTROUTING -s 10.255.2.24/32 -o net0 -j MASQUERADE 2>/dev/null; then
    iptables -t nat -D POSTROUTING -s 10.255.2.24/32 -o net0 -j MASQUERADE
fi
iptables -t nat -C POSTROUTING -s 10.255.2.24/32 ! -d 10.0.0.0/8 -o net0 -j MASQUERADE 2>/dev/null ||
    iptables -t nat -A POSTROUTING -s 10.255.2.24/32 ! -d 10.0.0.0/8 -o net0 -j MASQUERADE
