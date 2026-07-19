#!/usr/bin/env python3
import http.server
import socketserver


class Proxy(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_error(501, "Proxy script placeholder")

    def do_CONNECT(self):
        self.send_error(501, "CONNECT is not implemented")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=18080)
    args = parser.parse_args()

    with socketserver.ThreadingTCPServer((args.host, args.port), Proxy) as httpd:
        httpd.serve_forever()
