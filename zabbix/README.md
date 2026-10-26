# Deye cloud and direct monitoring

`templates/deye_hybrid.yaml` updates `t_Deye_API_invertor` while retaining its
existing item UUIDs and keys. Cloud dependent items continue to consume
`deye.cloud.raw`. The direct master polls the inverter every 15 seconds, and
dependent items extract every decoded parameter without additional network
requests. The two template dashboards are:

- **Deye Cloud — metrics by dimension**: the existing cloud items.
- **Direct overview**: direct Modbus readings; it retains the old overview
  dashboard UUID, so an update changes the existing dashboard.

Direct data is polled every 15 seconds. Overview widgets use Zabbix 7.4's
supported 10-second refresh interval so new readings appear promptly.

The direct check supports the SG01LP1 single-phase register map in the reference
script. It does not invent direct values for cloud-only fields such as third PV
inputs or firmware versions. Those existing cloud items are preserved.

The cloud master calls the helper inside the monitoring proxy. The helper uses
the template's `{$DEYE.API.URL}` and `{$DEYE.DEVICE.SN}` macros and the encrypted
Deye credentials in `group_vars/all/deye_cloud.yml`. `{$DEYE.APP.ID}` and
`{$DEYE.APP.SECRET}` may override the Vault application defaults; leave them empty
to use the mounted Vault credentials. The old `{$DEYE.TOKEN}` macro is retained
but no longer used by the updated master. Its value is omitted from this export.

Tokens are refreshed on the first cloud poll after 24 hours, sooner if the
provider's expiry is earlier, and once after an authentication rejection. The
cloud JSON payload and dependent JSONPaths remain unchanged. The helper uses
[Deye's documented token request](https://github.com/DeyeCloudDevelopers/deye-openapi-client-sample-code/blob/master/clientcode/account/obtain_token.py).

Deploy the proxy image first:

```shell
ansible-playbook -i inventory/vds1 -i inventory/vds8 \
  -i inventory/k16_k112_server 02_deploy_services.yaml --tags zabbix_proxy
```

To import through the Zabbix UI, upload `templates/deye_hybrid.yaml`, select **Update existing**
and **Create new**, and leave **Delete missing** unchecked for items and
dashboards. Existing item UUIDs and keys are retained to preserve history.

Each inverter host must use a proxy running the custom image. Configure its
`{$DEYE.HOST}` address, `{$DEYE.PORT}` (default `502`), and `{$DEYE.UNIT}` (default
`1`) as host macros. The direct address must expose Modbus TCP and be reachable
from the proxy container. It is independent of the Deye Cloud device serial.
The template's reference address is `10.10.0.196`; override it for other devices.

Validate locally without an inverter or Deye account:

```shell
python3 -m unittest discover -s roles/install_services/tests -v
python3 -m unittest discover -s tests/zabbix -v
```
