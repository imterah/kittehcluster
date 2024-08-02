#!/usr/bin/env python3
from os import environ, path, listdir
from sys import argv

import configparser
import base64
import yaml

for item in ["K3S_TOKEN", "SETUP_USERNAME", "SETUP_PASSWORD"]:
    if item not in environ:
        print(f"ERROR: .env failed to load! (missing environment variable '{item}')")
        exit(1)

if len(argv) < 3:
    print("ERROR: Missing the server name or the webhook URL")
    exit(1)

server_name = argv[1]
server_webhook_url = argv[2]

server_infra_contents = ""

with open("config/infrastructure.ini", "r") as f:
    server_infra_contents = f.read()

infrastructure = configparser.ConfigParser()
infrastructure.read_string(server_infra_contents)

if server_name not in infrastructure:
    print("ERROR: Server not found in infrastructure document")
    exit(1)

infra_server = infrastructure[server_name]
ubuntu_install_contents = ""

with open("ubuntu-install.yml", "r") as f:
    ubuntu_install_contents = f.read()

yaml_install_script = yaml.load(ubuntu_install_contents, Loader=yaml.CLoader)

for item in ["hostname", "role"]:
    if item not in infra_server:
        print(f"ERROR: Missing {item} in {server_name}")
        exit(1)

custom_shell_script = "#!/usr/bin/env bash\n"
custom_shell_script += f"export K3S_TOKEN=\"{environ["K3S_TOKEN"]}\"\n"
custom_shell_script += f"export SERVER_NAME=\"{server_name}\"\n"
custom_shell_script += f"export SERVER_HOSTNAME=\"{infra_server["hostname"]}\"\n"

if "upstream" in infra_server:
    upstream_name = infra_server["upstream"]

    if upstream_name not in infrastructure:
        print(f"ERROR: Could not find upstream server '{upstream_name}'")
        exit(1)

    upstream_server = infrastructure[infra_server["upstream"]]

    if "hostname" not in upstream_server:
        print(f"ERROR: Missing hostname in upstream '{upstream_name}'")
        exit(1)

    custom_shell_script += f"export UPSTREAM_NAME=\"{upstream_name}\"\n"
    custom_shell_script += f"export UPSTREAM_HOSTNAME=\"{upstream_server["hostname"]}\"\n"

custom_shell_script += "\n"

with open(f"base-scripts/role.{infra_server["role"]}.sh", "r") as base_script:
    custom_shell_script += base_script.read()

encoded_custom_shell_script = base64.b64encode(bytes(custom_shell_script, "utf-8")).decode("utf-8")

yaml_install_script["autoinstall"]["late-commands"] = []
yaml_install_script["autoinstall"]["late-commands"].append(f"bash -c \"echo \"{encoded_custom_shell_script}\" | base64 -d > /target/postinstall_script\"")
yaml_install_script["autoinstall"]["late-commands"].append("curtin in-target -- bash /postinstall_script")
yaml_install_script["autoinstall"]["late-commands"].append("rm -rf /target/postinstall_script")

yaml_install_script["autoinstall"]["ssh"]["authorized-keys"] = []

ssh_directory_contents = []

try:
    ssh_directory_contents = listdir(path.expanduser("~/.ssh/"))
except FileNotFoundError:
    pass

for file in ssh_directory_contents:
    if file.endswith(".pub"):
        with open(path.join(path.expanduser("~/.ssh/"), file), "r") as ssh_public_key:
            yaml_install_script["autoinstall"]["ssh"]["authorized-keys"].append(ssh_public_key.read())

yaml_install_script["autoinstall"]["identity"]["hostname"] = infra_server["hostname"]
yaml_install_script["autoinstall"]["identity"]["username"] = environ["SETUP_USERNAME"]
yaml_install_script["autoinstall"]["identity"]["password"] = environ["SETUP_PASSWORD"]

yaml_install_script["autoinstall"]["reporting"]["hook"]["endpoint"] = server_webhook_url

ubuntu_install_contents = yaml.dump(yaml_install_script, Dumper=yaml.CDumper)

with open("/tmp/script.yml", "w") as new_install_script:
    new_install_script.write(ubuntu_install_contents)
