#!/usr/bin/env python3
"""Discard only failed-consolidation artifacts after rollback verification."""
from pathlib import Path
import shlex
import shutil
import subprocess

for line in subprocess.check_output(['iptables', '-S', 'INPUT'], text=True).splitlines():
    args = shlex.split(line)
    if args[:1] == ['-A'] and 'linux-normalized-wg' in args:
        subprocess.run(['iptables', '-D'] + args[1:], check=True)
for filename in ['/etc/wireguard/linux-normalized.json',
                 '/usr/local/sbin/linux-normalized-firewall',
                 '/etc/systemd/system/linux-normalized-firewall.service',
                 '/etc/systemd/system/wireguard-routing.service']:
    Path(filename).unlink(missing_ok=True)
checkpoint = Path('/run/linux-wg-normalize')
if checkpoint.is_dir():
    shutil.rmtree(checkpoint)
subprocess.run(['systemctl', 'daemon-reload'], check=True)
with open('/etc/iptables/rules.v4', 'w') as out:
    subprocess.run(['iptables-save'], stdout=out, check=True)
print('Failed consolidation artifacts removed; restored configurations retained.')
