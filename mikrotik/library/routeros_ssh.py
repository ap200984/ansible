#!/usr/bin/python
"""Reconcile declarative RouterOS records through the local OpenSSH client."""
import subprocess
import re
from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.routeros_export import parse_export


def quote(value):
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$').replace('\n', '\\n').replace('\r', '\\r') + '"'


def selector_value(value):
    return str(value) if value in ('yes', 'no') else quote(value)


def comparable(key, value):
    if value in ('yes', 'no'):
        return quote('true' if value == 'yes' else 'false')
    if ',' in value:
        return '[:tostr [:toarray ' + quote(value) + ']]'
    if key.endswith(('interval', 'timeout')) and re.fullmatch(r'(\d+[wdhms])+', value):
        return '[:tostr [:totime ' + quote(value) + ']]'
    return quote(value)


def arguments(record):
    return ' '.join('!' + key if key in record.get('unset', []) and value == ''
                    else key + '=' + quote(value) for key, value in record['values'].items())


def script(record, check):
    path = record['path']
    selector = record.get('selector')
    prefix = ''
    target = ''
    if selector is not None:
        conditions = ' and '.join(k + '=' + selector_value(v) for k, v in selector.items())
        find = 'find where ' + conditions if conditions else 'find'
        prefix = f':local ids [{path} {find}]; '
        if 'occurrence' in record:
            ordinal = int(record['occurrence'])
            prefix += f':set ids [:pick $ids {ordinal} {ordinal + 1}]; '
        else:
            prefix += ':if ([:len $ids] > 1) do={ :error "Ambiguous selector" }; '
        if record.get('create', False):
            args = arguments(record)
            action = '' if check else f'{path} add {args}; '
            prefix += f':if ([:len $ids] = 0) do={{ {action}:put "ANSIBLE_CHANGED" }} else={{ '
        else:
            prefix += ':if ([:len $ids] = 0) do={ :error "Missing required entry" }; '
        target = '$ids '
    elif 'number' in record:
        target = str(record['number']) + ' '
    tests = ' or '.join(f'([:tostr [{path} get {target}{key}]] != {comparable(key, value)})' for key, value in record['values'].items())
    args = arguments(record)
    action = '' if check else f'{path} set {target}{args}; '
    body = f':if ({tests}) do={{ {action}:put "ANSIBLE_CHANGED" }}'
    return prefix + body + (' }' if selector is not None and record.get('create', False) else '')


def main():
    module = AnsibleModule(argument_spec=dict(host=dict(required=True), user=dict(default='ansible'),
        port=dict(type='int', default=22),
        identity_file=dict(type='path', required=True), records=dict(type='list', elements='dict', required=True)), supports_check_mode=True)
    if not 1 <= module.params['port'] <= 65535:
        module.fail_json(msg='SSH port must be between 1 and 65535')
    ssh = ['ssh', '-p', str(module.params['port']), '-i', module.params['identity_file'], '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes',
           '-o', 'ConnectTimeout=10', module.params['user'] + '@' + module.params['host']]
    changed = []
    try:
        exported = subprocess.run(ssh + ['/export terse show-sensitive'], capture_output=True, text=True, timeout=90)
        if exported.returncode or '#error' in exported.stdout:
            raise ValueError('Export failed')
        current = parse_export(exported.stdout.replace('\r', ''))
    except (OSError, subprocess.TimeoutExpired, ValueError):
        module.fail_json(msg='Unable to read current RouterOS configuration; sensitive output withheld')
    for index, record in enumerate(module.params['records']):
        matches = []
        for candidate in current:
            if candidate['path'] != record['path']:
                continue
            if 'selector' in record:
                if record['selector'] != candidate.get('selector') and not all(
                        candidate['values'].get(k) == v for k, v in record['selector'].items()):
                    continue
            elif record.get('number') != candidate.get('number'):
                continue
            matches.append(candidate)
        if 'occurrence' in record:
            ordinal = int(record['occurrence'])
            matches = matches[ordinal:ordinal + 1]
        if len(matches) > 1:
            module.fail_json(msg=f'Ambiguous exported record {index}', changed=bool(changed))
        if matches and all(matches[0]['values'].get(k) == v for k, v in record['values'].items()):
            continue
        # Export comparison avoids RouterOS get conversions of arrays, references,
        # booleans and durations. The script also verifies selector uniqueness.
        try:
            command = script(record, module.check_mode)
            # Only changed fields are set; unchanged reference-valued fields need
            # no comparison against their internal RouterOS IDs.
            if matches:
                record = dict(record, values={k: v for k, v in record['values'].items()
                    if matches[0]['values'].get(k) != v})
                command = script(record, module.check_mode)
            result = subprocess.run(ssh + [command], capture_output=True, text=True, timeout=45)
        except (OSError, subprocess.TimeoutExpired):
            module.fail_json(msg=f'SSH failed for record {index}', changed=bool(changed))
        output = result.stdout.strip()
        if result.returncode or (output and output != 'ANSIBLE_CHANGED'):
            module.fail_json(msg=f'RouterOS reconciliation failed for record {index} ({record["path"]}); output withheld because it may contain secrets', changed=bool(changed))
        if output:
            changed.append(index)
    module.exit_json(changed=bool(changed), changed_records=changed)


if __name__ == '__main__':
    main()
