# Container service installation

`install_services.yaml` is the single entry point for Docker services:

```shell
ansible-playbook -i inventory/vds5 install_services.yaml
ansible-playbook -i inventory/vds6 install_services.yaml --tags services
ansible-playbook -i inventory/vds6 install_services.yaml \
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

The Zabbix proxy uses the unmodified official image. Checks that must execute
on the Docker host are exposed through Zabbix Agent 2 user parameters instead
of being mounted into the proxy container.
Its hexadecimal PSK is read from the Vault variable `zabbix_proxy_psk`; the
role writes the bind-mounted PSK file and recreates the container when it
changes.

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
