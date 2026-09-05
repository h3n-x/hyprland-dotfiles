#!/bin/bash
# Genera los assets visuales del theme de GRUB: el fondo (wallpaper actual
# con blur + oscurecido + vignette, mismo criterio que Plymouth/hyprlock),
# el avatar (~/.face recortado en circulo, va como center_bitmap del
# +circular_progress en theme.txt) y un tick chico tenido con primary (se
# repite alrededor del circulo, tick_bitmap). Ver
# matugen/.config/matugen/templates/grub-theme.txt para como se usan.
#
# Independiente de generate-plymouth-assets.sh a proposito (mismo patron
# de recorte de avatar, pero sin acoplar los dos themes entre si -- cada
# uno genera lo suyo). Corre SIN sudo, todo el output va a la cache del
# usuario. sync-grub-theme.sh (root) es el que despues copia esto a
# /boot/grub/themes/.
set -euo pipefail

PRIMARY_HEX="${1:?uso: generate-grub-assets.sh <hex primary sin '#'> <path wallpaper>}"
WALLPAPER="${2:?uso: generate-grub-assets.sh <hex primary sin '#'> <path wallpaper>}"
OUT_DIR="$HOME/.cache/matugen/grub-theme"
mkdir -p "$OUT_DIR"

# Fondo: blur fuerte + oscurecido + vignette radial, igual que Plymouth --
# GRUB lo escala solo via "desktop-image-scale-method: stretch" en
# theme.txt, no hace falta generarlo a la resolucion real de pantalla.
magick "$WALLPAPER" -resize 1920x1080^ -gravity center -extent 1920x1080 \
  -blur 0x12 -brightness-contrast -25x-10 \
  \( -size 1920x1080 radial-gradient:white-black \) -compose multiply -composite \
  "$OUT_DIR/background.png"

# Avatar: ~/.face recortado en circulo -- va de center_bitmap del
# +circular_progress. Mascara sobre negro (no sobre transparente) + -alpha
# off: la version "mascara sobre xc:none" compone mal en este ImageMagick
# (queda un cuadrado opaco en vez de transparente afuera del circulo,
# encontrado debuggeando el mismo problema en Plymouth).
AVATAR_SIZE=140
FACE="$HOME/.face"
if [ -f "$FACE" ]; then
  magick "$FACE" -resize "${AVATAR_SIZE}x${AVATAR_SIZE}^" -gravity center -extent "${AVATAR_SIZE}x${AVATAR_SIZE}" -alpha set \
    \( -size "${AVATAR_SIZE}x${AVATAR_SIZE}" xc:black -fill white -draw "circle $((AVATAR_SIZE / 2)),$((AVATAR_SIZE / 2)) $((AVATAR_SIZE / 2)),0" -alpha off \) \
    -compose CopyOpacity -composite "$OUT_DIR/avatar.png"
else
  # Sin ~/.face todavia (nunca se corrio el selector de wallpaper) -- circulo
  # solido con el color primary como relleno de respaldo.
  magick -size "${AVATAR_SIZE}x${AVATAR_SIZE}" xc:none -fill "#${PRIMARY_HEX}" \
    -draw "circle $((AVATAR_SIZE / 2)),$((AVATAR_SIZE / 2)) $((AVATAR_SIZE / 2)),0" \
    "$OUT_DIR/avatar.png"
fi

# Tick: puntito solido tenido con primary, se repite num_ticks veces
# alrededor del circulo (ver theme.txt) -- GRUB lo va ocultando de a uno a
# medida que pasa el countdown (ticks_disappear).
TICK_SIZE=12
magick -size "${TICK_SIZE}x${TICK_SIZE}" xc:none -fill "#${PRIMARY_HEX}" \
  -draw "circle $((TICK_SIZE / 2)),$((TICK_SIZE / 2)) $((TICK_SIZE / 2)),1" \
  "$OUT_DIR/tick.png"

# Highlight de selección del boot_menu: "pill" redondeada semi-transparente
# tenida con primary (estilo Material You), en vez del resaltado plano por
# defecto de GRUB. selected_item_pixmap_style = "select_*.png" en theme.txt
# espera 3 slices (GRUB las junta solo): west/center/east -- se generan
# recortando un rectangulo redondeado mas ancho, no a mano cada slice.
SEL_H=36
SEL_CAP=18
SEL_SCRATCH_W=200
SEL_RADIUS=10
magick -size "${SEL_SCRATCH_W}x${SEL_H}" xc:none -fill "#${PRIMARY_HEX}CC" \
  -draw "roundrectangle 0,0,$((SEL_SCRATCH_W - 1)),$((SEL_H - 1)),$SEL_RADIUS,$SEL_RADIUS" \
  "$OUT_DIR/_select_pill.png"
magick "$OUT_DIR/_select_pill.png" -crop "${SEL_CAP}x${SEL_H}+0+0" +repage "$OUT_DIR/select_w.png"
magick "$OUT_DIR/_select_pill.png" -crop "${SEL_CAP}x${SEL_H}+$((SEL_SCRATCH_W - SEL_CAP))+0" +repage "$OUT_DIR/select_e.png"
magick "$OUT_DIR/_select_pill.png" -crop "8x${SEL_H}+$((SEL_SCRATCH_W / 2 - 4))+0" +repage "$OUT_DIR/select_c.png"
rm -f "$OUT_DIR/_select_pill.png"
