"""Run as root on a managed host; inject and clean up documentation-IP failures."""
import ctypes
import json
import pathlib
import subprocess
import syslog
import time

HELPER = '/usr/local/sbin/ssh-subnet-aggregate'


def run(*args):
    return subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def verify():
    print(run('fail2ban-client', 'get', 'sshd-subnet', 'ignorecommand').stdout)
    assert run('fail2ban-client', 'get', 'sshd-subnet', 'bantime').stdout.strip() == '1209600'
    rules = run('iptables', '-S', 'INPUT').stdout.splitlines()
    blacklist_position = 5 if any('--match-set trusted_hosts src' in rule for rule in rules) else 1
    assert 'ansible-ssh-blacklist' in rules[blacklist_position], 'Unexpected blacklist position'
    print(rules[:3])
    # The production journal selector includes _COMM=sshd. Use that name for
    # this test process so the actual filter handles the synthetic log entries.
    assert ctypes.CDLL(None).prctl(15, b'sshd', 0, 0, 0) == 0
    syslog.openlog('sshd', syslog.LOG_PID, syslog.LOG_AUTHPRIV)
    for addresses in [('198.51.100.11',) * 3, ('192.0.2.11', '192.0.2.12', '192.0.2.13')]:
        first = addresses[0]
        for address in set(addresses):
            run('fail2ban-client', 'set', 'sshd-subnet', 'unbanip', address)
        assert run(HELPER, 'forget', first).returncode == 0
        try:
            for number, address in enumerate(addresses, 1):
                syslog.syslog(syslog.LOG_WARNING,
                              'Failed password for invalid user fail2ban-policy-test '
                              f'from {address} port 45678 ssh2')
                time.sleep(2)
                banned = run('ipset', 'test', 'Blacklist', first).returncode == 0
                print(json.dumps({'attempt': number, 'address': address,
                                  'prefix_blocked': banned}), flush=True)
                assert banned == (number == 3), 'Unexpected subnet ban threshold'
            state = json.loads(pathlib.Path('/var/lib/fail2ban/ssh-subnet-attempts.json').read_text())
            assert state, 'Missing persisted attempt counter'
            print('TEST_PASSED', addresses, flush=True)
        finally:
            for address in set(addresses):
                run('fail2ban-client', 'set', 'sshd-subnet', 'unbanip', address)
            assert run(HELPER, 'forget', first).returncode == 0
            assert run('ipset', 'test', 'Blacklist', first).returncode != 0
    print('STATUS', run('fail2ban-client', 'status', 'sshd-subnet').stdout)


if __name__ == '__main__':
    verify()
