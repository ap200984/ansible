ARG ZABBIX_PROXY_BASE_IMAGE=zabbix/zabbix-proxy-sqlite3:ubuntu-7.4-latest
FROM ${ZABBIX_PROXY_BASE_IMAGE}

USER root

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*

COPY deye_modbus_metrics.py /usr/lib/zabbix/externalscripts/deye_modbus_metrics.py
RUN chmod 0755 /usr/lib/zabbix/externalscripts/deye_modbus_metrics.py

USER 1997
RUN /usr/lib/zabbix/externalscripts/deye_modbus_metrics.py --help > /dev/null
