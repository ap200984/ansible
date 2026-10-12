import importlib.util
from pathlib import Path
import unittest
spec = importlib.util.spec_from_file_location('reset', Path(__file__).parents[1] / 'files/reset-old-google.py')
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)

class TargetedResetTests(unittest.TestCase):
    def test_only_stale_google_sessions_are_selected(self):
        connections = [
            {'.id':'*A','dst-address':'8.8.8.8:443','reply-dst-address':'86.110.170.70:40000'},
            {'.id':'*B','dst-address':'8.8.8.8:443','reply-dst-address':'10.250.4.1:40001'},
            {'.id':'*C','dst-address':'1.1.1.1:443','reply-dst-address':'86.110.170.70:40002'},
            {'.id':'*D','dst-address':'10.255.0.6:22','reply-dst-address':'10.255.0.112:40003'},
        ]
        self.assertEqual(helper.stale_connections([{'address':'8.8.8.0/24'}],connections,'10.250.4.1'), ['*A'])

    def test_untrusted_identifier_cannot_be_executed(self):
        with self.assertRaises(ValueError):
            helper.stale_connections([{'address':'8.8.8.0/24'}],[{'.id':'*A; /system reboot','dst-address':'8.8.8.8:443','reply-dst-address':'1.2.3.4'}],'10.250.4.1')

    def test_dns_names_are_skipped_but_dynamic_addresses_are_selected(self):
        entries = [{'address':'chatgpt.com'}, {'address':'192.0.2.10'}, {'address':'2001:db8::1'}]
        connections = [{'.id':'*E','dst-address':'192.0.2.10:443','reply-dst-address':'1.2.3.4'}]
        self.assertEqual(helper.stale_connections(entries,connections,'10.250.4.1'), ['*E'])

    def test_missing_nat_details_prevents_reset(self):
        with self.assertRaises(ValueError):
            helper.stale_connections([{'address':'8.8.8.0/24'}],[{'.id':'*A','dst-address':'8.8.8.8:443','srcnat':True}],'10.250.4.1')
