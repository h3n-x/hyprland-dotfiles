#!/usr/bin/env python3
"""
nvidia-status.sh - Monitorea el estado de energía de la dGPU NVIDIA (RTX 3050)
sin despertarla si está en reposo (D3cold/runtime PM).
"""

import os
import sys
import json
import subprocess

def get_status():
    pci_path = "/sys/bus/pci/devices/0000:01:00.0/power/runtime_status"
    if not os.path.exists(pci_path):
        for dev in os.listdir("/sys/bus/pci/devices"):
            if "01:00.0" in dev:
                pci_path = f"/sys/bus/pci/devices/{dev}/power/runtime_status"
                break

    status = "unknown"
    if os.path.exists(pci_path):
        try:
            with open(pci_path, "r") as f:
                status = f.read().strip()
        except Exception:
            pass

    is_active = (status == "active")
    processes = []

    if is_active:
        # GPU ya activa: consultar procesos que tienen abiertos los nodos /dev/nvidia*
        try:
            lsof = subprocess.run(["lsof", "-t", "/dev/nvidia0"], capture_output=True, text=True, timeout=1)
            pids = set(lsof.stdout.strip().split())
            for pid_str in pids:
                if not pid_str:
                    continue
                try:
                    pid = int(pid_str)
                    with open(f"/proc/{pid}/comm", "r") as f:
                        name = f.read().strip()
                    if name not in ("Xorg", "-"):
                        processes.append({"pid": pid, "name": name})
                except Exception:
                    pass
        except Exception:
            pass

    return {
        "status": status,
        "active": is_active,
        "text": "Activa" if is_active else "Reposo (D3cold - 0W)",
        # Nombre de ligadura de Material Symbols (lo dibuja ControlCenter.qml).
        "icon": "memory",
        "processes": processes
    }

def main():
    info = get_status()
    if len(sys.argv) > 1 and sys.argv[1] == "text":
        print(info["text"])
    else:
        print(json.dumps(info))

if __name__ == "__main__":
    main()
