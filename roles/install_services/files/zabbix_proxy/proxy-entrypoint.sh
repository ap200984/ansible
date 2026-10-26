#!/bin/bash
set -euo pipefail

# Keep the official proxy entrypoint responsible for Zabbix configuration.
python3 /usr/local/libexec/deye_cloud_proxy.py &
cloud_pid=$!
/usr/bin/docker-entrypoint.sh "$@" &
proxy_pid=$!

stop_children() {
    trap - TERM INT
    kill -TERM "$proxy_pid" "$cloud_pid" 2>/dev/null || true
    wait "$proxy_pid" "$cloud_pid" 2>/dev/null || true
}
trap stop_children EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

# Exit if either service stops, so Docker's restart policy restores both.
set +e
wait -n "$proxy_pid" "$cloud_pid"
status=$?
set -e
if [ "$status" -eq 0 ]; then
    status=1
fi
exit "$status"
