ARG ZABBIX_PROXY_BASE_IMAGE=zabbix/zabbix-proxy-sqlite3:ubuntu-7.4-latest
FROM ${ZABBIX_PROXY_BASE_IMAGE}

USER root

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*

COPY deye_modbus_metrics.py /usr/lib/zabbix/externalscripts/deye_modbus_metrics.py
COPY deye_cloud_proxy.py /usr/local/libexec/deye_cloud_proxy.py
COPY proxy-entrypoint.sh /usr/local/bin/deye-proxy-entrypoint
RUN chmod 0755 /usr/lib/zabbix/externalscripts/deye_modbus_metrics.py \
    /usr/local/libexec/deye_cloud_proxy.py /usr/local/bin/deye-proxy-entrypoint \
    && mkdir -p /var/lib/zabbix/deye-cloud-cache \
    && chown 1997:1995 /var/lib/zabbix/deye-cloud-cache \
    && chmod 0700 /var/lib/zabbix/deye-cloud-cache

USER 1997
RUN /usr/lib/zabbix/externalscripts/deye_modbus_metrics.py --help > /dev/null \
    && /usr/local/libexec/deye_cloud_proxy.py --help > /dev/null

ENTRYPOINT ["/usr/local/bin/deye-proxy-entrypoint"]
CMD ["/usr/sbin/zabbix_proxy", "--foreground", "-c", "/etc/zabbix/zabbix_proxy.conf"]
