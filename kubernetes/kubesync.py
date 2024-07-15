#!/usr/bin/env python3
from dataclasses import dataclass
from pathlib import Path

import configparser
import subprocess
import argparse
import hashlib
import signal
import shutil
import sys
import os

from typing import Optional

latest_format_ver = 1

print("KubeSync (KittehCluster, v1.0.0-test)")

parser = argparse.ArgumentParser(description="Knockoff of ansible for K3s. By default, provisions only")

parser.add_argument(
    "--update",
    help="Updates all Helm charts/packages (K3s is automatically updated due to the nature of how it works)",
    action=argparse.BooleanOptionalAction
)

parser.add_argument(
    "--deprovision",
    help="Attempts to deprovision the cluster (note: will NOT run shell scripts)",
    action=argparse.BooleanOptionalAction
)

parser.add_argument(
    "--dryrun-only",
    help="Disable writing and applying the changeset, and give a shell script to manually run it",
    action=argparse.BooleanOptionalAction
)

args = parser.parse_args()

changeset_path = None
mode = "provision"
projects = []

if args.update:
    mode = "update"
elif args.deprovision:
    mode = "deprovision"

print("Reading project file...")

try:
    os.mkdir("meta")
except FileExistsError:
    pass

@dataclass
class HelmSettings:
    mode: str # add_repo, upgrade, install
    name: str
    repo: Optional[str]
    namespace_name: Optional[str]
    create_namespace: bool

@dataclass
class KubeSettings:
    mode: str # install
    yml_path: str

@dataclass
class ShellSettings:
    mode: str # this, serv_node, agent_node, all_node
    shell: str

@dataclass
class Project:
    name: str
    description: Optional[str]
    depends_on: list[str]
    mode: str # helm, k3s, shell, include
    helm_settings:  Optional[HelmSettings]
    kube_settings:  Optional[KubeSettings]
    shell_settings: Optional[ShellSettings]

helm_mode_settings = [
    "add_repo",
    "upgrade",
    "install"
]

kube_mode_settings = [
    "install"
]

shell_mode_settings = [
    "this",
    "serv_node",
    "agent_node",
    "all_node"
]

def parse_project(contents: str, workdir=os.getcwd()) -> list[Project]:
    project_out: list[Project] = []

    project = configparser.ConfigParser()
    project.read_string(contents)

    if "meta" not in project or "format_ver" not in project["meta"]:
        print("WARN: 'meta' attribute missing! Cannot check formatting")
    else:
        try:
            if latest_format_ver != int(project["meta"]["format_ver"]):
                print("ERROR: Incompatible format version! You need to migrate your 'project.ini' file(s) from version '%s' to '%s'" % (project["meta"]["format_ver"], latest_format_ver))
                exit(1)
        except ValueError:
            print("ERROR: Format version is not a number!")
            exit(1)

    for key in project.keys():
        if key == "DEFAULT" or key == "meta" or key.startswith("#"):
            continue

        depends_on = []

        if "mode" not in project[key]:
            print("ERROR: Mode is not defined!")
            exit(1)

        if "depends_on" in project[key]:
            depends_on = project[key]["depends_on"].split(":")

        match project[key]["mode"]:
            case "helm":
                if f"#{key}/helm" not in project:
                    print("ERROR: Could not find 'helm' entry (in helm type)")

                found_project = project[f"#{key}/helm"]

                if "mode" not in found_project:
                    print("ERROR: Mode is not defined!")
                    exit(1)

                if found_project["mode"] not in helm_mode_settings:
                    print("ERROR: Invalid mode recieved!")
                    exit(1)

                create_namespace = False

                try:
                    create_namespace = found_project.getboolean("create_namespace")
                except ValueError:
                    pass

                helm_settings = HelmSettings(
                    found_project["mode"],
                    found_project["name"],
                    found_project["repo"] if "repo" in found_project else None,
                    found_project["namespace"] if "namespace" in found_project else None,
                    create_namespace
                )

                project_obj = Project(
                    key,
                    project[key]["description"] if "description" in project[key] else None,
                    depends_on,
                    project[key]["mode"],
                    helm_settings,
                    None,
                    None
                )

                project_out.append(project_obj)
            case "k3s":
                if f"#{key}/k3s" not in project:
                    print("ERROR: Could not find 'k3s' entry (in k3s type)")

                found_project = project[f"#{key}/k3s"]

                if "mode" not in found_project:
                    print("ERROR: Mode is not defined!")
                    exit(1)

                if found_project["mode"] not in kube_mode_settings:
                    print("ERROR: Invalid mode recieved!")
                    exit(1)

                if "yml_path" not in found_project:
                    print("ERROR: Missing yml path!")
                    exit(1)

                k3s_settings = KubeSettings(
                    found_project["mode"],
                    os.path.join(workdir, found_project["yml_path"])
                )

                project_obj = Project(
                    key,
                    project[key]["description"] if "description" in project[key] else None,
                    depends_on,
                    project[key]["mode"],
                    None,
                    k3s_settings,
                    None
                )

                project_out.append(project_obj)
            case "shell":
                if f"#{key}/shell" not in project:
                    print("ERROR: Could not find 'shell' entry (in shell type)")

                found_project = project[f"#{key}/shell"]

                if "mode" not in found_project:
                    print("ERROR: Mode is not defined!")
                    exit(1)

                if found_project["mode"] not in shell_mode_settings:
                    print("ERROR: Invalid mode recieved!")
                    exit(1)

                if "shell" not in found_project:
                    print("ERROR: Could not find shell script in project!")
                    exit(1)

                shell_settings = ShellSettings(
                    found_project["mode"],
                    found_project["shell"]
                )

                project_obj = Project(
                    key,
                    project[key]["description"] if "description" in project[key] else None,
                    depends_on,
                    project[key]["mode"],
                    None,
                    None,
                    shell_settings
                )

                project_out.append(project_obj)
            case "include":
                if "path" not in project[key]:
                    print("ERROR: Could not find 'path' entry (in include type)")

                file_path = os.path.join(workdir, project[key]["path"])

                try:
                    with open(file_path, "r") as raw_project_file:
                        new_project_tree = parse_project(raw_project_file.read(), os.path.dirname(file_path))
                        project_out = project_out + new_project_tree
                except FileNotFoundError:
                    print(f"ERROR: Could not read file {file_path}")
                    exit(1)
            case _:
                print("ERROR: Invalid mode!")
                exit(1)

    return project_out

# Based on Kahn's algorithm
def sort_projects(projects: list[Project]) -> list[Project]:
    sorted_projects: list[Project] = []
    project_list_staging: list[Project] = [x for x in projects if not x.depends_on]

    while project_list_staging:
        n = project_list_staging.pop(0)
        sorted_projects.append(n)
        
        nodes_with_edges = list(filter(lambda x: n.name in x.depends_on, projects))

        for m in nodes_with_edges:
            m.depends_on.remove(n.name)

            if not m.depends_on:
                project_list_staging.append(m)

    # Check for circular dependencies/cycles
    if any(project.depends_on for project in projects):
        raise ValueError("Found circular dependency")
    
    return sorted_projects

def generate_change_set(projects: list[Project]) -> dict[str, list[str]]:
    global changeset_path

    sorted_projects = sort_projects(projects)
    changeset_values: dict[str, list[str]] = {}

    k3s_config_raw = subprocess.run([
        "kubectl",
        "config",
        "view",
        "--raw"
    ], stdout=subprocess.PIPE)

    k3s_config_str = k3s_config_raw.stdout.decode("utf-8")
    changeset_meta_id = ""

    for line in k3s_config_str.splitlines():
        if line.strip().startswith("certificate-authority-data"):
            data = line.strip()[line.strip().index(" ") + 1:]
            data_in_bytes = bytearray(changeset_meta_id + data, "utf-8")
            changeset_meta_id = hashlib.md5(data_in_bytes).hexdigest()
    
    base_changeset_path = f"meta/{changeset_meta_id}"
    
    try:
        os.mkdir(base_changeset_path)
    except FileExistsError:
        pass

    dir_contents = os.listdir(base_changeset_path)
    changeset_path = f"{base_changeset_path}/gen_{len(dir_contents) + 1}/"
    
    try:
        shutil.copytree(f"{base_changeset_path}/gen_{len(dir_contents) - 1}/", changeset_path)
    except FileNotFoundError:
        os.mkdir(changeset_path)
        os.mkdir(f"{changeset_path}/k3hashes")
        os.mkdir(f"{changeset_path}/helmhashes")
        os.mkdir(f"{changeset_path}/shellhashes")
    
    for project in sorted_projects:
        match project.mode:
            case "helm":
                if project.helm_settings.mode == "add_repo":
                    if project.helm_settings.repo == None or project.helm_settings.name == None:
                        print("ERROR: 'add_repo' is set but either repo or name is undefined")
                        exit(1)
                    
                    data_in_bytes = bytearray(f"add_repo.{project.helm_settings.repo}_{project.helm_settings.name}", "utf-8")
                    meta_id = hashlib.md5(data_in_bytes).hexdigest()

                    if not os.path.isfile(f"{changeset_path}/helmhashes/{meta_id}"):
                        Path(f"{changeset_path}/helmhashes/{meta_id}").touch()
                        
                        changeset_values[project.name] = [
                            f"helm repo add {project.helm_settings.name} {project.helm_settings.repo}"
                        ]
                elif project.helm_settings.mode == "upgrade" or project.helm_settings.mode == "install":
                    if project.helm_settings.name == None or project.helm_settings.repo == None or project.helm_settings.namespace_name == None:
                        print("ERROR: 'upgrade' or 'install' is set but either: name, repo, or namespace_name is undefined")
                        exit(1)
                    
                    data_in_bytes = bytearray(f"install.{project.helm_settings.repo}_{project.helm_settings.name}", "utf-8")
                    meta_id = hashlib.md5(data_in_bytes).hexdigest()

                    if not os.path.isfile(f"{changeset_path}/helmhashes/{meta_id}") and project.helm_settings.mode == "install":
                        Path(f"{changeset_path}/helmhashes/{meta_id}").touch()

                        changeset_values[project.name] = [
                            f"helm repo update {project.helm_settings.repo}",
                            f"helm upgrade --install {project.helm_settings.name} {project.helm_settings.repo} {"--create-namespace" if project.helm_settings.create_namespace else ""} --namespace {project.helm_settings.namespace_name}"
                        ]
                    elif project.helm_settings.mode == "upgrade" or mode == "update":
                        changeset_values[project.name] = [
                            f"helm repo update {project.helm_settings.repo}",
                            f"helm upgrade {project.helm_settings.name} {project.helm_settings.repo} {"--create-namespace" if project.helm_settings.create_namespace else ""} --namespace {project.helm_settings.namespace_name}"
                        ]
            case "k3s":
                data_in_bytes = bytearray(f"{project.kube_settings.yml_path}", "utf-8")
                meta_id = hashlib.md5(data_in_bytes).digest().hex()

                if not os.path.isfile(f"{changeset_path}/k3hashes/{meta_id}"):
                    file_hash = ""

                    with open(project.kube_settings.yml_path, "rb") as kube_file:
                        data = kube_file.read()
                        file_hash = hashlib.md5(data).hexdigest()
                    
                    with open(f"{changeset_path}/k3hashes/{meta_id}", "w") as kube_metaid_file:
                        kube_metaid_file.write(file_hash)
                else:
                    file_hash = ""

                    with open(project.kube_settings.yml_path, "rb") as kube_file:
                        data = kube_file.read()
                        file_hash = hashlib.md5(data).hexdigest()
                    
                    with open(f"{changeset_path}/k3hashes/{meta_id}", "rw") as kube_metaid_file:
                        if kube_metaid_file.read() == file_hash:
                            continue
                        else:
                            kube_metaid_file.write(file_hash)
                    
                changeset_values[project.name] = [
                    f"kubectl apply -f {project.kube_settings.yml_path}"
                ]
            case _:
                raise Exception("Could not match project type?")

    return changeset_values

def sigint_handler(signum, frame):
    print("Reverting generation...")

    if changeset_path == None:
        print("Changeset path is not set yet. Exiting...")
        
        if signum != None:
            sys.exit(0)

    shutil.rmtree(changeset_path)
    
    if signum != None:
        print("Exiting...")
        sys.exit(0)

signal.signal(signal.SIGINT, sigint_handler)

print("Parsing projects...")

try:
    with open("project.ini", "r") as project_file:
        projects = parse_project(project_file.read())
except FileNotFoundError:
    print("Could not find root project file!")
    exit(1)

if not projects:
    print("No projects could be found!")
    exit(1)

print("Generating changesets...")
change_set = generate_change_set(projects)

if args.dryrun_only:
    sigint_handler(None, None)

    print("Generating changeset script (writing to stderr!)")
    print("#!/usr/bin/env bash", file=sys.stderr)

    for project_name in change_set:
        print(f'echo "Applying changeset for \'{project_name}\'..."', file=sys.stderr)
        
        for command in change_set[project_name]:
            print(command, file=sys.stderr)
else:
    for project_name in change_set:
        print(f"Applying changeset for '{project_name}'...")

        for command in change_set[project_name]:
            os.system(command)