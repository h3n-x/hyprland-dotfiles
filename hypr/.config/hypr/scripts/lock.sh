#!/bin/bash
# Wrapper de hyprlock: sonidos de bloqueo/desbloqueo/contrasena incorrecta.
# Reemplaza al "hyprlock" pelado en hypridle.conf (lock_cmd) y en el bind
# SUPER+L. Simplificado respecto al hyprlock_with_sounds.sh original de
# hypr-rice: sin servicio systemd aparte, sin journalctl, sin PID/log files
# -- todo vive y se limpia solo dentro de esta corrida.

# $HOME no siempre esta seteado en el entorno donde hypridle/hl.dsp.exec_cmd
# corren este script, asi que resolvemos la ruta desde la ubicacion real del
# script en vez de depender de el.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS="$SCRIPT_DIR/../sounds"

play() {
  command -v paplay >/dev/null 2>&1 && paplay "$SOUNDS/$1" >/dev/null 2>&1 &
}

# Evita relanzar si ya hay una instancia activa (mismo guard que hypridle.conf)
pidof hyprlock >/dev/null && exit 0

play lock.wav

# --grace 2: en hyprlock 0.9.x "grace" paso de ser opcion de config a flag
# de CLI. El patron de match es "Authentication failed" especifico (no un
# "*fail*" generico) porque hyprlock tambien imprime cosas como
# "fail_timeout does not exist" en los logs de config, que matchean
# cualquier "fail" ancho y disparan el sonido en falso.
hyprlock --grace 2 2>&1 | while IFS= read -r line; do
  [[ "$line" == *"Authentication failed"* ]] && play wrong.wav
done

play unlock.wav
