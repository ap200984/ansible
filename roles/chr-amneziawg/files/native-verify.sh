#!/bin/sh
set -eu
case "$1" in 1|2|5|6|8) number=$1 ;; *) exit 2 ;; esac
systemctl is-active awg-quick@wg2
systemctl is-enabled awg-quick@wg2
awg show wg2 persistent-keepalive | awk '$2 != "off" && $2 != "0" {exit 1}'
ping -I wg2 -c 3 -W 2 10.250.1.7
vtysh -c 'show ip ospf neighbor' | awk '$1 == "10.255.0.7" && $3 ~ /^Full/ && $7 ~ /^wg2:/ {ok=1} END {if (!ok) exit 1}'
for destination in 10.255.0.7 10.9.0.1 10.9.1.1 10.255.0.21 10.255.0.64; do
  ping -I "10.255.0.$number" -c 3 -W 3 "$destination"
done
iptables -t nat -C POSTROUTING -s 10.0.0.0/8 -d 10.0.0.0/8 -m comment --comment internal-10-no-snat -j ACCEPT
ip route get 10.255.0.21 from "10.255.0.$number"
