# TODO:
# Install logging over HTTP *could* be implemented (see autoinstall documentation), however
# it is not implemented here.

import socketserver
import http.server
import socket
import sys

requests = set()

class HTTPHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        http.server.SimpleHTTPRequestHandler.do_GET(self)
        requests.add(self.path)

        found_meta_data   = "/meta-data" in requests
        found_user_data   = "/user-data" in requests
        found_vendor_data = "/vendor-data" in requests
        
        if found_meta_data and found_user_data and found_vendor_data:
            print("[x] sent all our data, exiting...")
            sys.exit(0)

server = socketserver.TCPServer(("", int(sys.argv[1])), HTTPHandler)
server.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

print("[x] started HTTP server.")
server.serve_forever()