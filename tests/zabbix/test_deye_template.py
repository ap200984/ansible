"""Validate the portable import artifact without connecting to Zabbix or an inverter."""

import fnmatch
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import unittest
import uuid

import yaml


ROOT = Path(__file__).resolve().parents[2]
TEMPLATE_PATH = ROOT / "zabbix/templates/deye_hybrid.yaml"
DIRECT_MASTER_KEY = 'deye_modbus_metrics.py["{$DEYE.HOST}","{$DEYE.PORT}","{$DEYE.UNIT}"]'
CLOUD_DASHBOARD_UUID = "7c0b55b37a3740baab770aea47e5408f"
DIRECT_DASHBOARD_UUID = "c3f1053b52e2487897318ab462f4d9b3"

# Frozen from the supplied export. The fingerprint covers all fields of every
# original cloud dependent, including order, units, preprocessing, and UUIDs.
ORIGINAL_CLOUD_UUIDS = {'deye.cloud.raw': 'ac7894aa543a42f3a00e7d7995e78d0b',
 'deye.metric[ACCurrentRUA]': 'da0f469adb194c30bdb5d805689a8fd7',
 'deye.metric[ACOutputFrequencyR]': 'cb1bf64f7d0e4cc1b8691ee5f65034d8',
 'deye.metric[AC Temperature]': '1464987931c342b5a1ecddb188eef7d3',
 'deye.metric[ACVoltageRUA]': '1c52c06c34f549f8b85c744977f85814',
 'deye.metric[BatteryCurrent]': 'e7159881ed044cb49925d6c5bb43e700',
 'deye.metric[BatteryPower]': 'b213cf4dcf174f8b9908b160ad15c920',
 'deye.metric[BatteryRatedCapacity]': '61f35521b4c84f16861bf4f12e0a0c5d',
 'deye.metric[BatteryVoltage]': '8d0b5d0ea1cb4454b1e8471458d8053a',
 'deye.metric[CumulativeConsumption]': '1c168d48ba544c5aaf1a9bd298b94108',
 'deye.metric[CumulativeEnergyPurchased]': '3e3502667b204a5da088206c3f1a0bc3',
 'deye.metric[CumulativeGridFeedIn]': '33c5395c8bd545c7b1faa993d0d77b40',
 'deye.metric[DailyActiveProduction]': '27da96fb041245afa583f3ef3be275f6',
 'deye.metric[DailyChargingEnergy]': '016690a8c2884847b25e512c875b5681',
 'deye.metric[DailyConsumption]': 'a3fd3f6d057246ce9a0d2af963501a18',
 'deye.metric[DailyDischargingEnergy]': '26bf8c7b44964ba8b59590e3f9ed81a8',
 'deye.metric[DailyEnergyPurchased]': 'af0e543b511c44008ef8ff5cd2db5334',
 'deye.metric[DailyGridFeedIn]': 'bc149520641b40489514ca6782f160fd',
 'deye.metric[DailyProductionGenerator]': '59270e6cf7794d9191fe2dd72a81ab48',
 'deye.metric[DCCurrentPV1]': 'd4ae924504e0439cb3481833944fe8a8',
 'deye.metric[DCCurrentPV2]': '2c82b4161119415b83cecadc26df49ef',
 'deye.metric[DCCurrentPV3]': '3803d0856c2c487e8ebc073ac0857060',
 'deye.metric[DCPowerPV1]': '0290d88c7bf24e7d95dcc9a83432a3ca',
 'deye.metric[DCPowerPV2]': 'e8eb6882c18b4aefbdbfe21b54e5b4f7',
 'deye.metric[DCPowerPV3]': '5783d2d7717343a8ab8e8031d7ac7634',
 'deye.metric[DC Temperature]': '7381cfe5d6124636867d48446d4eef2e',
 'deye.metric[DCVoltagePV1]': '7f67080920e843918e7c567c7cdc0af2',
 'deye.metric[DCVoltagePV2]': '1807eaabdb5d4168830ff0e89f9b0695',
 'deye.metric[DCVoltagePV3]': '622149b71d1e4f46b79fd63ac6da18f1',
 'deye.metric[ExternalCTPowerL1L2]': '2f88b52b55294d918260e9e03b6a9613',
 'deye.metric[GenDailyRunTime]': 'ecf04e0c224f49668a88e7d798a6ba18',
 'deye.metric[GeneratorFrequency]': '33ea3aa5e7c44e6f8ac2e2db5302137a',
 'deye.metric[GenVoltage]': '5de8b12bcf5f41208c68a0b543ae698b',
 'deye.metric[GridCurrentL1L2]': '5195571c21e9476fa5126f2db30d46a1',
 'deye.metric[GridFrequency]': '2eb6e79fbb544196aa6d86548e1e17be',
 'deye.metric[GridTotalReactivePower]': '8718081757ad47e8921d756577b41072',
 'deye.metric[GridVoltageL1L2]': 'a0b43a9deadf4aa08dfeeb2d9fce6196',
 'deye.metric[HMI]': 'eaf68f2d69d146458a0af3584d6be905',
 'deye.metric[InverterOutputPowerL1L2]': '61a3e3060c9f45b382100679440e036a',
 'deye.metric[InverterTotalReactivePower]': 'ee05cd62f87f4393a2024cdfd70cc069',
 'deye.metric[LithiumBatteryVersionNumber]': 'b326a4b54d7243288eb46be63361d386',
 'deye.metric[LoadVoltageL1L2]': 'f72ee22d09b14453a85f7c003298b9f4',
 'deye.metric[MAIN]': '2fbd70b3fa7543aaa52b244c36f890e8',
 'deye.metric[PowerFactor]': '16f1a628403b419baaa5ce3f92cccb61',
 'deye.metric[ProtocolVersion]': '35ceca7b01264c379a93f3e585b86475',
 'deye.metric[PVCumulativePowerGenerationActive]': '0ec9e0928082454b8ec73cc611fb0a9c',
 'deye.metric[PVDailyPowerGenerationActive]': 'b3c44747d4034a20900b307990192a49',
 'deye.metric[RatedPower]': 'c5ff373f05104dd2ace92f418ec1d4bc',
 'deye.metric[SOC]': 'eef85df344214271a15a14e11348bfc9',
 'deye.metric[SOC_empty]': '64720515f662497c9b77af229ef15d64',
 'deye.metric[Temperature- Battery]': '805ac51edd6e455da8b64feeea441ae9',
 'deye.metric[TotalActiveProduction]': 'ba910f8237054df8b6dbc9835eea35c3',
 'deye.metric[TotalChargeEnergy]': 'fe27f60b837e4062859b1f282cdcee92',
 'deye.metric[TotalConsumptionPower]': '37476b776dfd48d2a95fa946dd31c283',
 'deye.metric[TotalDCInputPower]': 'd5aa21efb2e04873b28144a3d026ca50',
 'deye.metric[TotalDischargeEnergy]': '0a0b890c9f4c4885bae616e0da6a16d9',
 'deye.metric[TotalGenPower]': 'c5bac182f6f34e80906e97e2e5e0ceb6',
 'deye.metric[TotalGridPower]': '65a118a7118248a190c4b7f026b40528',
 'deye.metric[TotalProductionGenerator]': 'fbe78410fe7c4ff08dd3cdd7c6421dc0',
 'deye.metric[UPSLoadPower]': '8f06ade560c943cfa8b487059c1306dc'}
ORIGINAL_DEPENDENT_SHA256 = "ab43f9939e8bdde00d91f4da09526fade72becdde6ce2d51ec9420f6c71f22ac"


def widget_selectors(dashboard):
    for page in dashboard["pages"]:
        for widget in page["widgets"]:
            for field in widget.get("fields", []):
                if re.fullmatch(r"ds\.\d+\.items\.\d+", field["name"]):
                    yield widget, field["value"]


class DeyeTemplateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.export = yaml.safe_load(TEMPLATE_PATH.read_text())["zabbix_export"]
        cls.template = cls.export["templates"][0]
        cls.items = cls.template["items"]
        cls.by_key = {item["key"]: item for item in cls.items}
        cls.macros = {macro["macro"]: macro for macro in cls.template["macros"]}
        cls.dashboards = {dashboard["uuid"]: dashboard for dashboard in cls.template["dashboards"]}
        spec = importlib.util.spec_from_file_location(
            "deye_template_script", ROOT / "roles/install_services/files/zabbix_proxy/deye_modbus_metrics.py")
        cls.deye = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.deye)

    def test_import_identity_and_all_original_cloud_item_identities_are_preserved(self):
        self.assertEqual(self.export["version"], "7.4")
        self.assertEqual(self.template["uuid"], "34408a93158b41fab58f8cc5fe1e55a1")
        self.assertEqual(self.template["template"], "t_Deye_API_invertor")
        self.assertEqual(len(ORIGINAL_CLOUD_UUIDS), 60)
        for key, expected_uuid in ORIGINAL_CLOUD_UUIDS.items():
            with self.subTest(key=key):
                self.assertEqual(self.by_key[key]["uuid"], expected_uuid)
        self.assertEqual(len(self.items), len(self.by_key), "Item keys must be unique")
        self.assertEqual(len(self.items), len({item["uuid"] for item in self.items}))

    def test_every_original_cloud_dependent_definition_is_unchanged(self):
        dependents = [self.by_key[key] for key in ORIGINAL_CLOUD_UUIDS if key != "deye.cloud.raw"]
        fingerprint = hashlib.sha256(json.dumps(
            dependents, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        self.assertEqual(fingerprint, ORIGINAL_DEPENDENT_SHA256)

    def test_cloud_master_uses_token_refresh_helper_without_authorization_header(self):
        master = self.by_key["deye.cloud.raw"]
        self.assertEqual(master["type"], "HTTP_AGENT")
        self.assertEqual(master["value_type"], "TEXT")
        self.assertEqual(master["url"], "{$DEYE.PROXY.API.URL}/device/latest")
        self.assertEqual(master["timeout"], "45s")
        self.assertEqual(master["request_method"], "POST")
        self.assertEqual(master["post_type"], "JSON")
        self.assertEqual(json.loads(master["posts"]), {
            "api_url": "{$DEYE.API.URL}", "app_id": "{$DEYE.APP.ID}",
            "app_secret": "{$DEYE.APP.SECRET}", "deviceList": ["{$DEYE.DEVICE.SN}"],
        })
        headers = {header["name"].lower(): header["value"] for header in master["headers"]}
        self.assertNotIn("authorization", headers)
        self.assertEqual(headers["content-type"], "application/json")

    def test_connection_macros_and_credential_fallback_defaults(self):
        for name, value in (("HOST", "10.10.0.196"), ("PORT", "502"), ("UNIT", "1"),
                            ("PROXY.API.URL", "http://127.0.0.1:8766")):
            self.assertEqual(self.macros["{$DEYE." + name + "}"]["value"], value)
        for name in ("APP.ID", "APP.SECRET", "TOKEN"):
            with self.subTest(macro=name):
                macro = self.macros["{$DEYE." + name + "}"]
                self.assertEqual(macro["value"], "")
                self.assertTrue(macro["description"])
        for name in ("APP.ID", "APP.SECRET"):
            self.assertIn("Empty uses the proxy Vault", self.macros["{$DEYE." + name + "}"]["description"])
        self.assertEqual(self.macros["{$DEYE.APP.SECRET}"]["type"], "SECRET_TEXT")
        self.assertEqual(self.macros["{$DEYE.TOKEN}"]["type"], "SECRET_TEXT")
        self.assertIn("Unused", self.macros["{$DEYE.TOKEN}"]["description"])

    def test_direct_master_polls_every_15_seconds(self):
        master = self.by_key[DIRECT_MASTER_KEY]
        self.assertEqual(master["type"], "EXTERNAL")
        self.assertEqual(master["delay"], "15s")
        self.assertEqual(master["timeout"], "15s")
        self.assertEqual(master["value_type"], "TEXT")

    def test_direct_dependents_cover_every_decoded_metric_with_exact_jsonpaths(self):
        registers = {address: 0 for start, count in self.deye.READ_BLOCKS
                     for address in range(start, start + count)}
        metrics, units = self.deye.decode(registers)
        expected_keys = {f"deye.direct.metric[{metric}]" for metric in metrics}
        direct_keys = {key for key in self.by_key if key.startswith("deye.direct.metric[")}
        self.assertEqual(direct_keys, expected_keys | {"deye.direct.metric[SOC_empty]"})
        for metric in metrics:
            with self.subTest(metric=metric):
                item = self.by_key[f"deye.direct.metric[{metric}]"]
                self.assertEqual(item["type"], "DEPENDENT")
                self.assertEqual(item["master_item"], {"key": DIRECT_MASTER_KEY})
                self.assertEqual(item["preprocessing"], [
                    {"type": "JSONPATH", "parameters": [f'$.metrics["{metric}"]']},
                ])
                self.assertEqual(item["units"] if "units" in item else None, units.get(metric))
                self.assertEqual(item["value_type"], "FLOAT")

    def test_derived_empty_battery_capacity_preserves_pie_semantics(self):
        item = self.by_key["deye.direct.metric[SOC_empty]"]
        self.assertEqual(item["master_item"], {"key": DIRECT_MASTER_KEY})
        self.assertEqual(item["units"], "%")
        self.assertEqual(item["preprocessing"], [
            {"type": "JSONPATH", "parameters": ['$.metrics["SOC"]']},
            {"type": "JAVASCRIPT", "parameters": ['return Math.max(0, 100 - Number(value));']},
        ])
        self.assertEqual(item["value_type"], "FLOAT")

    def test_all_exported_uuids_are_valid_unique_uuid4(self):
        identifiers = []

        def collect(value):
            if isinstance(value, dict):
                for key, child in value.items():
                    if key == "uuid":
                        identifiers.append(child)
                    else:
                        collect(child)
            elif isinstance(value, list):
                for child in value:
                    collect(child)

        collect(self.export)
        self.assertEqual(len(identifiers), len(set(identifiers)))
        for identifier in identifiers:
            with self.subTest(uuid=identifier):
                self.assertRegex(identifier, r"^[0-9a-f]{32}$")
                self.assertEqual(uuid.UUID(identifier).version, 4)

    def test_new_item_uuids_and_all_masters_exist(self):
        for item in self.items:
            with self.subTest(key=item["key"]):
                if item["key"] not in ORIGINAL_CLOUD_UUIDS:
                    self.assertEqual(uuid.UUID(item["uuid"]).version, 4)
                if item.get("type") == "DEPENDENT":
                    self.assertIn(item["master_item"]["key"], self.by_key)

    def test_both_dashboards_keep_their_identity_and_all_selectors_resolve_to_their_source(self):
        self.assertEqual(set(self.dashboards), {CLOUD_DASHBOARD_UUID, DIRECT_DASHBOARD_UUID})
        self.assertEqual(self.dashboards[DIRECT_DASHBOARD_UUID]["name"], "Direct overview")
        self.assertEqual(self.dashboards[CLOUD_DASHBOARD_UUID]["name"], "Deye Cloud — metrics by dimension")
        for dashboard_uuid, dashboard in self.dashboards.items():
            selectors = list(widget_selectors(dashboard))
            self.assertTrue(selectors)
            expected_direct = dashboard_uuid == DIRECT_DASHBOARD_UUID
            for widget, pattern in selectors:
                with self.subTest(dashboard=dashboard["name"], widget=widget["name"], pattern=pattern):
                    matching = [item for item in self.items if fnmatch.fnmatchcase(item["name"], pattern)]
                    self.assertEqual(len(matching), 1, "Selectors must match exactly one existing item")
                    key = matching[0]["key"]
                    self.assertEqual(key.startswith("deye.direct.metric["), expected_direct)
                    if not expected_direct:
                        self.assertIn(key, ORIGINAL_CLOUD_UUIDS)

    def test_direct_overview_keeps_widgets_refreshes_and_scales_grid_voltage(self):
        dashboard = self.dashboards[DIRECT_DASHBOARD_UUID]
        widgets = [widget for page in dashboard["pages"] for widget in page["widgets"]]
        self.assertEqual(len(widgets), 9)
        for widget in widgets:
            fields = {field["name"]: field for field in widget.get("fields", [])}
            # Zabbix 7.4 supports 10s and 30s widget refresh; 15s is not an option.
            self.assertEqual(fields["rf_rate"], {"type": "INTEGER", "name": "rf_rate", "value": "10"})
        grid_widget = next(widget for widget in widgets if widget["name"] == "Grid voltage (V)")
        self.assertEqual([pattern for widget, pattern in widget_selectors(dashboard) if widget is grid_widget],
                         ["Deye Direct: GridVoltageL1L2"])
        self.assertEqual(self.by_key["deye.direct.metric[GridVoltageL1L2]"]["units"], "V")


if __name__ == "__main__":
    unittest.main()
