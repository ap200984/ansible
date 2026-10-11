#!/usr/bin/env python3
"""Reset only Google IPv4 sessions that still use the pre-GRE NAT path."""
import argparse
import ipaddress
import json
import re
import subprocess

def stale_connections(prefixes, connections, gre_address):
    networks = [ipaddress.ip_network(p['address']) for p in prefixes]
    stale = []
    for connection in connections:
        try:
            destination = ipaddress.ip_address(connection['dst-address'].split(':')[0])
        except (KeyError, ValueError):
            continue
        if not any(destination in network for network in networks):
            continue
        reply_destination = str(connection.get('reply-dst-address', '')).split(':')[0]
        if reply_destination == gre_address:
            continue
        entry_id = connection.get('.id', '')
        if not re.fullmatch(r'\*[0-9A-Fa-f]+', entry_id):
            raise ValueError('Invalid connection identifier')
        stale.append(entry_id)
    return stale

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--ssh', required=True)
    parser.add_argument('--gre-address', required=True)
    args = parser.parse_args()
    transport = json.loads(args.ssh)
    def query(command):
        result = subprocess.run(transport + [command], capture_output=True, text=True, check=True, timeout=30)
        return json.loads(result.stdout)
    prefixes = query(':put [:serialize to=json [/ip firewall address-list print as-value where list=google_ips]];')
    connections = query(':put [:serialize to=json [/ip firewall connection print as-value]];')
    stale = stale_connections(prefixes, connections, args.gre_address)
    for offset in range(0, len(stale), 50):
        result = subprocess.run(transport + ['/ip firewall connection remove ' + ','.join(stale[offset:offset+50])], capture_output=True, text=True, check=True, timeout=30)
        if 'failure:' in result.stdout or 'syntax error' in result.stdout:
            raise RuntimeError('Targeted connection reset failed')
    print('RESET_OLD_GOOGLE_SESSIONS', len(stale))
