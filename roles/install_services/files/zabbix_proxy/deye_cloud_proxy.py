#!/usr/bin/env python3
"""Local Deye Cloud reader with a private, persistent daily token cache.

POST /device/latest accepts api_url, deviceList and optional app_id/app_secret.
Account credentials and fallback app credentials come from the mounted JSON file.
Only token acquisition and the read-only device/latest endpoint are exposed.

Protocol references:
https://github.com/DeyeCloudDevelopers/deye-openapi-client-sample-code
https://developer.deyecloud.com/openmcp/docs/deye-open-mcp-tools.html
"""

import argparse
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import math
import os
from pathlib import Path
import tempfile
import threading
import time
from urllib import error, parse, request


MAX_TOKEN_AGE = 24 * 60 * 60
MAX_REQUEST_BYTES = 64 * 1024
MAX_RESPONSE_BYTES = 4 * 1024 * 1024
DEFAULT_CREDENTIALS_FILE = "/var/lib/zabbix/enc/deye-cloud.json"
DEFAULT_CACHE_DIR = "/var/lib/zabbix/deye-cloud-cache"


class CloudError(Exception):
    """An intentionally sanitized error suitable for the local HTTP response."""

    def __init__(self, message, status=502, auth=False):
        super().__init__(message)
        self.status = status
        self.auth = auth


def api_base_url(value):
    """Restrict credentials to HTTPS on Deye's developer domain."""
    if not isinstance(value, str):
        raise CloudError("api_url must be a Deye Cloud HTTPS URL.", 400)
    try:
        url = parse.urlsplit(value.strip())
        hostname = (url.hostname or "").lower()
        valid = (url.scheme == "https" and
                 (hostname == "deyecloud.com" or hostname.endswith(".deyecloud.com")) and
                 url.port in (None, 443) and not url.username and not url.password and
                 not url.query and not url.fragment and
                 url.path.rstrip("/") in ("", "/v1.0"))
    except ValueError:
        valid = False
    if not valid:
        raise CloudError("api_url must be a Deye Cloud HTTPS URL.", 400)
    return "https://" + hostname + "/v1.0"


def bearer_token(value):
    if not isinstance(value, str):
        raise CloudError("Deye Cloud returned an invalid access token.")
    token = value.strip()
    while token.lower().startswith("bearer "):
        token = token[7:].strip()
    if not token or any(character.isspace() for character in token):
        raise CloudError("Deye Cloud returned an invalid access token.")
    return token


class NoRedirects(request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # urllib must never forward an app secret or bearer token to another URL.
        return None


def post_json(url, payload, token=None, timeout=10):
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    if token is not None:
        headers["Authorization"] = "Bearer " + bearer_token(token)
    req = request.Request(url, data=json.dumps(payload).encode("utf-8"),
                          headers=headers, method="POST")
    try:
        with request.build_opener(NoRedirects()).open(req, timeout=timeout) as response:
            raw = response.read(MAX_RESPONSE_BYTES + 1)
        if len(raw) > MAX_RESPONSE_BYTES:
            raise CloudError("Deye Cloud returned an oversized response.")
        result = json.loads(raw)
    except error.HTTPError as exc:
        raise CloudError("Deye Cloud HTTP request failed (status %d)." % exc.code,
                         auth=exc.code in (401, 403)) from None
    except (OSError, error.URLError, ValueError):
        raise CloudError("Deye Cloud request failed or returned invalid JSON.") from None
    if not isinstance(result, dict):
        raise CloudError("Deye Cloud returned an invalid response.")
    if result.get("success") is not True or str(result.get("code")) != "1000000":
        # Some deployments return rejected tokens as HTTP 200/business errors.
        code = str(result.get("code", ""))
        message = str(result.get("msg", "")).lower()
        auth = (code == "2101019" or
                ("token" in message and any(word in message for word in
                 ("invalid", "expired", "expire", "unauthorized"))))
        safe_code = code if code.isascii() and code.isdigit() and len(code) <= 10 else "unknown"
        raise CloudError("Deye Cloud rejected the request (code %s)." % safe_code,
                         auth=auth)
    return result


class CloudClient:
    def __init__(self, credentials_file=None, cache_dir=None, transport=None, clock=None):
        self.credentials_file = Path(credentials_file or os.environ.get(
            "DEYE_CLOUD_CREDENTIALS_FILE", DEFAULT_CREDENTIALS_FILE))
        self.cache_dir = Path(cache_dir or os.environ.get(
            "DEYE_CLOUD_CACHE_DIR", DEFAULT_CACHE_DIR))
        self.transport = transport or post_json
        self.clock = clock or time.time
        self._locks = {}
        self._locks_guard = threading.Lock()

    def _credentials(self):
        try:
            credentials = json.loads(self.credentials_file.read_text())
            if not isinstance(credentials, dict):
                raise ValueError
            login = credentials.get("login") or credentials.get("email")
            password = credentials.get("password")
            if (not isinstance(login, str) or not login.strip() or
                    not isinstance(password, str) or not password):
                raise ValueError
        except (OSError, ValueError):
            raise CloudError("Deye Cloud credentials are unavailable or invalid.", 503) from None
        return credentials, login.strip(), password

    def _lock(self, key):
        with self._locks_guard:
            return self._locks.setdefault(key, threading.Lock())

    def _cache_path(self, key):
        try:
            self.cache_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
            self.cache_dir.chmod(0o700)
        except OSError:
            raise CloudError("Deye Cloud token cache is unavailable.", 503) from None
        return self.cache_dir / (key + ".json")

    def _cached_token(self, path):
        try:
            path.chmod(0o600)
            data = json.loads(path.read_text())
            now = self.clock()
            issued = data["issued_at"]
            expires = data["expires_at"]
            if (not all(isinstance(value, (int, float)) and not isinstance(value, bool)
                        and math.isfinite(value) for value in (issued, expires)) or
                    not issued <= now < min(expires, issued + MAX_TOKEN_AGE)):
                return None
            return bearer_token(data["access_token"])
        except (OSError, ValueError, KeyError, TypeError, CloudError):
            return None

    def _write_token(self, path, data):
        temporary = None
        try:
            descriptor, temporary = tempfile.mkstemp(prefix=".token-", dir=self.cache_dir)
            with os.fdopen(descriptor, "w") as stream:
                json.dump(data, stream)
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, path)
        except OSError:
            raise CloudError("Deye Cloud token cache could not be saved.", 503) from None
        finally:
            if temporary is not None:
                try:
                    os.unlink(temporary)
                except FileNotFoundError:
                    pass

    def _refresh_token(self, base, app_id, app_secret, login, password, path):
        issued = self.clock()
        result = self.transport(base + "/account/token?" + parse.urlencode({"appId": app_id}), {
            "appSecret": app_secret, "email": login,
            "password": hashlib.sha256(password.encode("utf-8")).hexdigest(),
        })
        token = bearer_token(result.get("accessToken"))
        try:
            lifetime = float(result.get("expiresIn", MAX_TOKEN_AGE))
            if not math.isfinite(lifetime) or lifetime <= 0:
                raise ValueError
        except (TypeError, ValueError):
            raise CloudError("Deye Cloud returned an invalid token expiry.") from None
        # Preserve the daily cadence, but stop using shorter-lived tokens slightly
        # before server expiry so an in-flight data request does not race it.
        usable_lifetime = min(lifetime, MAX_TOKEN_AGE)
        if lifetime <= MAX_TOKEN_AGE:
            usable_lifetime -= min(30, lifetime * 0.1)
        self._write_token(path, {"access_token": token, "issued_at": issued,
                                 "expires_at": issued + usable_lifetime})
        return token

    def latest(self, payload):
        if not isinstance(payload, dict):
            raise CloudError("The request must be a JSON object.", 400)
        base = api_base_url(payload.get("api_url"))
        devices = payload.get("deviceList")
        if (not isinstance(devices, list) or not 1 <= len(devices) <= 10 or
                any(not isinstance(device, str) or not device.strip() or len(device) > 512
                    for device in devices)):
            raise CloudError("deviceList must contain between 1 and 10 device serial numbers.", 400)
        credentials, login, password = self._credentials()
        values = []
        for field in ("app_id", "app_secret"):
            value = payload.get(field)
            if value is None or value == "" or (isinstance(value, str) and not value.strip()):
                value = credentials.get(field)
            if not isinstance(value, str) or not value.strip():
                raise CloudError("Deye Cloud application credentials are unavailable or invalid.", 503)
            values.append(value.strip())
        app_id, app_secret = values
        identity = json.dumps([base, app_id, app_secret, login, password], separators=(",", ":"))
        key = hashlib.sha256(identity.encode("utf-8")).hexdigest()
        # Serialize each account/app pair, including the retry, to prevent refresh storms.
        with self._lock(key):
            path = self._cache_path(key)
            token = self._cached_token(path)
            if token is None:
                token = self._refresh_token(base, app_id, app_secret, login, password, path)
            for attempt in range(2):
                try:
                    return self.transport(base + "/device/latest", {"deviceList": devices}, token=token)
                except CloudError as exc:
                    if not exc.auth or attempt:
                        raise
                    try:
                        path.unlink(missing_ok=True)
                    except OSError:
                        raise CloudError("Deye Cloud token cache is unavailable.", 503) from None
                    token = self._refresh_token(base, app_id, app_secret, login, password, path)


class CloudHTTPServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address, client):
        self.client = client
        super().__init__(address, CloudRequestHandler)

    def handle_error(self, request, client_address):
        # BaseServer's traceback can include exception text from request data.
        pass


class CloudRequestHandler(BaseHTTPRequestHandler):
    def log_message(self, *_args):
        pass

    def _reply(self, status, payload):
        content = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(content)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(content)

    def do_GET(self):
        if self.path == "/health":
            self._reply(200, {"success": True})
        else:
            self._reply(404, {"success": False, "msg": "Unknown endpoint."})

    def do_POST(self):
        if self.path != "/device/latest":
            self._reply(404, {"success": False, "msg": "Unknown endpoint."})
            return
        try:
            try:
                length = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                raise CloudError("A valid Content-Length is required.", 400) from None
            if not 0 < length <= MAX_REQUEST_BYTES:
                raise CloudError("The JSON request is missing or too large.", 400)
            try:
                payload = json.loads(self.rfile.read(length))
            except (ValueError, UnicodeError):
                raise CloudError("The request contains invalid JSON.", 400) from None
            self._reply(200, self.server.client.latest(payload))
        except CloudError as exc:
            self._reply(exc.status, {"success": False, "code": "DEYE_PROXY_ERROR", "msg": str(exc)})
        except Exception:
            self._reply(500, {"success": False, "code": "DEYE_PROXY_ERROR",
                              "msg": "Deye Cloud helper failed."})


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=int(os.environ.get("DEYE_CLOUD_PORT", "8766")))
    args = parser.parse_args(argv)
    if not 1 <= args.port <= 65535:
        parser.error("port must be between 1 and 65535")
    with CloudHTTPServer(("127.0.0.1", args.port), CloudClient()) as server:
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
