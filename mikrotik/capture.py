#!/usr/bin/env python3
"""Capture RouterOS exports without logging sensitive output."""
import json
import os
from pathlib import Path
import subprocess
import re
import argparse
import sys
import hashlib

import yaml

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'module_utils'))
from routeros_export import parse_export
SSH = ['ssh', '-i', '~/.ssh/priv/ansible', '-o', 'IdentitiesOnly=yes',
       '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10']

def query(command):
    result = subprocess.run(SSH + [command], capture_output=True, text=True, check=True)
    return result.stdout.replace('\r', '')

def records(export):
    result = parse_export(export)
    result = [record for record in result if record['path'] != '/system keymat-provider']
    for record in result:
        path, operation = record['path'], record.pop('operation')
        if operation == 'add':
            keys = {
                '/interface bridge port': ['interface'],
                '/ip address': ['address', 'interface'],
                '/ip route': ['dst-address', 'routing-table', 'gateway', 'distance'],
                '/caps-man provisioning': ['master-configuration', 'name-prefix'],
                '/ip dhcp-server network': ['address'],
                '/routing bfd configuration': [],
                '/system logging': ['topics'],
                '/system ntp client servers': ['address'],
                '/interface list member': ['list', 'interface'],
                '/ip dhcp-server lease': ['mac-address', 'server'],
                '/ip firewall address-list': ['list', 'address'],
                '/ipv6 firewall address-list': ['list', 'address'],
                '/routing rule': ['routing-mark', 'table', 'src-address', 'dst-address'],
            }.get(path, ['name'] if 'name' in record['values'] else [
                key for key in record['values'] if key not in ('disabled', 'log', 'source', 'on-event')])
            record['selector'] = {key: record['values'][key] for key in keys if key in record['values']}
            if keys and not record['selector']:
                raise ValueError(f'No stable selector for {path}')
            record['create'] = True
    for record in result:
        if 'selector' not in record:
            continue
        peers = [other for other in result if other['path'] == record['path']
                 and (record['selector'] == other.get('selector') or all(
                     other['values'].get(key) == value for key, value in record['selector'].items()))]
        if len(peers) > 1:
            record['occurrence'] = next(index for index, other in enumerate(peers) if other is record)
    return result


def normalize_export(export):
    """Keep version metadata, but not the time at which export was run."""
    return re.sub(r'^# .*? by RouterOS (.+)$', r'# by RouterOS \1', export,
                  flags=re.MULTILINE)


def portable_key_path(key):
    """Save keys under the current user's home without a machine-specific prefix."""
    expanded = Path(key).expanduser()
    try:
        return '~/' + expanded.relative_to(Path.home()).as_posix()
    except ValueError:
        return str(expanded)


def record_identity(record):
    return json.dumps({key: record[key] for key in
                       ('path', 'selector', 'number', 'occurrence') if key in record},
                      sort_keys=True)


def extract_secrets(desired, redacted, previous=()):
    previous = {record_identity(record): record for record in previous}
    secrets = {}
    for index, record in enumerate(desired):
        identity = record_identity(record)
        old = previous.get(identity, {}).get('values', {})
        for key, value in list(record['values'].items()):
            if key in ('source', 'on-event') or key not in redacted[index]['values'] or redacted[index]['values'][key] != value:
                match = re.fullmatch(r'\{\{ routeros_secrets\.([A-Za-z0-9_]+) \}\}',
                                     str(old.get(key, '')))
                secret_key = (match.group(1) if match else 'record_' +
                              hashlib.sha256((identity + '\0' + key).encode()).hexdigest()[:24])
                if secret_key in secrets:
                    raise ValueError('Duplicate secret reference')
                secrets[secret_key] = value
                record['values'][key] = '{{ routeros_secrets.' + secret_key + ' }}'
    return secrets

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('host', help='Router IP or SSH hostname')
    parser.add_argument('--user', default='ansible')
    parser.add_argument('--key', default='~/.ssh/priv/ansible')
    parser.add_argument('--port', type=int, default=22)
    options = parser.parse_args()
    SSH[2] = os.path.expanduser(options.key)
    if not 1 <= options.port <= 65535:
        parser.error('--port must be between 1 and 65535')
    SSH.extend(['-p', str(options.port)])
    SSH.append(options.user + '@' + options.host)
    os.umask(0o077)
    identity = query(':put [/system identity get name]').strip()
    if not identity or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-' for c in identity):
        raise ValueError('Router identity is not a safe filename')
    sensitive = normalize_export(query('/export terse show-sensitive'))
    public = normalize_export(query('/export terse'))
    if '#error' in sensitive or '#error' in public:
        raise RuntimeError('RouterOS reported an incomplete export')
    router_dir = ROOT / 'routers' / identity
    host_vars_dir = ROOT / 'host_vars'
    secrets = router_dir / 'secrets'
    secrets.mkdir(parents=True, exist_ok=True)
    host_vars_dir.mkdir(exist_ok=True)
    desired = records(sensitive)
    redacted = records(public)
    if len(desired) != len(redacted) or any(
            left['path'] != right['path'] or left.get('selector') != right.get('selector')
            for left, right in zip(desired, redacted)):
        raise RuntimeError('Router configuration changed between exports; retry capture')
    desired_file = router_dir / f'{identity}.yml'
    previous = yaml.safe_load(desired_file.read_text())['routeros_records'] if desired_file.exists() else []
    secret_values = extract_secrets(desired, redacted, previous)
    secret_file = secrets / f'secrets_{identity}.yml'
    secret_data = {
        'routeros_secrets': secret_values, 'routeros_sensitive_export': sensitive,
    }
    encrypted = secret_file.exists() and secret_file.read_text().startswith('$ANSIBLE_VAULT;')
    old_data = None
    if encrypted:
        result = subprocess.run(['ansible-vault', 'view', str(secret_file)],
                                capture_output=True, text=True, check=True)
        old_data = yaml.safe_load(result.stdout)
        old_data['routeros_sensitive_export'] = normalize_export(old_data['routeros_sensitive_export'])
    if old_data != secret_data:
        if encrypted:
            result = subprocess.run(['ansible-vault', 'encrypt', '--output', str(secret_file)],
                                    input=yaml.safe_dump(secret_data, sort_keys=False),
                                    capture_output=True, text=True, check=True)
        else:
            secret_file.write_text(yaml.safe_dump(secret_data, sort_keys=False))
        secret_file.chmod(0o600)
    (host_vars_dir / f'{identity}.yml').write_text(yaml.safe_dump({
        'router_host': options.host, 'router_user': options.user,
        'router_port': options.port,
        'router_ssh_key': portable_key_path(options.key),
    }, sort_keys=False))
    (router_dir / f'{identity}.yml').write_text(yaml.safe_dump({
        'routeros_records': desired,
    }, sort_keys=False))
    # Script bodies can contain credentials that RouterOS does not classify as
    # sensitive. Keep the original export only inside the encrypted secrets.
    public = re.sub(r'\\\n[ \t]*', '', public)
    public = re.sub(r'\b(source|on-event)=(?:"(?:\\.|[^"\\])*"|[^\s"]+)',
                    lambda match: match.group(1) + '="<stored in secrets>"', public)
    (router_dir / f'{identity}.rsc').write_text(public)
    print(json.dumps({'identity': identity, 'export_lines': len(public.splitlines())}))
