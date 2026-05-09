#!/usr/bin/env python3
import argparse
import select
import socket
import socketserver
import urllib.request
from http.server import BaseHTTPRequestHandler


class ProxyHandler(BaseHTTPRequestHandler):
    timeout = 30

    def log_message(self, fmt, *args):
        return

    def do_CONNECT(self):
        host, _, port = self.path.partition(":")
        port = int(port or 443)
        try:
            upstream = socket.create_connection((host, port), timeout=self.timeout)
        except OSError as exc:
            self.send_error(502, str(exc))
            return

        self.send_response(200, "Connection established")
        self.end_headers()
        sockets = [self.connection, upstream]
        try:
            while True:
                readable, _, errored = select.select(sockets, [], sockets, self.timeout)
                if errored or not readable:
                    break
                for source in readable:
                    data = source.recv(65536)
                    if not data:
                        return
                    target = upstream if source is self.connection else self.connection
                    target.sendall(data)
        finally:
            upstream.close()

    def do_GET(self):
        self._proxy_http_request()

    def do_HEAD(self):
        self._proxy_http_request()

    def _proxy_http_request(self):
        if not self.path.startswith(("http://", "https://")):
            self.send_error(400, "Proxy request must use an absolute URL")
            return

        request = urllib.request.Request(self.path, method=self.command)
        for key, value in self.headers.items():
            if key.lower() not in {"proxy-connection", "connection"}:
                request.add_header(key, value)

        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                self.send_response(response.status)
                for key, value in response.headers.items():
                    if key.lower() not in {"transfer-encoding", "connection"}:
                        self.send_header(key, value)
                self.end_headers()
                if self.command != "HEAD":
                    while True:
                        chunk = response.read(65536)
                        if not chunk:
                            break
                        self.wfile.write(chunk)
        except Exception as exc:
            self.send_error(502, str(exc))


class ThreadingTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, required=True)
    args = parser.parse_args()

    with ThreadingTCPServer((args.host, args.port), ProxyHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
