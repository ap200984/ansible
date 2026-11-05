#!/usr/bin/env python3
"""Remove only firewall rules belonging to the retired VDS6 tunnels."""
import argparse
import shlex
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('host', choices=['vds5', 'vds6'])
args = parser.parse_args()
retired = ({'wg-vds6', '195.245.239.82/32'} if args.host == 'vds5' else
           {'gre-k16', 'gre-3ekip', 'gre-k21', 'gre-misha', 'wg0', 'wg1',
            'google-gre', 'jenkins-private-snat'})
snapshot = subprocess.check_output(['iptables-save'], text=True)
table = None
removed = 0
for line in snapshot.splitlines():
    if line.startswith('*'):
        table = line[1:]
    elif line.startswith('-A '):
        rule = shlex.split(line)
        if retired.intersection(rule):
            subprocess.run(['iptables', '-w', '10', '-t', table, '-D'] + rule[1:], check=True)
            removed += 1
print(f'RETIRED_FIREWALL_RULES {removed}')
