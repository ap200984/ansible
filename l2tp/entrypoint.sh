#!/bin/bash
echo "Starting xl2tpd..."
service xl2tpd start

echo "L2TP server is running. Tailing system logs..."
tail -F /var/log/messages /var/log/syslog 2>/dev/null
