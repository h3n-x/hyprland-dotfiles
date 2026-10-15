#!/usr/bin/env python3
"""
audio-manager.sh - Administrador de dispositivos de audio PipeWire/WirePlumber
Uso:
  audio-manager.sh data               -> Devuelve JSON con lista de sinks y sources
  audio-manager.sh set-default <id>   -> Establece el dispositivo por defecto
  audio-manager.sh set-volume <id> <vol> -> Establece el volumen (0.0 - 1.0)
  audio-manager.sh toggle-mute <id>   -> Alterna mute en el dispositivo
"""

import sys
import os
import re

# Textos en el idioma del usuario (Fase 15 B4): scripts/i18n, texto fuente en ingles.
def _i18n():
    import importlib.machinery, importlib.util
    sys.dont_write_bytecode = True  # sin __pycache__ junto a los scripts
    loader = importlib.machinery.SourceFileLoader("i18n", os.path.join(os.path.dirname(os.path.realpath(__file__)), "i18n"))
    mod = importlib.util.module_from_spec(importlib.util.spec_from_loader("i18n", loader))
    loader.exec_module(mod)
    return mod
T, Tn = _i18n().translator()
import json
import subprocess

def get_audio_devices():
    res = subprocess.run(["wpctl", "status"], capture_output=True, text=True)
    lines = res.stdout.split("\n")

    sinks = []
    sources = []
    in_audio = False
    section = None

    for line in lines:
        if line.startswith("Audio"):
            in_audio = True
            continue
        elif line.startswith("Video") or line.startswith("Settings"):
            in_audio = False
            section = None
            continue

        if not in_audio:
            continue

        if "Sinks:" in line:
            section = "sinks"
            continue
        elif "Sources:" in line:
            section = "sources"
            continue
        elif "Filters:" in line or "Streams:" in line:
            section = None
            continue

        if section in ("sinks", "sources"):
            clean = re.sub(r"^[│├└─\s]+", "", line).strip()
            if not clean:
                continue
            m = re.search(r"^(\*?)\s*(\d+)\.\s+(.*?)(?:\s+\[vol:\s*([\d\.]+)(?:\s+(MUTED))?\])?$", clean)
            if m:
                is_def = (m.group(1) == "*")
                dev_id = int(m.group(2))
                name = m.group(3).strip()
                vol = float(m.group(4)) if m.group(4) else 1.0
                muted = (m.group(5) == "MUTED")

                item = {
                    "id": dev_id,
                    "name": name,
                    "default": is_def,
                    "volume": vol,
                    "muted": muted
                }
                if section == "sinks":
                    sinks.append(item)
                else:
                    sources.append(item)

    return {"sinks": sinks, "sources": sources}

def main():
    if len(sys.argv) < 2:
        print("uso: audio-manager.sh [data|set-default <id> [name] [type]|set-volume <id> <vol>|toggle-mute <id>]")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "data":
        print(json.dumps(get_audio_devices()))
    elif cmd == "set-default":
        if len(sys.argv) < 3:
            sys.exit(1)
        dev_id = sys.argv[2]
        dev_name = sys.argv[3] if len(sys.argv) > 3 else T("Device")
        dev_type = sys.argv[4] if len(sys.argv) > 4 else "audio"

        subprocess.run(["wpctl", "set-default", dev_id])
        icon = "audio-speakers" if dev_type == "sink" else "audio-input-microphone"
        title = T("Output changed") if dev_type == "sink" else T("Microphone changed")
        subprocess.run([
            "notify-send", "-a", T("Audio"),
            title,
            dev_name,
            "-i", icon, "-t", "2000"
        ])
    elif cmd == "set-volume":
        if len(sys.argv) < 4:
            sys.exit(1)
        dev_id = sys.argv[2]
        vol = sys.argv[3]
        subprocess.run(["wpctl", "set-volume", dev_id, vol])
    elif cmd == "toggle-mute":
        if len(sys.argv) < 3:
            sys.exit(1)
        dev_id = sys.argv[2]
        subprocess.run(["wpctl", "set-mute", dev_id, "toggle"])
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
