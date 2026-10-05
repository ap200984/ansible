#!/usr/bin/env python3
"""Restrict unmanaged VDS masquerade to WAN; retain Docker-owned 172.x rules."""
import ipaddress
import json
from pathlib import Path
import re
import shlex
import shutil
import subprocess

def command(*args):
    return subprocess.check_output(args, text=True)

routes = json.loads(command('ip', '-j', '-4', 'route', 'show', 'default'))
wan = {route['dev'] for route in routes if 'dev' in route}
rules = command('iptables', '-t', 'nat', '-S', 'POSTROUTING').splitlines()
for line in rules:
    rule = shlex.split(line)
    if '-j' not in rule or rule[rule.index('-j') + 1] not in ('MASQUERADE', 'SNAT'):
        continue
    if '-s' in rule and ipaddress.ip_network(rule[rule.index('-s') + 1]).subnet_of(ipaddress.ip_network('172.16.0.0/12')):
        continue  # Docker and Amnezia manage these container egress/hairpin rules.
    assert '-o' in rule and rule[rule.index('-o') + 1] in wan, 'Unexpected non-container source NAT outside the WAN; inspect before changing'
    if '-d' in rule:
        continue
    new = rule[:2] + ['!', '-d', '10.0.0.0/8'] + rule[2:]
    check = ['iptables', '-t', 'nat', '-C'] + new[1:]
    if subprocess.run(check, capture_output=True).returncode:
        subprocess.run(['iptables', '-t', 'nat'] + new, check=True)
    subprocess.run(['iptables', '-t', 'nat', '-D'] + rule[1:], check=True)
    print('NAT_RULE_RESTRICTED')
# WireGuard must not create/delete a host-wide masquerade rule on each restart.
for path in Path('/etc/wireguard').glob('wg*.conf'):
    original = path.read_text()
    result = re.sub(r'(?m)^Post(?:Up|Down)\s*=\s*iptables -t nat -[AD] POSTROUTING -o \S+ -j MASQUERADE\s*\n?', '', original)
    if result != original:
        shutil.copy2(path, str(path) + '.before-nat-policy')
        path.write_text(result)
        path.chmod(0o600)
        print('NAT_HOOK_REMOVED')
