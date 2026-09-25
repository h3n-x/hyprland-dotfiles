#!/bin/bash

# Cache de la galeria de wallpapers (Fase 3 B0): miniaturas 480x270 y paleta
# de cada wallpaper, sin escribir ningun archivo de tema.
#
#   wallpaper-cache.sh [--jobs N] [--force]
#
# Incremental: solo regenera lo que cambio (mtime/tamano) y borra entradas de
# archivos que ya no estan. Miniaturas con vipsthumbnail (GIF: primer cuadro
# con magick). Paletas con `matugen --dry-run --json` y una config vacia (no
# renderiza plantillas ni corre hooks); se guardan los roles en modo oscuro y
# claro para la vista previa de la galeria.
#
# Salida: ~/.cache/dotfiles/wallpapers/{thumbs/,palettes.json}

set -euo pipefail

WALLPAPERS_DIR="${WALLPAPERS_DIR:-$HOME/Pictures/Wallpapers}"
CACHE_DIR="${WALLPAPER_CACHE_DIR:-$HOME/.cache/dotfiles/wallpapers}"
JOBS=8
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --jobs)  JOBS="${2:?}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) sed -n '6p' "$0" | sed 's/^# \{0,3\}//'; exit 0 ;;
    *) echo "wallpaper-cache: opcion desconocida: $1" >&2; exit 2 ;;
  esac
done

for cmd in vipsthumbnail magick matugen python3; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "wallpaper-cache: falta $cmd" >&2; exit 1; }
done

mkdir -p "$CACHE_DIR/thumbs"
# Config de matugen sin plantillas: --dry-run igual la lee.
EMPTY_CFG="$CACHE_DIR/.matugen-empty.toml"
printf '[config]\n\n[templates]\n' > "$EMPTY_CFG"

WALLPAPERS_DIR="$WALLPAPERS_DIR" CACHE_DIR="$CACHE_DIR" JOBS="$JOBS" FORCE="$FORCE" EMPTY_CFG="$EMPTY_CFG" \
python3 - <<'PY'
import json, os, subprocess, sys, time
from concurrent.futures import ThreadPoolExecutor

walls = os.environ["WALLPAPERS_DIR"]
cache = os.environ["CACHE_DIR"]
jobs = max(1, int(os.environ["JOBS"]))
force = os.environ["FORCE"] == "1"
empty_cfg = os.environ["EMPTY_CFG"]
index_path = os.path.join(cache, "palettes.json")
thumbs = os.path.join(cache, "thumbs")
exts = (".png", ".jpg", ".jpeg", ".webp", ".gif")

t0 = time.time()
try:
    with open(index_path) as f:
        index = json.load(f)
except (OSError, ValueError):
    index = {}

files = sorted(n for n in os.listdir(walls)
               if n.lower().endswith(exts) and os.path.isfile(os.path.join(walls, n)))

def thumb_path(name):
    return os.path.join(thumbs, name + ".jpg")

def stale(name):
    st = os.stat(os.path.join(walls, name))
    e = index.get(name)
    return (force or e is None or e.get("mtime") != int(st.st_mtime) or e.get("size") != st.st_size
            or not os.path.exists(thumb_path(name)))

def build_thumb(name):
    src = os.path.join(walls, name)
    out = thumb_path(name)
    if name.lower().endswith(".gif"):
        cmd = ["magick", src + "[0]", "-resize", "480x270^", "-gravity", "center",
               "-extent", "480x270", "-quality", "85", "-strip", out]
    else:
        cmd = ["vipsthumbnail", src, "--size", "480x270", "--smartcrop", "centre",
               "-o", out + "[Q=85,strip]"]
    return subprocess.run(cmd, capture_output=True).returncode == 0 and os.path.exists(out)

def build_palette(name):
    src = os.path.join(walls, name)
    r = subprocess.run(["matugen", "-c", empty_cfg, "image", src, "--prefer", "saturation",
                        "--dry-run", "--json", "hex", "-q"], capture_output=True, text=True)
    try:
        colors = json.loads(r.stdout)["colors"]
        palette = {role: {"dark": v["dark"]["color"], "light": v["light"]["color"]}
                   for role, v in colors.items()}
    except (ValueError, KeyError):
        palette = None
    return palette

def save():
    tmp = index_path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(index, f, separators=(",", ":"))
    os.replace(tmp, index_path)

todo = [n for n in files if stale(n)]
new = sum(1 for n in todo if n not in index)

# Dos pasadas: primero todas las miniaturas (rapido; el indice se guarda al
# terminar, asi la galeria ya puede mostrar la grilla) y despues las paletas
# (matugen lee la imagen completa: la paleta de la miniatura no coincide).
with ThreadPoolExecutor(jobs) as ex:
    for name, ok in zip(todo, ex.map(build_thumb, todo)):
        st = os.stat(os.path.join(walls, name))
        old = index.get(name, {})
        index[name] = {"mtime": int(st.st_mtime), "size": st.st_size, "thumb": ok,
                       "colors": old.get("colors") if old.get("mtime") == int(st.st_mtime) else None}
save()
with ThreadPoolExecutor(jobs) as ex:
    for name, palette in zip(todo, ex.map(build_palette, todo)):
        index[name]["colors"] = palette

removed = [n for n in list(index) if n not in files]
for n in removed:
    index.pop(n, None)
    try:
        os.remove(thumb_path(n))
    except OSError:
        pass

save()

failed = [n for n, e in index.items() if not e.get("thumb") or not e.get("colors")]
print(f"{len(files)} wallpapers: {new} nuevos, {len(todo) - new} actualizados, "
      f"{len(removed)} eliminados, en {time.time() - t0:.1f} s"
      + (f"; con errores: {', '.join(failed)}" if failed else ""))
PY
