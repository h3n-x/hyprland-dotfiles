#!/bin/bash
# Recolorea las carpetas de Papirus-Dark al color primario generado por
# matugen. papirus-folders solo acepta un set fijo de nombres de color (no
# hex arbitrario), asi que este script mapea el hex al mas cercano por tono
# (HSV hue), usando python3/colorsys (sin dependencias extra).
#
# Requiere una copia LOCAL del tema en ~/.local/share/icons/Papirus-Dark
# (ver README) para que papirus-folders no necesite sudo en cada corrida.

set -euo pipefail

HEX="${1:-}"
[ -n "$HEX" ] || { echo "uso: recolor-icons.sh <hex sin #>" >&2; exit 1; }

command -v papirus-folders >/dev/null 2>&1 || exit 0

COLOR=$(python3 - "$HEX" <<'PYEOF'
import colorsys, sys

hex_color = sys.argv[1].lstrip("#")
r, g, b = (int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4))
h, s, v = colorsys.rgb_to_hsv(r, g, b)

# Colores disponibles en Papirus-Dark (ver folder-<nombre>-documents.svg),
# con un hex representativo tomado de cada icono.
palette = {
    "blue": "5294e2", "red": "e25252", "green": "87b158", "yellow": "f9bd30",
    "orange": "ee923a", "pink": "f06292", "violet": "7e57c2", "cyan": "00bcd4",
    "magenta": "ca71df", "teal": "16a085", "indigo": "5c6bc0", "brown": "ae8e6c",
    "bluegrey": "607d8b", "breeze": "57b8ec", "carmine": "a30002",
    "darkcyan": "45abb7", "deeporange": "eb6637", "nordic": "81a1c1",
    "palebrown": "d1bfae", "paleorange": "eeca8f",
}

# Colores casi sin saturacion (grises/pasteles muy lavados) -> grey directo,
# matchear por tono ahi da resultados random.
if s < 0.12:
    print("grey")
    sys.exit(0)

def hue(hx):
    pr, pg, pb = (int(hx[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return colorsys.rgb_to_hsv(pr, pg, pb)[0]

def hue_dist(h1, h2):
    d = abs(h1 - h2)
    return min(d, 1 - d)

best = min(palette, key=lambda name: hue_dist(h, hue(palette[name])))
print(best)
PYEOF
)

papirus-folders -C "$COLOR" -t Papirus-Dark --once >/dev/null 2>&1 || true
