from termcolor import colored

from datetime import datetime, timezone
from os import getcwd, environ
from pathlib import Path
import socketserver
import http.server
import socket
import json
import sys

def json_to_bytes(str: str) -> bytearray:
    return bytearray(json.dumps(str), "utf-8")

# Who needs Flask, anyways?
class HTTPHandler(http.server.BaseHTTPRequestHandler):
    def send_headers(self):
        self.send_header("Content-Type", "application/json")
        self.end_headers()
    
    def do_POST(self):
        if self.path == "/api/installer_update_webhook":
            content_length = 0
            
            try:
                content_length = int(self.headers.get('Content-Length'))
            except ValueError:
                self.send_response(400)
                self.send_headers()

                self.wfile.write(json_to_bytes({
                    "success": False,
                    "error": "Failed to decode Content-Length to read body",
                }))

                return

            resp_data = self.rfile.read(content_length).decode("utf-8")
            resp_decoded_data: dict = {}

            try:
                resp_decoded_data = json.loads(resp_data)

                if type(resp_decoded_data) is not dict:
                    self.send_response(400)
                    self.send_headers()

                    self.wfile.write(json_to_bytes({
                        "success": False,
                        "error": "Recieved invalid type for JSON",
                    }))

                    return
            except json.JSONDecodeError:
                self.send_response(400)
                self.send_headers()

                self.wfile.write(json_to_bytes({
                    "success": False,
                    "error": "Failed to decode JSON",
                }))

                return

            date_time = datetime.fromtimestamp(resp_decoded_data["timestamp"], timezone.utc)
            str_formatted_time = date_time.strftime("%H:%M:%S")

            result_is_safe = resp_decoded_data["result"] == "SUCCESS" if "result" in resp_decoded_data else True
            output_file = sys.stdout if result_is_safe else sys.stderr

            output_coloring = "light_blue"

            if "result" in resp_decoded_data:
                res = resp_decoded_data["result"]

                if res == "SUCCESS":
                    output_coloring = "light_green"
                elif res == "WARN":
                    output_coloring = "light_yellow"
                elif res == "FAIL":
                    output_coloring = "light_red"
            
            result_text_component = f" {resp_decoded_data["result"]} " if "result" in resp_decoded_data else " "
            final_output_text = f"{str_formatted_time} {resp_decoded_data["event_type"].upper()} {resp_decoded_data["level"]}:{result_text_component}{resp_decoded_data["name"]} ({resp_decoded_data["description"]})"

            print(colored(final_output_text, output_coloring), file=output_file)

            self.send_response(200)
            self.send_headers()

            self.wfile.write(json_to_bytes({
                "success": True,
            }))

            if resp_decoded_data["event_type"] == "finish" and resp_decoded_data["name"] == "subiquity/Shutdown/shutdown":
                print("\nSuccessfully finished installing!")
                exit(0)
        else:
            self.send_response(404)
            self.send_headers()

            self.wfile.write(json_to_bytes({
                "success": False,
                "error": "Unknown route"
            }))
    
    def do_GET(self):
        resolved_path = str(Path(self.path).resolve())
        file_path = getcwd() + resolved_path

        try:
            self.send_response(200)
            self.end_headers()

            with open(file_path, "rb") as file:
                self.wfile.write(file.read())
        except (FileNotFoundError, IsADirectoryError):
            self.send_response(404)
            self.send_headers()

            self.wfile.write(json_to_bytes({
                "success": False,
                "error": "file not found"
            }))
        except () as exception:
            exception.print_exception()
    
    def log_message(self, format: str, *args):
        status_code = 0

        try:
            status_code = int(args[1])
        except ValueError:
            pass

        # Disable logging for the /api/ endpoint for POST requests unless the error code > 400
        if len(args) >= 1 and args[0].startswith("POST") and self.path.startswith("/api/") and status_code < 400:
            return
        
        super().log_message(format, *args)

port = int(sys.argv[1]) if "SERVE_DEVELOP" not in environ else 10240
server = socketserver.TCPServer(("", port), HTTPHandler)
server.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

print("[x] started HTTP server.")
server.serve_forever()