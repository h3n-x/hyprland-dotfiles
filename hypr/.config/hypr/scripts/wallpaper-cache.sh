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
# Color base (Fase 3 B8a): por cada imagen se guardan sus candidatos a semilla
# ("candidates", el dominante primero; filtro gaussian, como theme-apply.sh) y
# la paleta se calcula con las opciones EFECTIVAS de ese wallpaper (excepcion >
# preferencias globales de wallpapers.json > scheme-content / contraste 0) a
# partir de la semilla (`matugen color`, ~10 ms): la vista previa muestra lo
# mismo que dara aplicar. "opts" guarda con que opciones se calculo; si cambian
# (theme-apply.sh --prefs/--override) se recalcula solo la paleta.
#
# Salida: ~/.cache/dotfiles/wallpapers/{thumbs/,palettes.json}
#
# Formato real (KI-C24): se mira el contenido de cada archivo (primeros bytes)
# y se guarda en el indice ("format"). Avisa en stderr si la extension no
# coincide con el contenido (p. ej. un JPEG llamado .png) y si el formato no lo
# decodifica el Qt instalado (plugins de imageformats): la capa de wallpaper de
# Quickshell lo mostraria como color liso. Esto ultimo, ademas, con una
# notificacion la primera vez que aparece el archivo (WALLPAPER_CACHE_NOTIFY=0
# la desactiva, para pruebas).

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

# Una pasada a la vez (Fase 3 B8a): la galeria y theme-apply.sh --prefs/--override
# la lanzan en segundo plano, a veces varias seguidas. Si ya hay una corriendo,
# esta deja una marca y sale; la que corre repite al terminar con el estado nuevo
# (si no, pasadas en paralelo se pisaban el indice con datos viejos).
LOCK="$CACHE_DIR/.cache.lock"
PENDING="$CACHE_DIR/.cache.pending"
exec 9> "$LOCK"
if ! flock -n 9; then
  touch "$PENDING"
  echo "wallpaper-cache: ya hay una pasada en curso; se repite al terminar" >&2
  exit 0
fi

run_once() {
WALLPAPERS_DIR="$WALLPAPERS_DIR" CACHE_DIR="$CACHE_DIR" JOBS="$JOBS" FORCE="$FORCE" EMPTY_CFG="$EMPTY_CFG" \
NOTIFY="${WALLPAPER_CACHE_NOTIFY:-1}" QT_FORMATS_DIR="${QT_IMAGEFORMATS_DIR:-/usr/lib/qt6/plugins/imageformats}" \
STATE_FILE="${THEME_STATE_DIR:-$HOME/.local/state/dotfiles}/wallpapers.json" \
python3 - <<'PY'
import glob, json, os, re, shutil, subprocess, sys, time
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

# Estado anterior (para avisar solo la primera vez que aparece un archivo).
prev = {n: (e.get("mtime"), e.get("size")) for n, e in index.items()}

files = sorted(n for n in os.listdir(walls)
               if n.lower().endswith(exts) and os.path.isfile(os.path.join(walls, n)))

# Formato por contenido (no por extension).
def sniff(path):
    try:
        with open(path, "rb") as f:
            h = f.read(12)
    except OSError:
        return "desconocido"
    if h.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if h[:3] == b"\xff\xd8\xff":
        return "jpeg"
    if h[:4] == b"GIF8":
        return "gif"
    if h[:4] == b"RIFF" and h[8:12] == b"WEBP":
        return "webp"
    return "desconocido"

by_ext = {".png": "png", ".jpg": "jpeg", ".jpeg": "jpeg", ".webp": "webp", ".gif": "gif"}
# PNG viene dentro de Qt; el resto, segun los plugins instalados (libqjpeg.so...).
qt_formats = {"png"} | {re.sub(r"^libq|\.so$", "", os.path.basename(p))
                        for p in glob.glob(os.path.join(os.environ["QT_FORMATS_DIR"], "libq*.so"))}

def thumb_path(name):
    return os.path.join(thumbs, name + ".jpg")

def stale(name):
    st = os.stat(os.path.join(walls, name))
    e = index.get(name)
    return (force or e is None or e.get("mtime") != int(st.st_mtime) or e.get("size") != st.st_size
            or not os.path.exists(thumb_path(name)))

# Opciones efectivas (mismos valores por defecto que theme-apply.sh).
DEFAULT_SCHEME, DEFAULT_CONTRAST = "scheme-content", 0
try:
    with open(os.environ["STATE_FILE"]) as f:
        state = json.load(f)
except (OSError, ValueError):
    state = {}
prefs = state.get("prefs") or {}
overrides = state.get("overrides") or {}

def effective(name):
    e = index.get(name) or {}
    o = overrides.get(os.path.join(walls, name)) or {}
    cands = e.get("candidates") or []
    seed = o.get("seed") or (cands[0] if cands else None)
    if not seed:
        return None
    return {"seed": seed.lower(), "scheme": o.get("scheme") or prefs.get("scheme") or DEFAULT_SCHEME,
            "contrast": prefs.get("contrast") if prefs.get("contrast") is not None else DEFAULT_CONTRAST}

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

# Candidatos a semilla, el dominante primero (lista vacia si matugen fallo).
rank_re = re.compile(r"\] [0-9]+: (#[0-9a-fA-F]{6})")
def build_candidates(name):
    src = os.path.join(walls, name)
    r = subprocess.run(["matugen", "-c", empty_cfg, "image", src, "-r", "gaussian", "--prefer", "saturation",
                        "--dry-run", "-d"], capture_output=True, text=True)
    text = re.sub(r"\x1b\[[0-9;]*m", "", r.stdout + r.stderr)
    return [c.lower() for c in rank_re.findall(text)]

# Paleta a partir de la semilla (misma que da `matugen image` con esa semilla).
def build_palette(opts):
    r = subprocess.run(["matugen", "-c", empty_cfg, "color", "hex", opts["seed"], "-t", opts["scheme"],
                        "--contrast", str(opts["contrast"]), "--dry-run", "--json", "hex", "-q"],
                       capture_output=True, text=True)
    try:
        colors = json.loads(r.stdout)["colors"]
        return {role: {"dark": v["dark"]["color"], "light": v["light"]["color"]} for role, v in colors.items()}
    except (ValueError, KeyError):
        return None

def save():
    tmp = index_path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(index, f, separators=(",", ":"))
    os.replace(tmp, index_path)

todo = [n for n in files if stale(n)]
new = sum(1 for n in todo if n not in index)
formats = {n: sniff(os.path.join(walls, n)) for n in files}

# Dos pasadas: primero todas las miniaturas (rapido; el indice se guarda al
# terminar, asi la galeria ya puede mostrar la grilla) y despues las paletas
# (matugen lee la imagen completa: la paleta de la miniatura no coincide).
with ThreadPoolExecutor(jobs) as ex:
    for name, ok in zip(todo, ex.map(build_thumb, todo)):
        st = os.stat(os.path.join(walls, name))
        old = index.get(name, {})
        same = old.get("mtime") == int(st.st_mtime) and old.get("size") == st.st_size
        index[name] = {"mtime": int(st.st_mtime), "size": st.st_size, "thumb": ok,
                       "colors": old.get("colors") if same else None,
                       "opts": old.get("opts") if same else None}
        if same and "candidates" in old:
            index[name]["candidates"] = old["candidates"]
            index[name]["no_color"] = old.get("no_color", False)
for name in files:
    index[name]["format"] = formats[name]
save()
# Candidatos: archivos nuevos o cambiados, y los que todavia no los tienen
# (cache anterior a B8a) sin rehacer su miniatura.
need = [n for n in files if "candidates" not in index[n]]
with ThreadPoolExecutor(jobs) as ex:
    for name, cands in zip(need, ex.map(build_candidates, need)):
        index[name]["candidates"] = cands
        index[name]["no_color"] = cands == ["#4285f4"]

# Paletas: solo donde cambiaron las opciones efectivas (o no hay).
recolor = []
for name in files:
    eff = effective(name)
    if eff and (index[name].get("opts") != eff or not index[name].get("colors")):
        recolor.append((name, eff))
with ThreadPoolExecutor(jobs) as ex:
    for (name, eff), palette in zip(recolor, ex.map(build_palette, [e for _, e in recolor])):
        index[name]["colors"] = palette
        index[name]["opts"] = eff if palette else None

removed = [n for n in list(index) if n not in files]
for n in removed:
    index.pop(n, None)
    try:
        os.remove(thumb_path(n))
    except OSError:
        pass

save()

failed = [n for n, e in index.items() if not e.get("thumb") or not e.get("colors")]

# Avisos de formato (KI-C24).
mismatch = [n for n in files if formats[n] != by_ext[os.path.splitext(n)[1].lower()]]
unsupported = [n for n in files if formats[n] not in qt_formats]
if mismatch:
    kinds = {}
    for n in mismatch:
        kinds.setdefault(formats[n], []).append(n)
    for fmt, names in sorted(kinds.items()):
        print(f"aviso: {len(names)} con extension que no coincide (contenido {fmt}): {', '.join(names)}",
              file=sys.stderr)
if unsupported:
    print(f"aviso: {len(unsupported)} en un formato que el Qt instalado no decodifica "
          f"(la capa de wallpaper los mostraria como color liso): "
          + ", ".join(f"{n} ({formats[n]})" for n in unsupported), file=sys.stderr)
    def is_new(n):
        st = os.stat(os.path.join(walls, n))
        return prev.get(n) != (int(st.st_mtime), st.st_size)
    fresh = [n for n in unsupported if is_new(n)]
    if fresh and os.environ["NOTIFY"] != "0" and shutil.which("notify-send"):
        subprocess.run(["notify-send", "-i", "image-missing", "Wallpaper no compatible",
                        ", ".join(fresh) + ": formato que la shell no puede mostrar (convertir a PNG o JPEG)"],
                       capture_output=True)
print(f"{len(files)} wallpapers: {new} nuevos, {len(todo) - new} actualizados, "
      f"{len(removed)} eliminados, {len(recolor)} paletas recalculadas, en {time.time() - t0:.1f} s"
      + (f"; con errores: {', '.join(failed)}" if failed else ""))
PY
}

while :; do
  rm -f "$PENDING"
  run_once
  [ -e "$PENDING" ] || break
done
