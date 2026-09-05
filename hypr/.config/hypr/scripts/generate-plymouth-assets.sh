#!/bin/bash
# Genera los assets visuales del theme de Plymouth: el fondo (wallpaper actual
# con blur + oscurecido + vignette, mismo criterio que hyprlock.conf), el
# avatar (~/.face recortado en circulo -- la misma imagen "de usuario" que
# hyprlock, ver wallpaper-selector.sh) y los frames del spinner (arco
# circular de 270 grados, puntas redondeadas, rotando, tenido con el color
# primary de matugen). El anillo del spinner tiene el centro transparente a
# proposito -- ahi adentro va el avatar (ver plymouth.script, se dibujan
# superpuestos). post_hook del template
# matugen/.config/matugen/templates/plymouth.script (ver
# matugen/.config/matugen/config.toml) -- corre SIN sudo, todo el output va a
# la cache del usuario. sync-plymouth-theme.sh (root) es el que despues copia
# esto a /usr/share/plymouth/themes/.
set -euo pipefail

PRIMARY_HEX="${1:?uso: generate-plymouth-assets.sh <hex primary sin '#'> <path wallpaper>}"
WALLPAPER="${2:?uso: generate-plymouth-assets.sh <hex primary sin '#'> <path wallpaper>}"
OUT_DIR="$HOME/.cache/matugen/plymouth-theme"
mkdir -p "$OUT_DIR"

# Fondo: blur fuerte + oscurecido + vignette radial (multiply contra un
# gradiente blanco-a-negro) para que el spinner y el texto se lean bien
# encima sin importar que tan clara sea la zona del wallpaper. 1920x1080 fijo
# -- plymouth.script lo escala una sola vez al tamano real de pantalla al
# arrancar, y ya viene tan desenfocado que escalarlo no se nota.
magick "$WALLPAPER" -resize 1920x1080^ -gravity center -extent 1920x1080 \
  -blur 0x12 -brightness-contrast -25x-10 \
  \( -size 1920x1080 radial-gradient:white-black \) -compose multiply -composite \
  "$OUT_DIR/background.png"

# Avatar: ~/.face recortado en circulo, con margen para que quepa en el
# hueco transparente del anillo del spinner (anillo con radio interno ~55px
# -- ver SIZE/STROKE abajo -- asi que 100px de diametro deja aire de sobra).
AVATAR_SIZE=100
FACE="$HOME/.face"
if [ -f "$FACE" ]; then
  # Mascara: circulo blanco sobre negro (no sobre transparente) + -alpha off
  # asi CopyOpacity lee el nivel de gris de la mascara, no su propio canal
  # alpha -- version robusta de la receta, probada visualmente (la version
  # "mascara sobre xc:none" compuso mal: quedaba un cuadrado opaco en vez de
  # transparente afuera del circulo).
  magick "$FACE" -resize "${AVATAR_SIZE}x${AVATAR_SIZE}^" -gravity center -extent "${AVATAR_SIZE}x${AVATAR_SIZE}" -alpha set \
    \( -size "${AVATAR_SIZE}x${AVATAR_SIZE}" xc:black -fill white -draw "circle $((AVATAR_SIZE / 2)),$((AVATAR_SIZE / 2)) $((AVATAR_SIZE / 2)),0" -alpha off \) \
    -compose CopyOpacity -composite "$OUT_DIR/avatar.png"
else
  # Sin ~/.face todavia (nunca se corrio el selector de wallpaper) -- circulo
  # solido con el color primary como relleno de respaldo, para que
  # plymouth.script siempre tenga un avatar.png que cargar.
  magick -size "${AVATAR_SIZE}x${AVATAR_SIZE}" xc:none -fill "#${PRIMARY_HEX}" \
    -draw "circle $((AVATAR_SIZE / 2)),$((AVATAR_SIZE / 2)) $((AVATAR_SIZE / 2)),0" \
    "$OUT_DIR/avatar.png"
fi

SIZE=140
FRAMES=24
STROKE=10
MARGIN=$STROKE
X1=$MARGIN
Y1=$MARGIN
X2=$((SIZE - MARGIN))
Y2=$((SIZE - MARGIN))

for i in $(seq 0 $((FRAMES - 1))); do
  angle=$((i * 360 / FRAMES))
  magick -size "${SIZE}x${SIZE}" xc:none \
    -fill none -stroke "#${PRIMARY_HEX}" -strokewidth "$STROKE" \
    -draw "stroke-linecap round arc $X1,$Y1 $X2,$Y2 0,270" \
    -virtual-pixel transparent -distort SRT "$angle" \
    -background none -gravity center -extent "${SIZE}x${SIZE}" \
    "$OUT_DIR/frame${i}.png"
done
