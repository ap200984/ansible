"""Local token lifecycle and HTTP-contract checks; no cloud credentials are used."""

from concurrent.futures import ThreadPoolExecutor
import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import stat
import tempfile
import unittest
from unittest import mock
from urllib import error, request


SCRIPT = Path(__file__).parents[1] / "files/zabbix_proxy/deye_cloud_proxy.py"
SPEC = importlib.util.spec_from_file_location("deye_cloud_proxy", SCRIPT)
cloud = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(cloud)
BASE = "https://eu1-developer.deyecloud.com/v1.0"
LATEST = {"success": True, "code": 1000000, "deviceDataList": [{"deviceSn": "test-sn"}]}


class CloudClientTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.credentials = self.root / "credentials.json"
        self.values = {"login": "example@example.invalid", "password": "test-private-password",
                       "app_id": "application-id", "app_secret": "test-private-app-secret"}
        self.credentials.write_text(json.dumps(self.values))
        self.now = 1000000
        self.calls = []
        self.lifetime = 200000
        self.client = cloud.CloudClient(self.credentials, self.root / "cache",
                                       self.transport, lambda: self.now)
        self.payload = {"api_url": BASE, "deviceList": ["test-sn"]}

    def transport(self, url, payload, token=None):
        self.calls.append((url, payload, token))
        if "/account/token?" in url:
            return {"accessToken": "Bearer test-token-%d" % self.auth_count(),
                    "expiresIn": str(self.lifetime)}
        return LATEST

    def auth_count(self):
        return sum("/account/token?" in call[0] for call in self.calls)

    def test_auth_hashes_password_and_uses_file_application_defaults(self):
        self.assertEqual(self.client.latest(self.payload), LATEST)
        url, payload, _ = self.calls[0]
        self.assertEqual(url, BASE + "/account/token?appId=application-id")
        self.assertEqual(payload, {"email": self.values["login"],
                                  "appSecret": self.values["app_secret"],
                                  "password": hashlib.sha256(self.values["password"].encode()).hexdigest()})
        self.assertEqual(self.calls[1], (BASE + "/device/latest",
                                        {"deviceList": ["test-sn"]}, "test-token-1"))

    def test_blank_app_macros_fall_back_and_nonempty_macros_override(self):
        self.client.latest(dict(self.payload, app_id="", app_secret=" "))
        self.assertIn("appId=application-id", self.calls[0][0])
        self.client.latest(dict(self.payload, app_id="different-id", app_secret="different-secret"))
        self.assertIn("appId=different-id", self.calls[2][0])
        self.assertEqual(self.calls[2][1]["appSecret"], "different-secret")
        self.assertEqual(self.auth_count(), 2)

    def test_token_persists_across_clients_and_refreshes_on_first_poll_after_a_day(self):
        self.client.latest(self.payload)
        self.now += cloud.MAX_TOKEN_AGE - 1
        second = cloud.CloudClient(self.credentials, self.root / "cache",
                                   self.transport, lambda: self.now)
        second.latest(self.payload)
        self.assertEqual(self.auth_count(), 1)
        self.now += 1
        second.latest(self.payload)
        self.assertEqual(self.auth_count(), 2)

    def test_expiry_shorter_than_a_day_is_respected(self):
        self.lifetime = 60
        self.client.latest(self.payload)
        self.now += 53
        self.client.latest(self.payload)
        self.assertEqual(self.auth_count(), 1)
        self.now += 1
        self.client.latest(self.payload)
        self.assertEqual(self.auth_count(), 2)

    def test_auth_failure_refreshes_once_and_retries_latest(self):
        original = self.transport

        def rejected_once(url, payload, token=None):
            result = original(url, payload, token)
            if "/device/latest" in url and token == "test-token-1":
                raise cloud.CloudError("Deye Cloud rejected the request.", auth=True)
            return result

        self.client.transport = rejected_once
        self.assertEqual(self.client.latest(self.payload), LATEST)
        self.assertEqual(self.auth_count(), 2)
        self.assertEqual(self.calls[-1][2], "test-token-2")

    def test_permanent_auth_failure_and_other_api_failures_propagate(self):
        original = self.transport

        def always_rejected(url, payload, token=None):
            result = original(url, payload, token)
            if "/device/latest" in url:
                raise cloud.CloudError("Deye Cloud rejected the request.", auth=True)
            return result

        self.client.transport = always_rejected
        with self.assertRaises(cloud.CloudError):
            self.client.latest(self.payload)
        self.assertEqual(self.auth_count(), 2)
        self.calls.clear()
        self.client.transport = mock.Mock(side_effect=cloud.CloudError("Upstream unavailable."))
        with self.assertRaisesRegex(cloud.CloudError, "Upstream unavailable"):
            self.client.latest(self.payload)
        self.assertEqual(self.client.transport.call_count, 1)

    def test_failed_daily_refresh_does_not_use_expired_token_or_return_old_metrics(self):
        self.client.latest(self.payload)
        self.now += cloud.MAX_TOKEN_AGE
        self.client.transport = mock.Mock(side_effect=cloud.CloudError("Authentication unavailable."))
        with self.assertRaisesRegex(cloud.CloudError, "Authentication unavailable"):
            self.client.latest(self.payload)
        self.assertIn("/account/token?", self.client.transport.call_args.args[0])
        self.assertEqual(self.client.transport.call_count, 1)

    def test_cache_is_private_and_contains_no_account_or_application_credentials(self):
        self.client.latest(self.payload)
        cache = self.root / "cache"
        self.assertEqual(stat.S_IMODE(cache.stat().st_mode), 0o700)
        files = list(cache.glob("*.json"))
        self.assertEqual(len(files), 1)
        self.assertEqual(stat.S_IMODE(files[0].stat().st_mode), 0o600)
        contents = files[0].read_text()
        for value in self.values.values():
            self.assertNotIn(value, contents)
            self.assertNotIn(value, files[0].name)
        self.assertEqual(set(json.loads(contents)), {"access_token", "issued_at", "expires_at"})

    def test_password_rotation_and_api_region_have_separate_cache_entries(self):
        self.client.latest(self.payload)
        self.values["password"] = "new-private-password"
        self.credentials.write_text(json.dumps(self.values))
        self.client.latest(self.payload)
        self.client.latest(dict(self.payload, api_url="https://us1-developer.deyecloud.com"))
        self.assertEqual(self.auth_count(), 3)

    def test_concurrent_polls_acquire_one_token(self):
        with ThreadPoolExecutor(max_workers=8) as executor:
            results = list(executor.map(lambda _index: self.client.latest(self.payload), range(16)))
        self.assertEqual(results, [LATEST] * 16)
        self.assertEqual(self.auth_count(), 1)

    def test_startup_is_lazy_but_requests_fail_cleanly_without_credentials(self):
        client = cloud.CloudClient(self.root / "missing-secret-file", self.root / "cache")
        with self.assertRaisesRegex(cloud.CloudError, "credentials are unavailable") as caught:
            client.latest(self.payload)
        self.assertEqual(caught.exception.status, 503)
        self.assertNotIn("missing-secret-file", str(caught.exception))

    def test_bad_cache_is_replaced_and_invalid_expiry_is_rejected(self):
        self.client.latest(self.payload)
        path = next((self.root / "cache").glob("*.json"))
        path.write_text("not-json")
        self.client.latest(self.payload)
        self.assertEqual(self.auth_count(), 2)
        self.now += cloud.MAX_TOKEN_AGE
        self.lifetime = float("nan")
        with self.assertRaisesRegex(cloud.CloudError, "invalid token expiry"):
            self.client.latest(self.payload)


class TransportTests(unittest.TestCase):
    def post(self, response):
        stream = mock.MagicMock()
        stream.__enter__.return_value.read.return_value = json.dumps(response).encode()
        opener = mock.Mock()
        opener.open.return_value = stream
        with mock.patch.object(cloud.request, "build_opener", return_value=opener):
            result = cloud.post_json(BASE + "/device/latest", {"deviceList": ["test-sn"]},
                                     token="Bearer Bearer abc")
        return result, opener

    def test_normalizes_bearer_prefix_and_validates_success_code(self):
        result, opener = self.post(LATEST)
        self.assertEqual(result, LATEST)
        req = opener.open.call_args.args[0]
        self.assertEqual(req.get_header("Authorization"), "Bearer abc")
        self.assertEqual(json.loads(req.data), {"deviceList": ["test-sn"]})
        self.assertIsNone(cloud.NoRedirects().redirect_request(None, None, 302, "", {}, "http://bad.invalid"))

    def test_business_errors_are_sanitized_and_token_errors_marked(self):
        for body, auth in (({"success": False, "code": 2101019, "msg": "secret leaked token invalid"}, True),
                           ({"success": True, "code": 2101025, "msg": "private password"}, False),
                           ({"success": False, "code": "private password", "msg": "private password"}, False)):
            with self.subTest(body=body):
                with self.assertRaises(cloud.CloudError) as caught:
                    self.post(body)
                self.assertEqual(caught.exception.auth, auth)
                self.assertNotIn("private password", str(caught.exception))
                self.assertNotIn("secret leaked", str(caught.exception))

    def test_http_errors_are_sanitized_and_401_or_403_retryable(self):
        for status in (401, 403, 429, 500):
            opener = mock.Mock()
            opener.open.side_effect = error.HTTPError(BASE, status, "private secret", {},
                                                       io.BytesIO(b"private response"))
            with mock.patch.object(cloud.request, "build_opener", return_value=opener):
                with self.assertRaises(cloud.CloudError) as caught:
                    cloud.post_json(BASE, {})
            self.assertEqual(caught.exception.auth, status in (401, 403))
            self.assertNotIn("private", str(caught.exception))

    def test_invalid_destination_urls_are_rejected(self):
        for value in ("http://eu1-developer.deyecloud.com", "https://deyecloud.com.evil.invalid",
                      "https://evildeyecloud.com", "https://user:pass@eu1-developer.deyecloud.com",
                      "https://eu1-developer.deyecloud.com:8443", BASE + "?secret=oops",
                      BASE + "/device/latest", "https://localhost", None):
            with self.subTest(value=value):
                with self.assertRaises(cloud.CloudError):
                    cloud.api_base_url(value)
        self.assertEqual(cloud.api_base_url(BASE + "/"), BASE)


class MemorySocket:
    """Run the real HTTP request parser without opening a network socket."""

    def __init__(self, content):
        self.input = io.BytesIO(content)
        self.output = bytearray()

    def makefile(self, *_args):
        return self.input

    def sendall(self, content):
        self.output.extend(content)


class HTTPContractTests(unittest.TestCase):
    def setUp(self):
        self.client = mock.Mock()

    def send(self, method, path, content=b""):
        raw = ("%s %s HTTP/1.0\r\nHost: localhost\r\nContent-Length: %d\r\n\r\n" %
               (method, path, len(content))).encode() + content
        connection = MemorySocket(raw)
        server = mock.Mock(client=self.client)
        cloud.CloudRequestHandler(connection, ("127.0.0.1", 12345), server)
        headers, body = bytes(connection.output).split(b"\r\n\r\n", 1)
        status = int(headers.split(b" ")[1])
        return status, json.loads(body)

    def test_health_requires_no_credentials_and_latest_returns_original_api_json(self):
        self.assertEqual(self.send("GET", "/health"), (200, {"success": True}))
        self.client.latest.assert_not_called()
        self.client.latest.return_value = LATEST
        payload = {"api_url": BASE, "deviceList": ["test-sn"]}
        self.assertEqual(self.send("POST", "/device/latest", json.dumps(payload).encode()), (200, LATEST))
        self.client.latest.assert_called_once_with(payload)

    def test_errors_are_non_success_http_and_request_credentials_are_not_logged(self):
        self.client.latest.side_effect = RuntimeError("private credential in exception")
        logs = io.StringIO()
        with contextlib.redirect_stderr(logs):
            status, body = self.send("POST", "/device/latest", b'{"app_secret":"private credential"}')
        self.assertEqual(status, 500)
        self.assertNotIn("private credential", json.dumps(body) + logs.getvalue())
        self.assertEqual(body["success"], False)

    def test_malformed_json_is_rejected_before_client_call(self):
        self.assertEqual(self.send("POST", "/device/latest", b"not-json")[0], 400)
        self.client.latest.assert_not_called()


if __name__ == "__main__":
    unittest.main()
