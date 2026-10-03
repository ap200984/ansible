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
