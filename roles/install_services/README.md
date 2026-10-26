# Container service installation

`02_deploy_services.yaml` is the single entry point for Docker services:

```shell
ansible-playbook -i inventory/vds5 02_deploy_services.yaml
ansible-playbook -i inventory/vds6 02_deploy_services.yaml --tags services
ansible-playbook -i inventory/vds6 02_deploy_services.yaml \
  -e socks5_proxy_password=''
```

Install or update only one selected service by using either its short tag or
its namespaced tag:

```shell
ansible-playbook -i inventory/k16_k112_server 02_deploy_services.yaml \
  --tags owncloud
ansible-playbook -i inventory/k16_k112_server 02_deploy_services.yaml \
  --tags services:owncloud
```

The `services` tag continues to install or update every service selected for
the host.

Hosts that need containers select their desired services with
`service_containers` in `host_vars/<inventory_hostname>.yml`. The role defaults
to an empty list, so hosts without container services need no host-vars file or
empty override. Container definitions and defaults live in
`defaults/main.yaml`; per-service preparation and post-install work lives in
small task files under `tasks/`.

The order in `service_containers` is significant for dependent services. For
example, PostgreSQL must precede the Zabbix backend and frontend, and Certbot
must precede NGINX.

NGINX can proxy arbitrary HTTP services with `nginx_upstreams` in host vars.
Each item maps one name to one `host:port`; the name becomes a subdomain of
`domain`:

```yaml
nginx_upstreams:
  - kibana: 10.9.0.90:5601
  - elasticsearch: 10.9.0.90:9200
  - some_other_web_service: 10.0.0.20:8080
```

This creates `kibana.<domain>`, `elasticsearch.<domain>`, and
`some-other-web-service.<domain>`. HTTP requests are redirected to HTTPS by
the common wildcard server, and the existing wildcard certificate is used.

Certbot bootstraps a wildcard certificate only when one is not already present.
It requires `domain` in host vars and the existing Vault-backed Reg.ru and
Let's Encrypt secret files.

After a successful renewal, Certbot touches
`/etc/letsencrypt/.nginx-reload`. NGINX watches that marker through the shared
read-only certificate volume and reloads itself within one minute. This does
not require host cron, the Docker socket, or privileged container access.

The Zabbix proxy uses a custom image built from the official Ubuntu 7.4 SQLite
proxy image. The Dockerfile and Deye Modbus TCP external check live in
`files/zabbix_proxy/`. Python is installed inside the image; the checks use only
the standard library. A small supervisor starts the upstream Zabbix entrypoint
and a local Deye Cloud helper, both as the Zabbix user (UID 1997).

`prepare_zabbix_proxy.yaml` builds the image on each selected Docker host before
starting its proxy. It stages only the Dockerfile, scripts, and entrypoint in a temporary
directory, then removes that directory even if the build fails. Each run checks
for base-image updates and uses Docker's build cache; a changed image recreates
the proxy. The locally built image is never pulled from a registry. Override
`zabbix_proxy_base_image`, `zabbix_proxy_image`, or `zabbix_proxy_build_pull`
in inventory if needed. Build operations are skipped in Ansible check mode.

The proxy's hexadecimal PSK is read from the Vault variable `zabbix_proxy_psk`;
the role writes the bind-mounted PSK file and recreates the container when it
changes. Secrets are never part of the image build context.

The four Deye Cloud variables `deye_cloud_login`, `deye_cloud_password`,
`deye_cloud_app_id`, and `deye_cloud_app_secret` are encrypted in
`group_vars/all/deye_cloud.yml`. Ansible installs a UID-1997-readable, mode-0400
JSON file and mounts it read-only at `/var/lib/zabbix/enc/deye-cloud.json`.
Changing credentials recreates the proxy to refresh the mounted file.

The local cloud helper listens only on `127.0.0.1:8766` inside the proxy container;
that port is not published on the host. The cloud HTTP master item passes its
API URL, device serial, and optional application macro overrides to this helper.
The helper obtains a token with the Vault-backed account credentials, hashes
the password with SHA-256 as required by Deye, and returns the unchanged
`/device/latest` response to the existing dependent items. It caches tokens in
the private `zabbix-proxy-deye-cloud-cache` Docker volume and renews them on the
first cloud poll after 24 hours, before earlier expiration, or after an
authentication rejection. No cloud account credentials are baked into the image.

Deploy the proxy image and migrate the three existing proxy hosts with:

```shell
ansible-playbook -i inventory/vds1 -i inventory/vds8 \
  -i inventory/k16_k112_server 02_deploy_services.yaml --tags zabbix_proxy
```

After the proxy starts, the role removes the old host-side `deya_solar.py`,
`deya_solar.conf` UserParameter, and `AllowKey=deye.inverter.get[*]`. A running
Zabbix Agent 2 is restarted only when its configuration changes. The agent role
also performs this cleanup on subsequent runs. Shared host Python packages are
left installed; no Deye dependencies are installed on hosts anymore.

Configure each inverter host in Zabbix to be monitored by the appropriate
proxy, then change its master item to:

- Type: **External check**
- Key: `deye_modbus_metrics.py["{$DEYE.HOST}","{$DEYE.PORT}","{$DEYE.UNIT}"]`
- Type of information: **Text**
- Update interval: `15s` (one read feeds all direct dependent items)
- Timeout: `15s` in the item's flexible timeout settings

Set `{$DEYE.HOST}` to the inverter's Modbus TCP address reachable from the proxy
container, `{$DEYE.PORT}` to `502`, and `{$DEYE.UNIT}` to `1` unless the device
uses different values. This check targets the SUN-8K-SG01LP1-EU / SG01LP1
single-phase register map from the reference script. It sends only Modbus FC03
reads in three blocks. It requires a Modbus TCP endpoint; a Solarman logger's
TCP 8899 endpoint and serial-number argument are not interchangeable.

The JSON has `timestamp`, `source`, `unit_id`, `metrics`, and `units` fields.
Update dependent-item JSONPath preprocessing to the new metric names, for
example:

| Measurement | JSONPath |
| --- | --- |
| Battery charge | `$.metrics.SOC` |
| Battery voltage | `$.metrics.BatteryVoltage` |
| Battery power | `$.metrics.BatteryPower` |
| PV power | `$.metrics.TotalDCInputPower` |
| Daily PV generation | `$.metrics.PVDailyPowerGenerationActive` |
| Grid power | `$.metrics.TotalGridPower` |
| Load power | `$.metrics.TotalConsumptionPower` |
| Battery temperature | `$.metrics['Temperature- Battery']` |

The updated importable template in `zabbix/templates/deye_hybrid.yaml` keeps the
existing cloud items and adds the direct master and dependent items. It retains
the cloud dashboard and changes the old solar overview to **Direct overview**.
The former agent item `deye.inverter.get[...]` and its grouped JSONPaths
(`$.battery.*`, `$.pv.*`, etc.) are superseded by these direct items. See the
[Zabbix external-check documentation](https://www.zabbix.com/documentation/7.4/en/manual/config/items/itemtypes/external)
for item configuration.

Deploy the new proxy image before importing the template. Import through the
Zabbix UI with **Update existing** and **Create new** enabled and **Delete missing**
disabled. See `zabbix/README.md` for details.

Inspect a reading inside the running image:

```shell
docker exec zabbix-proxy /usr/lib/zabbix/externalscripts/deye_modbus_metrics.py \
  10.10.0.196 502 1 --pretty
```

Named arguments (`--host`, `--port`, `--unit`, `--timeout`), `--raw`, and
`--from-dump FILE` are also available for troubleshooting and offline replay.

Ejabberd accounts are configured with the Vault-backed `ejabberd_users` list.
Each list item maps one username to its password:

```yaml
ejabberd_users:
  - admin: "password-for-admin"
  - user1: "password-for-user1"
  - user2: "password-for-user2"
```

Every account is registered on both `localhost` and `ejabberd.<domain>`.
Existing accounts are left unchanged; only missing accounts are registered.

VDS hosts select `https_proxy` to run a TLS-encrypted authenticated forward
proxy with HTTPS CONNECT support on TCP 1981. Configure `https_proxy_port`,
`https_proxy_users`, and `https_proxy_tls_certificate_file` in host vars;
passwords reference the SOCKS5 Vault secret. Clients use `https://<host>:1981`
and FoxyProxy type **HTTPS**. Plain HTTP proxy connections are rejected.

The shared server certificate in `certificates/vds-proxy-server.crt` includes
all six public IP addresses in its SAN and expires on 2036-10-11. Its private
key (`https_proxy_tls_private_key`) and the private CA key
(`https_proxy_ca_private_key`) are encrypted in
`group_vars/all/https_proxy_tls.yml`. Only the server key is deployed to hosts,
as `/opt/https-proxy/server.key` with mode 0600.

Import the public `certificates/vds-proxy-ca.crt` in Firefox under
Settings → Privacy & Security → Certificates → View Certificates → Authorities,
and enable trust for identifying websites. The CA expires on 2036-10-11.
CA SHA-256 fingerprint:
`D0:33:EC:4B:FD:13:53:7A:C6:63:55:AA:96:C3:24:B1:0F:32:E7:04:DA:3B:E7:45:FC:49:8E:5C:B0:E5:C2:7B`.

Both certificates have a 10-year validity and retain their existing private
keys in Vault. Import the renewed CA certificate in clients to update its
expiry date. The server certificate identifies the proxy and secures the
client-to-proxy connection; browsers need the CA certificate instead.
HTTPS CONNECT preserves the destination website's own TLS certificate;
this configuration does not intercept website TLS.

Certificate changes or Vault key changes recreate the container automatically.

```shell
ansible-playbook -i inventory/vds1 -i inventory/vds2 -i inventory/vds3 \
  -i inventory/vds5 -i inventory/vds6 -i inventory/vds8 \
  02_deploy_services.yaml --tags https_proxy
```

Vds1 and vds8 use explicit `https_proxy_dns_servers` for upstream DNS. Vds3 is private at `10.9.0.120`; public access additionally
requires an edge-router forwarding rule from `86.110.170.70:1981` to
`10.9.0.120:1981`. The approved rule is managed by the proxy post task using
the `https_proxy_nat_*` host variables.

VDS3 permits authenticated HTTP access on port 1955 and HTTPS CONNECT on
port 1956 for all IPv4 destinations. Exceptions are declared in
`host_vars/vds3.yml` as `https_proxy_destination_exceptions`:

```yaml
https_proxy_destination_exceptions:
  - address: 0.0.0.0/0
    http_ports: [1955]
    https_ports: [1956]
```

These authenticated exceptions precede Squid's normal port restrictions.
Ports 80/443 retain their standard handling; other nonstandard ports remain
blocked. The IPv4 exception does not include IPv6 destinations.
