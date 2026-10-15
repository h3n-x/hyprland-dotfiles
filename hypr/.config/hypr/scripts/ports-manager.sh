#!/usr/bin/env python3
"""
ports-manager.sh - Administrador de puertos abiertos para Quickshell
Filtrado especializado en entornos de desarrollo (Node, Python, Go, Rust, Java, Docker, etc.)
y pruebas de hacking / pentesting / CTF (Hack The Box, listeners nc/socat, chisel, metasploit, etc.)
excluyendo ruido de navegadores (Zen, Firefox, Chrome), Steam y servicios internos del sistema.

Uso:
  ports-manager.sh data [dev|all]     -> Devuelve JSON con lista de puertos (por defecto modo dev)
  ports-manager.sh count [dev|all]    -> Devuelve la cantidad de puertos
  ports-manager.sh close <proto> <port> [pid] [process] -> Cierra el puerto matando el proceso
"""

import sys
import os
import json
import re
import subprocess
import signal
import time

# Textos en el idioma del usuario (Fase 15 B4): scripts/i18n, texto fuente en ingles.
def _i18n():
    import importlib.machinery, importlib.util
    sys.dont_write_bytecode = True  # sin __pycache__ junto a los scripts
    loader = importlib.machinery.SourceFileLoader("i18n", os.path.join(os.path.dirname(os.path.realpath(__file__)), "i18n"))
    mod = importlib.util.module_from_spec(importlib.util.spec_from_loader("i18n", loader))
    loader.exec_module(mod)
    return mod
T, Tn = _i18n().translator()

# Procesos que deben ser ignorados por defecto (navegadores, multimedia, lanzadores de juegos, ruido de sistema)
BLACKLIST_PROCESSES = {
    "zen-bin", "zen", "zen-browser", "firefox", "firefox-bin", "chromium",
    "chrome", "google-chrome", "brave", "brave-bin", "vivaldi", "opera", "tor-browser",
    "steam", "steamwebhelper", "agy", "pipewire", "wireplumber", "wireplumber-pulse",
    "avahi-daemon", "systemd-resolved", "cupsd", "rtkit-daemon", "sddm", "hyprland",
    "quickshell", "qs", "dbus-daemon", "dbus-broker", "polkitd"
}

# Puertos fijos de ruido o broadcast/multicast que no son servidores de desarrollo ni pruebas de hacking
BLACKLIST_PORTS = {
    5353,   # mDNS (multicast DNS usado por navegadores y avahi)
    1900,   # SSDP / UPnP
    5355,   # LLMNR
    68,     # DHCP client
    67,     # DHCP server
    137,    # NetBIOS Name Service broadcast
    138,    # NetBIOS Datagram
}

# Palabras clave de procesos de desarrollo web, backend, bases de datos y contenedores
DEV_PROCESS_KEYWORDS = [
    # Node / JS / Web
    "node", "npm", "pnpm", "yarn", "bun", "deno", "vite", "next", "nuxt",
    "astro", "remix", "webpack", "esbuild", "turbo", "nodemon", "live-server",
    "http-server", "serve", "express", "fastify", "electron",
    # Python
    "python", "python3", "uvicorn", "gunicorn", "flask", "django", "fastapi",
    "jupyter", "streamlit", "tornado", "waitress", "celery", "asgi", "wsgi",
    # Otros lenguajes de backend
    "go", "air", "gin", "cargo", "rust", "java", "dotnet", "php", "artisan",
    "ruby", "rails", "puma",
    # Bases de datos y caches
    "postgres", "mysqld", "mariadb", "redis", "mongod", "surreal", "pocketbase",
    "sqlite3", "rabbitmq", "minio",
    # Contenedores y orquestacion
    "docker", "podman", "containerd", "k3s", "minikube",
    # Servidores web y proxies locales
    "nginx", "caddy", "apache", "httpd", "traefik", "caddyfile"
]

# Herramientas de Pentesting, Hacking, Hack The Box, CTF y tunneling
PENTEST_PROCESS_KEYWORDS = [
    "nc", "ncat", "netcat", "socat", "pwncat", "rustcat", "powercat",
    "chisel", "ngrok", "cloudflared", "frp", "frpc", "frps", "ligolo", "bore", "localtunnel",
    "msf", "msfconsole", "metasploit", "burp", "burpsuite", "zaproxy", "zap",
    "sqlmap", "responder", "impacket", "bloodhound", "neo4j", "crackmapexec",
    "netexec", "updog", "droopy", "simplehttp", "ssh", "sshd", "hashcat", "hydra"
]

# Puertos típicos de desarrollo y listeners de hacking
DEV_PENTEST_PORTS = {
    # Web y APIs
    80, 443, 8000, 8080, 8081, 8443, 8888, 9000, 9090, 5000, 5001,
    3000, 3001, 4000, 4200, 5173, 5174,
    # CTFs, reverse shells y listeners tipicos de Hack The Box
    1337, 4444, 4445, 5555, 9001, 9002, 9003, 1234, 6666, 6667, 7777,
    # Proxies / SOCKS
    1080, 8080, 8081,
    # Bases de datos
    5432, 3306, 6379, 27017, 9200,
    # Protocolos de prueba
    445, 139, 389, 636, 88, 21, 22, 23, 25
}

def is_dev_or_pentest(p):
    pname = (p.get("process") or "").lower()
    port = p.get("port")
    proto = p.get("proto")

    # 1. Filtro estricto por lista negra de puertos
    if port in BLACKLIST_PORTS:
        return False

    # 2. Filtro estricto por lista negra de procesos
    if pname in BLACKLIST_PROCESSES or any(b in pname for b in ["zen-bin", "zen", "steam", "agy", "firefox", "chromium"]):
        return False

    # 3. Coincidencia con herramientas de desarrollo
    for kw in DEV_PROCESS_KEYWORDS:
        if kw in pname:
            return True

    # 4. Coincidencia con herramientas de hacking / pentest
    for kw in PENTEST_PROCESS_KEYWORDS:
        if kw in pname:
            return True

    # 5. Puertos conocidos de desarrollo o CTF/HTB
    if port in DEV_PENTEST_PORTS:
        return True

    # 6. Rangos comunes de servidores dev (ej. 3000-3015, 5000-5015, 5173-5185, 8000-8015, 8080-8090)
    for start, end in [(3000, 3015), (5000, 5015), (5173, 5185), (8000, 8015), (8080, 8090)]:
        if start <= port <= end:
            return True

    # Si es un proceso desconocido o vacío y el puerto no está en los estándares, descartar
    if pname in ("-", ""):
        return False

    # Si es un proceso de usuario (no en blacklist) en puertos asignables de servicios (< 32768)
    if port < 32768 and proto == "TCP":
        return True

    return False

def get_open_ports(filter_mode="dev"):
    ports = []
    seen = set()

    try:
        res = subprocess.run(["ss", "-tulnp"], capture_output=True, text=True, timeout=3)
        lines = res.stdout.strip().split("\n")
    except Exception:
        lines = []

    for line in lines[1:]:
        parts = line.split()
        if len(parts) < 5:
            continue

        proto = parts[0].upper()
        if proto not in ("TCP", "UDP"):
            continue

        local_addr = parts[4]
        if ":" not in local_addr:
            continue

        port_str = local_addr.rsplit(":", 1)[1]
        host_str = local_addr.rsplit(":", 1)[0].strip("[]")
        try:
            port = int(port_str)
        except ValueError:
            continue

        pname = "-"
        pid = None
        if len(parts) >= 7:
            pinfo = parts[6]
            m = re.search(r'\(\("([^"]+)",pid=(\d+)', pinfo)
            if m:
                pname = m.group(1)
                pid = int(m.group(2))
            else:
                m2 = re.search(r'pid=(\d+)', pinfo)
                if m2:
                    pid = int(m2.group(1))

        # Si ss no detecto el proceso (por permisos u otro), intentar lsof
        if not pid or pname == "-":
            try:
                lsof = subprocess.run(
                    ["lsof", "-i", f"{proto.lower()}:{port}", "-t"],
                    capture_output=True, text=True, timeout=1
                )
                pids = lsof.stdout.strip().split()
                if pids:
                    pid = int(pids[0])
                    try:
                        with open(f"/proc/{pid}/comm", "r") as f:
                            pname = f.read().strip()
                    except Exception:
                        pname = "-"
            except Exception:
                pass

        key = (proto, port, pid)
        if key in seen:
            continue
        seen.add(key)

        item = {
            "proto": proto,
            "port": port,
            "host": host_str,
            "process": pname,
            "pid": pid
        }

        if filter_mode != "all":
            if not is_dev_or_pentest(item):
                continue

        ports.append(item)

    ports.sort(key=lambda x: (x["proto"], x["port"]))
    return ports

def close_port(proto, port_str, pid_str=None, pname=None):
    try:
        port = int(port_str)
    except ValueError:
        print(f"Error: Puerto invalido {port_str}", file=sys.stderr)
        return False

    killed = False
    target_pid = None
    if pid_str and pid_str not in ("-", "null", "None", ""):
        try:
            target_pid = int(pid_str)
        except ValueError:
            pass

    # 1. Matar por PID si se conoce
    if target_pid:
        try:
            os.kill(target_pid, signal.SIGTERM)
            time.sleep(0.25)
            # Si sigue vivo, forzar SIGKILL
            try:
                os.kill(target_pid, 0)
                os.kill(target_pid, signal.SIGKILL)
            except OSError:
                pass
            killed = True
        except ProcessLookupError:
            killed = True
        except PermissionError:
            pass

    # 2. Utilizar fuser como metodo directo para liberar el socket
    try:
        proto_flag = f"{port}/{proto.lower()}"
        res = subprocess.run(["fuser", "-k", "-TERM", proto_flag], capture_output=True, text=True)
        if res.returncode == 0:
            killed = True
            time.sleep(0.2)
            subprocess.run(["fuser", "-k", "-KILL", proto_flag], capture_output=True, text=True)
    except Exception:
        pass

    # 3. Notificar al usuario
    proc_info = f" ({pname})" if pname and pname != "-" else ""
    if killed:
        subprocess.run([
            "notify-send", "-a", T("Ports"),
            T("Port closed"),
            T("Port %1 was closed", f"{port}/{proto}{proc_info}"),
            "-i", "network-wired", "-t", "2500"
        ])
    else:
        subprocess.run([
            "notify-send", "-a", T("Ports"),
            T("Couldn't close the port"),
            T("Couldn't free port %1 (does it need root permissions?)", f"{port}/{proto}"),
            "-i", "dialog-warning", "-t", "3000"
        ])

    return killed

def main():
    if len(sys.argv) < 2:
        print("uso: ports-manager.sh [data [dev|all]|count [dev|all]|close <proto> <port> [pid] [process]]")
        sys.exit(1)

    cmd = sys.argv[1]
    filter_mode = "dev"
    if len(sys.argv) > 2 and sys.argv[2] in ("dev", "all"):
        filter_mode = sys.argv[2]

    if cmd == "data":
        ports = get_open_ports(filter_mode=filter_mode)
        print(json.dumps(ports))
    elif cmd == "count":
        ports = get_open_ports(filter_mode=filter_mode)
        print(len(ports))
    elif cmd == "close":
        if len(sys.argv) < 4:
            print("uso: ports-manager.sh close <proto> <port> [pid] [process]", file=sys.stderr)
            sys.exit(1)
        proto = sys.argv[2]
        port = sys.argv[3]
        pid = sys.argv[4] if len(sys.argv) > 4 else None
        pname = sys.argv[5] if len(sys.argv) > 5 else None
        close_port(proto, port, pid, pname)
    else:
        print(f"Comando desconocido: {cmd}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
