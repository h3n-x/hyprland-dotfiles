#!/bin/bash
# Genera los assets visuales del theme de GRUB: el fondo (wallpaper actual
# con blur + oscurecido + vignette, mismo criterio que Plymouth y el bloqueo),
# la tarjeta de 9 slices detras del boot_menu (menu_pixmap_style), el
# highlight de seleccion con franja de acento (selected_item_pixmap_style)
# y las esquinas decorativas. Ver
# matugen/.config/matugen/templates/grub-theme.txt para como se usan.
#
# NOTA: hubo un avatar circular (~/.face) con anillo de ticks y glow
# detras, en el centro de la pantalla. Se saco del todo -- el lector de
# PNG de GRUB nunca mostraba el contenido real de ese archivo especifico
# (cuadrado solido en pantalla) sea cual sea el formato/widget probado,
# algo especifico de decodificar PNG con canal alfa + foto compleja a la
# vez que no valia la pena seguir persiguiendo. Ver el historial de git de
# este archivo y de matugen/.config/matugen/templates/grub-theme.txt si en
# algun momento se quiere retomar esa investigacion.
#
# Independiente de generate-plymouth-assets.sh a proposito (mismo patron
# de fondo con blur, pero sin acoplar los dos themes entre si -- cada uno
# genera lo suyo). Corre SIN sudo, todo el output va a la cache del
# usuario. sync-grub-theme.sh (root) es el que despues copia esto a
# /boot/grub/themes/, y tambien mete el hostname real en theme.txt (ver
# el sed al final de este script -- matugen no tiene una variable de
# hostname, asi que se resuelve aca con shell real).
set -euo pipefail

usage="uso: generate-grub-assets.sh <primary> <tertiary> <on_primary> <surface_container> <outline_variant> <wallpaper> (colores hex SIN '#')"
PRIMARY_HEX="${1:?$usage}"
# tertiary, no secondary: en la paleta Material You de este rice secondary
# suele quedar muy parecido de tono a primary, y tertiary tiene un tono
# distinto (identidad decorativa, no un estado: P8.7) -- para que la franja de acento del
# item seleccionado se note de verdad hace falta contraste de color real,
# no solo de luminancia.
TERTIARY_HEX="${2:?$usage}"
ON_PRIMARY_HEX="${3:?$usage}"
SURFACE_CONTAINER_HEX="${4:?$usage}"
OUTLINE_VARIANT_HEX="${5:?$usage}"
WALLPAPER="${6:?$usage}"
OUT_DIR="$HOME/.cache/matugen/grub-theme"
mkdir -p "$OUT_DIR"

# Fondo: blur fuerte + oscurecido + vignette radial, igual que Plymouth --
# GRUB lo escala solo via "desktop-image-scale-method: stretch" en
# theme.txt, no hace falta generarlo a la resolucion real de pantalla.
magick "$WALLPAPER" -resize 1920x1080^ -gravity center -extent 1920x1080 \
  -blur 0x12 -brightness-contrast -25x-10 \
  \( -size 1920x1080 radial-gradient:white-black \) -compose multiply -composite \
  "$OUT_DIR/background.png"

# Esquinas decorativas: marca en "L" fina, tenida con outline_variant, en
# las 4 esquinas de la pantalla (generamos una y las espejamos) -- detalle
# de encuadre tipo HUD, sutil, no compite con el contenido.
CORNER_SIZE=48
CORNER_LEN=30
CORNER_THICK=2
magick -size "${CORNER_SIZE}x${CORNER_SIZE}" xc:none -fill "#${OUTLINE_VARIANT_HEX}99" \
  -draw "rectangle 0,0,${CORNER_THICK},${CORNER_LEN}" \
  -draw "rectangle 0,0,${CORNER_LEN},${CORNER_THICK}" \
  "$OUT_DIR/corner_tl.png"
magick "$OUT_DIR/corner_tl.png" -flop "$OUT_DIR/corner_tr.png"
magick "$OUT_DIR/corner_tl.png" -flip "$OUT_DIR/corner_bl.png"
magick "$OUT_DIR/corner_tl.png" -flip -flop "$OUT_DIR/corner_br.png"

# Tarjeta del boot_menu (menu_pixmap_style, styled box de 9 slices nativo
# de GRUB -- ver "Component List: boot_menu" en `info grub`): rectangulo
# redondeado tenido con surface_container + borde fino con
# outline_variant, mismo lenguaje "card" que el resto del rice
# (quickshell). GRUB estira cada slice para llenar el marco del menu, no
# hace falta generarlo al tamano real.
MENU_SCRATCH=200
MENU_CAP=28
# radius.lg x 1.5 (design system D4/Q4a): GRUB dibuja en px fisicos sin el
# escalado del escritorio. lg (panel) y no xl: con 36px el radio no entra en
# la pieza de MENU_CAP y agrandarla corre las entradas del menu hacia adentro.
MENU_RADIUS=24
magick -size "${MENU_SCRATCH}x${MENU_SCRATCH}" xc:none \
  -fill "#${SURFACE_CONTAINER_HEX}E3" \
  -draw "roundrectangle 0,0,$((MENU_SCRATCH - 1)),$((MENU_SCRATCH - 1)),${MENU_RADIUS},${MENU_RADIUS}" \
  -fill none -stroke "#${OUTLINE_VARIANT_HEX}80" -strokewidth 2 \
  -draw "roundrectangle 1,1,$((MENU_SCRATCH - 2)),$((MENU_SCRATCH - 2)),${MENU_RADIUS},${MENU_RADIUS}" \
  "$OUT_DIR/_menu_card.png"
MENU_MID=$(((MENU_SCRATCH - 8) / 2))
MENU_FAR=$((MENU_SCRATCH - MENU_CAP))
magick "$OUT_DIR/_menu_card.png" -crop "${MENU_CAP}x${MENU_CAP}+0+0" +repage "$OUT_DIR/menu_nw.png"
magick "$OUT_DIR/_menu_card.png" -crop "${MENU_CAP}x${MENU_CAP}+${MENU_FAR}+0" +repage "$OUT_DIR/menu_ne.png"
magick "$OUT_DIR/_menu_card.png" -crop "${MENU_CAP}x${MENU_CAP}+0+${MENU_FAR}" +repage "$OUT_DIR/menu_sw.png"
magick "$OUT_DIR/_menu_card.png" -crop "${MENU_CAP}x${MENU_CAP}+${MENU_FAR}+${MENU_FAR}" +repage "$OUT_DIR/menu_se.png"
magick "$OUT_DIR/_menu_card.png" -crop "8x${MENU_CAP}+${MENU_MID}+0" +repage "$OUT_DIR/menu_n.png"
magick "$OUT_DIR/_menu_card.png" -crop "8x${MENU_CAP}+${MENU_MID}+${MENU_FAR}" +repage "$OUT_DIR/menu_s.png"
magick "$OUT_DIR/_menu_card.png" -crop "${MENU_CAP}x8+0+${MENU_MID}" +repage "$OUT_DIR/menu_w.png"
magick "$OUT_DIR/_menu_card.png" -crop "${MENU_CAP}x8+${MENU_FAR}+${MENU_MID}" +repage "$OUT_DIR/menu_e.png"
magick "$OUT_DIR/_menu_card.png" -crop "8x8+${MENU_MID}+${MENU_MID}" +repage "$OUT_DIR/menu_c.png"
rm -f "$OUT_DIR/_menu_card.png"

# Highlight de seleccion del boot_menu: "pill" redondeada con relleno
# solido (mucho mas opaco que antes: F0 no CC) + franja de acento en
# secondary sobre el borde izquierdo (clipeada al mismo contorno
# redondeado via CopyOpacity, no un rectangulo suelto) + borde fino con
# on_primary para que el limite quede nitido. selected_item_pixmap_style
# en theme.txt espera 3 slices (GRUB las junta solo): west/center/east.
SEL_H=42
SEL_CAP=20
SEL_SCRATCH_W=200
SEL_RADIUS=12
SEL_ACCENT_W=7
magick -size "${SEL_SCRATCH_W}x${SEL_H}" xc:black -fill white \
  -draw "roundrectangle 0,0,$((SEL_SCRATCH_W - 1)),$((SEL_H - 1)),${SEL_RADIUS},${SEL_RADIUS}" \
  -alpha off "$OUT_DIR/_sel_mask.png"
magick -size "${SEL_SCRATCH_W}x${SEL_H}" xc:none \
  -fill "#${TERTIARY_HEX}" -draw "rectangle 0,0,${SEL_ACCENT_W},$((SEL_H - 1))" \
  -fill "#${PRIMARY_HEX}F0" -draw "rectangle ${SEL_ACCENT_W},0,$((SEL_SCRATCH_W - 1)),$((SEL_H - 1))" \
  "$OUT_DIR/_sel_color.png"
magick "$OUT_DIR/_sel_color.png" "$OUT_DIR/_sel_mask.png" \
  -compose CopyOpacity -composite "$OUT_DIR/_sel_pill.png"
magick "$OUT_DIR/_sel_pill.png" -fill none -stroke "#${ON_PRIMARY_HEX}66" -strokewidth 1.5 \
  -draw "roundrectangle 1,1,$((SEL_SCRATCH_W - 2)),$((SEL_H - 2)),${SEL_RADIUS},${SEL_RADIUS}" \
  "$OUT_DIR/_sel_pill_final.png"
magick "$OUT_DIR/_sel_pill_final.png" -crop "${SEL_CAP}x${SEL_H}+0+0" +repage "$OUT_DIR/select_w.png"
magick "$OUT_DIR/_sel_pill_final.png" -crop "${SEL_CAP}x${SEL_H}+$((SEL_SCRATCH_W - SEL_CAP))+0" +repage "$OUT_DIR/select_e.png"
magick "$OUT_DIR/_sel_pill_final.png" -crop "8x${SEL_H}+$((SEL_SCRATCH_W / 2 - 4))+0" +repage "$OUT_DIR/select_c.png"
rm -f "$OUT_DIR/_sel_mask.png" "$OUT_DIR/_sel_color.png" "$OUT_DIR/_sel_pill.png" "$OUT_DIR/_sel_pill_final.png"

# GRUB (grub-core/video/readers/png.c) solo soporta PNG de 8 o 16 bits
# por canal -- probado en vivo: "error: video/readers/png.c:
# grub_png_decode_image_header:310:png: bit depth must be 8 or 16".
# ImageMagick optimiza los PNG chicos con pocos colores o casi todo
# transparente (marcas de esquina, slices del menu/seleccion) a un
# bit depth menor (1/2/4) para ahorrar espacio -- cualquier visor normal
# lo banca perfecto, pero el lector de PNG minimalista de GRUB no.
#
# OJO: esto se probo primero con un mogrify a TODOS los .png del
# directorio (incluyendo background.png) y lo rompio -- forzar
# color-type=6 sobre una imagen fotografica (que ImageMagick ya guarda
# valida, en 8-bit PseudoClass) le altera los datos de color de forma
# impredecible. Por eso esto SOLO toca los PNG "de interfaz" (silueta
# solida o casi transparente, pocos colores) que son los unicos con riesgo
# real de bit depth invalido -- el fondo queda afuera a proposito, tal
# cual lo escribio ImageMagick antes.
magick mogrify -depth 8 -define png:color-type=6 -define png:bit-depth=8 \
  "$OUT_DIR"/corner_*.png "$OUT_DIR"/menu_*.png "$OUT_DIR"/select_*.png

# theme.txt ya lo escribio matugen en este mismo directorio (es su
# output_path) justo antes de correr este post_hook -- le mete el
# hostname real aca (matugen no tiene esa variable, pero este script SI
# tiene shell real). __HOSTNAME__ es un placeholder literal puesto en el
# template. El binario "hostname" (paquete inetutils) no esta instalado
# en este equipo -- /etc/hostname siempre existe en un sistema systemd,
# es la fuente mas portable.
if [ -f "$OUT_DIR/theme.txt" ]; then
  HOSTNAME_VALUE="$(cat /etc/hostname 2>/dev/null || hostnamectl --static 2>/dev/null || echo arch)"
  sed -i "s/__HOSTNAME__/${HOSTNAME_VALUE}/" "$OUT_DIR/theme.txt"
fi
