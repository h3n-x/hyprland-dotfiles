#!/bin/bash

# Punto de entrada unico para aplicar un tema (wallpaper + paleta), Fase 3 B0.
# Lo llaman la galeria (aplicar, favoritos, etiquetas, opciones de color),
# deshacer (SUPER+SHIFT+Z, IPC) y la linea de comandos.
#
#   theme-apply.sh <wallpaper> [--scheme <tipo>] [--contrast <-1..1>]
#                  [--source gallery|undo|ipc|settings] [--dry-run] [--no-system]
#   theme-apply.sh --flush-system   (corre ya el trabajo de sistema pendiente)
#   theme-apply.sh --favorite <wallpaper> on|off|toggle   (galeria, Fase 3 B3)
#   theme-apply.sh --tag <wallpaper> add|remove <etiqueta>  (galeria, Fase 3 B4)
#   theme-apply.sh --undo [--no-notify] [--dry-run]   (tema anterior del historial, B5)
#   theme-apply.sh --backend quickshell|hyprpaper|status   (quien dibuja el wallpaper, B6)
#   theme-apply.sh --face [--dry-run]   (rehace ~/.face con el avatar elegido, Fase 10 B2)
#   theme-apply.sh --system   (agenda la pasada del sistema con el tema actual: el idioma, Fase 15 B3)
#   theme-apply.sh --reapply [--source settings|ipc] [--force] [--dry-run]   (el tema actual en el modo del almacen, P5.5;
#                  --force: aunque el modo no cambie, para las opciones de colores de codigo, Fase 18)
#   theme-apply.sh --override <wallpaper> seed <#hex>|scheme <tipo>|reset   (excepcion por wallpaper, B8a;
#                  "default" en seed o scheme quita solo ese campo, B8b)
#
# Una sola aplicacion a la vez: cada llamada deja su pedido en un archivo (el
# ultimo pisa al anterior) y solo un proceso "worker", protegido con flock,
# los aplica en orden. Si elegis varios wallpapers seguidos se aplica solo el
# ultimo y nunca corren dos matugen a la vez (KI-S11).
#
# ~/.face se genera ANTES de matugen: el hook de Plymouth lo usa como avatar
# (KI-S1). Sale del wallpaper o de la imagen propia (appearance.avatar*,
# Fase 10 B2; esquema y contraste globales se eligen en el centro de
# configuracion, appearance.scheme/contrast).
# Estado e historial: ~/.local/state/dotfiles/wallpapers.json (fuera del repo).
#
# Dos velocidades (Fase 3 B2): matugen corre al instante con config.toml (lo
# que se ve en la sesion); los temas de arranque/login (config-system.toml:
# SDDM, Plymouth, GRUB) quedan como trabajo pendiente y un "debouncer" los
# regenera una sola vez, 60 s despues del ultimo cambio. Cada cambio nuevo
# reemplaza el pendiente. Si la sesion termina antes, autostart.lua corre
# --flush-system al iniciar la siguiente.
#
# Wallpaper (Fase 3 B6): por defecto lo dibuja Quickshell (modules/Wallpaper.qml,
# con fundido) leyendo la imagen del JSON de colores, asi que aca no hay nada
# que hacer. Vuelta atras: --backend hyprpaper arranca hyprpaper y oculta la
# capa de Quickshell; la eleccion queda en prefs.wallpaper_backend.
# current-wallpaper.conf se escribe siempre: hyprpaper arranca con el correcto.
#
# Color base (Fase 3 B8a, KI-L12): matugen propone hasta 4 colores semilla por
# imagen; se usa el DOMINANTE (el primero de su ranking, con el filtro de
# reduccion gaussian, estable ante el decodificador) en vez del mas saturado.
# Opciones efectivas de cada aplicacion = excepcion del wallpaper (semilla,
# esquema) > opciones globales appearance.scheme/appearance.contrast del
# almacen (P8.7; sus valores de fabrica viven en el esquema de opciones). La semilla sale de los candidatos que guarda
# wallpaper-cache.sh (o se calcula si el archivo no esta en la cache). Todo se
# resuelve al PEDIR y viaja en el pedido y el historial: deshacer restaura el
# tema exacto. Entradas viejas sin semilla ("legacy") se aplican como antes
# (--prefer saturation, tonal-spot).
#
# Modo claro u oscuro (P5.5): appearance.colorMode del almacen, resuelto al
# PEDIR como el resto ("auto": la luminancia del wallpaper, con una banda
# muerta) y guardado en el pedido y el historial. Pasa a palette (estado y codigo) y a
# matugen (-m) y al escritorio por gsettings (GTK, libadwaita, portales, iconos;
# KI-S13): theme-apply escribe gsettings, nunca lo lee. Cambiar solo el modo
# (--reapply) reaplica el tema actual sin la pasada de sistema: arranque y
# login son siempre oscuros (D-P55-3), con su propio status-system.json.
#
# --dry-run no ejecuta hyprctl, magick ni matugen: solo registra lo que haria
# (para pruebas; usar THEME_STATE_DIR/THEME_LOG_DIR para no tocar el estado
# real, THEME_SYSTEM_DELAY para acortar la espera). --no-system no agenda la
# pasada de sistema.

set -uo pipefail

SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"
# Mensajes en el idioma del usuario (Fase 15 B4; el log sigue en espanol).
i18n_tr() { "$SCRIPTS_DIR/i18n" tr "$@"; }
STATE_DIR="${THEME_STATE_DIR:-$HOME/.local/state/dotfiles}"
STATE="$STATE_DIR/wallpapers.json"
# Toda escritura del estado (aplicar, favoritos) pasa por este lock: la
# galeria y un cambio de wallpaper nunca se pisan la actualizacion.
STATE_LOCK="$STATE_DIR/wallpapers.json.lock"
REQUEST="$STATE_DIR/theme-apply.request"
LOCK="$STATE_DIR/theme-apply.lock"
SYSTEM_PENDING="$STATE_DIR/system.pending"
SYSTEM_LOCK="$STATE_DIR/theme-system.lock"
SYSTEM_CFG="$HOME/.config/matugen/config-system.toml"
# Colores de estado de la pasada de sistema (siempre oscura): archivo propio,
# asi una pasada de sesion en claro nunca le pisa los suyos ni al reves.
SYSTEM_STATUS="${XDG_CACHE_HOME:-$HOME/.cache}/matugen/status-system.json"
SYSTEM_DELAY="${THEME_SYSTEM_DELAY:-60}"
LOG_DIR="${THEME_LOG_DIR:-$HOME/.cache/dotfiles}"
LOG="$LOG_DIR/theme-apply.log"
CURRENT_CONF="$HOME/.config/hypr/current-wallpaper.conf"
HISTORY_MAX=50
LOG_MAX=500
# Solo en --dry-run: cuanto "tarda" la aplicacion simulada (probar la cola).
DRY_DELAY="${THEME_DRY_DELAY:-1}"

CACHE_DIR="${WALLPAPER_CACHE_DIR:-$HOME/.cache/dotfiles/wallpapers}"
CACHE_INDEX="$CACHE_DIR/palettes.json"
# Opciones globales de color: las lee y escribe solo el motor de opciones.
SETTINGS="$SCRIPTS_DIR/settings"
# Colores de estado fijos (P8.7) y paleta de codigo (Fase 18): palette los deja en los JSON que
# importan las configs de matugen (import_json_files) antes de cada corrida (la de sistema, solo
# el estado: palette status).
PALETTE="$SCRIPTS_DIR/palette"
COLORS_JSON="${XDG_CACHE_HOME:-$HOME/.cache}/matugen/quickshell-colors.json"
RULE="dominante"
# Color de respaldo de matugen: si es el unico candidato, la imagen no tiene un
# color claro y la semilla puede ser cualquier color (colores predefinidos, B8h).
MATUGEN_FALLBACK="#4285f4"

# Esquemas validos: los del esquema de opciones (una sola lista).
SCHEMA="${SETTINGS_SCHEMA:-$HOME/.config/quickshell/dotshell/data/settings.schema.json}"
SCHEMES="$(jq -r '.keys["appearance.scheme"].values | keys | join(" ")' "$SCHEMA" 2>/dev/null)"

mkdir -p "$STATE_DIR" "$LOG_DIR"

log() {
  printf '%s [%s] %s\n' "$(date '+%F %T.%3N')" "$$" "$*" >> "$LOG"
}

die() {
  echo "theme-apply: $*" >&2
  log "ERROR $*"
  exit 1
}

usage() {
  i18n_tr "theme-apply.sh <wallpaper> [--scheme <type>] [--contrast <-1..1>]
               [--source gallery|undo|ipc|settings] [--dry-run] [--no-system]
theme-apply.sh --flush-system   (runs the pending system work now)
theme-apply.sh --favorite <wallpaper> on|off|toggle   (gallery, Phase 3 B3)
theme-apply.sh --tag <wallpaper> add|remove <tag>  (gallery, Phase 3 B4)
theme-apply.sh --undo [--no-notify] [--dry-run]   (previous theme in the history, B5)
theme-apply.sh --backend quickshell|hyprpaper|status   (who draws the wallpaper, B6)
theme-apply.sh --face [--dry-run]   (remakes ~/.face with the chosen avatar, Phase 10 B2)
theme-apply.sh --system   (schedules the system pass with the current theme: the language, Phase 15 B3)
theme-apply.sh --reapply [--source settings|ipc] [--force] [--dry-run]   (the current theme in the store's mode, P5.5)
theme-apply.sh --override <wallpaper> seed <#hex>|scheme <type>|reset   (per-wallpaper exception, B8a;
               \"default\" in seed or scheme removes only that field, B8b)" >&2
  exit 2
}

# ---- Estado ---------------------------------------------------------------

# Estado inicial a partir del wallpaper que ya esta aplicado, asi el
# historial arranca desde lo que hay hoy.
with_state_lock() { # comando... (bloqueante)
  (
    flock 7
    "$@"
  ) 7> "$STATE_LOCK"
}

init_state() { with_state_lock _init_state; }
_init_state() {
  [ -s "$STATE" ] && jq -e . "$STATE" >/dev/null 2>&1 && return 0
  local wp=""
  [ -f "$CURRENT_CONF" ] && wp=$(awk -F'= *' '/^[[:space:]]*path[[:space:]]*=/ {print $2; exit}' "$CURRENT_CONF")
  jq -n --arg wp "$wp" --arg now "$(date -Iseconds)" '
    ($wp | if . == "" then null else {wallpaper: ., scheme: null, contrast: null,
      mode: "dark", applied_at: $now, source: "inicial"} end) as $cur
    | {version: 1, current: $cur, history: (if $cur then [$cur] else [] end),
       favorites: [], tags: {}, prefs: {}}' > "$STATE.tmp" \
    && mv "$STATE.tmp" "$STATE"
}

record_apply() { with_state_lock _record_apply "$@"; }
# Historial (Fase 3 B5): si el tope ya es este mismo tema (wallpaper, esquema,
# contraste, semilla y modo) solo se refresca su fecha en vez de agregar una entrada
# (decision B5d). Cubre tambien el deshacer: --undo ya saco la entrada
# deshecha, asi que el tema restaurado es el tope. Si no, se agrega arriba.
_record_apply() { # wallpaper scheme contrast source seed rule mode
  jq --arg wp "$1" --arg scheme "$2" --arg contrast "$3" --arg source "$4" --arg seed "${5:-}" --arg rule "${6:-legacy}" \
     --arg mode "${7:-dark}" \
     --arg now "$(date -Iseconds)" --argjson max "$HISTORY_MAX" '
    {wallpaper: $wp,
     scheme: (if $scheme == "" then null else $scheme end),
     contrast: (if $contrast == "" then null else ($contrast | tonumber) end),
     seed: (if $seed == "" then null else $seed end), rule: $rule,
     mode: $mode, applied_at: $now, source: $source} as $e
    | (.history // []) as $h
    | def same($a; $b): $a != null and $b != null and $a.wallpaper == $b.wallpaper
                        and $a.scheme == $b.scheme and $a.contrast == $b.contrast
                        and ($a.seed // null) == ($b.seed // null) and ($a.rule // "legacy") == ($b.rule // "legacy")
                        and ($a.mode // "dark") == ($b.mode // "dark");
    if ($h | length) > 0 and same($h[0]; $e) then
      .history = ([$h[0] + {applied_at: $now}] + $h[1:])
      | .current = .history[0]
    else
      .current = $e
      | .history = ([$e] + $h)[:$max]
    end' "$STATE" > "$STATE.tmp" \
    && mv "$STATE.tmp" "$STATE"
}

# Backend del wallpaper: "quickshell" (defecto, tambien sin estado) o "hyprpaper".
wallpaper_backend() {
  local b
  b="$(jq -r '.prefs.wallpaper_backend // "quickshell"' "$STATE" 2>/dev/null)"
  [ "$b" = hyprpaper ] && echo hyprpaper || echo quickshell
}

# ---- Opciones efectivas (Fase 3 B8a) --------------------------------------

# Candidatos (semillas) de un wallpaper: de la cache si el archivo no cambio;
# si no, matugen los calcula (mismo comando que wallpaper-cache.sh).
candidates_of() { # wallpaper -> una semilla por linea, la dominante primero
  local wp="$1" name mt sz
  name="$(basename "$wp")"; mt="$(stat -c %Y "$wp")"; sz="$(stat -c %s "$wp")"
  if [ -s "$CACHE_INDEX" ] && jq -e --arg n "$name" --argjson m "$mt" --argjson s "$sz" \
       '.[$n] | .mtime == $m and .size == $s and ((.candidates // []) | length) > 0' "$CACHE_INDEX" >/dev/null 2>&1; then
    jq -r --arg n "$name" '.[$n].candidates[]' "$CACHE_INDEX"
    return
  fi
  local cfg="$CACHE_DIR/.matugen-empty.toml"
  [ -f "$cfg" ] || { mkdir -p "$CACHE_DIR"; printf '[config]\n\n[templates]\n' > "$cfg"; }
  matugen -c "$cfg" image "$wp" -r gaussian --prefer saturation --dry-run -d 2>&1 \
    | sed 's/\x1b\[[0-9;]*m//g' | grep -oE '\] [0-9]+: #[0-9a-fA-F]{6}' | awk '{print tolower($3)}'
}

# Opciones efectivas: argumento > excepcion del wallpaper > opcion global.
resolve_opts() { # wallpaper scheme contrast seed -> "scheme contrast seed"
  local wp="$1" scheme="$2" contrast="$3" seed="$4" ov
  ov="$(jq -c --arg wp "$wp" '.overrides[$wp] // {}' "$STATE" 2>/dev/null || echo '{}')"
  [ -n "$scheme" ] || scheme="$(jq -r '.scheme // empty' <<< "$ov")"
  [ -n "$scheme" ] || scheme="$("$SETTINGS" get appearance.scheme)"
  [ -n "$contrast" ] || contrast="$("$SETTINGS" get appearance.contrast)"
  [ -n "$seed" ] || seed="$(jq -r '.seed // empty' <<< "$ov")"
  [ -n "$seed" ] || seed="$(candidates_of "$wp" | head -1)"
  [ -n "$seed" ] || seed="$MATUGEN_FALLBACK"
  echo "$scheme $contrast ${seed,,}"
}

# Luminancia de un wallpaper (P5.5): L media OKLab (0..1) de la cache de la
# galeria si el archivo no cambio; si no, se mide sobre una copia chica.
luma_of() { # wallpaper -> numero (vacio si no se pudo)
  local wp="$1" name mt sz
  name="$(basename "$wp")"; mt="$(stat -c %Y "$wp")"; sz="$(stat -c %s "$wp")"
  if [ -s "$CACHE_INDEX" ] && jq -e --arg n "$name" --argjson m "$mt" --argjson s "$sz" \
       '.[$n] | .mtime == $m and .size == $s and .luma != null' "$CACHE_INDEX" >/dev/null 2>&1; then
    jq -r --arg n "$name" '.[$n].luma' "$CACHE_INDEX"
    return
  fi
  magick "${wp}[0]" -resize 480x270 -colorspace OkLab -channel R -separate +channel -format '%[fx:mean]' info: 2>/dev/null
}

# Modo efectivo: appearance.colorMode; con "auto", claro sobre autoLight,
# oscuro bajo autoDark y en el medio el del tema actual (sin saltos entre
# fondos parecidos). Los umbrales viven en el esquema (los lee tambien la
# vista previa de la galeria).
resolve_mode() { # wallpaper -> dark|light
  local m cur lo hi l
  m="$("$SETTINGS" get appearance.colorMode 2>/dev/null)"
  case "$m" in
    dark|light) echo "$m"; return ;;
    auto) ;;
    *) echo dark; return ;;
  esac
  cur="$(jq -r '.current.mode // "dark"' "$STATE" 2>/dev/null)"
  read -r lo hi < <(jq -r '.keys["appearance.colorMode"] | "\(.autoDark) \(.autoLight)"' "$SCHEMA")
  l="$(luma_of "$1")"
  if [ -z "$l" ]; then echo "${cur:-dark}"; return; fi
  awk -v l="$l" -v lo="$lo" -v hi="$hi" -v cur="${cur:-dark}" 'BEGIN { print (l > hi) ? "light" : (l < lo) ? "dark" : cur }'
}

# Escritorio en el modo (P5.5, KI-S13): GTK 3 (gtk-theme), libadwaita y los
# portales (color-scheme) e iconos (el tema de settings.ini o su hermano claro,
# scripts/icon-theme). settings.ini ya no fija tema ni oscuro: el unico dueno es esto.
desktop_mode() { # dark|light
  command -v gsettings >/dev/null 2>&1 || { log "  modo: falta gsettings"; return 0; }
  local scheme gtk icons
  # GTK3 (Thunar, pavucontrol...): adw-gtk3 lee los colores de libadwaita que deja la plantilla
  # gtk.css; el Adwaita de GTK3 los ignora y dibuja con los suyos (Fase 19). Sin adw-gtk3, Adwaita.
  local base=Adwaita d
  for d in "${XDG_DATA_HOME:-$HOME/.local/share}/themes" "$HOME/.themes" /usr/share/themes; do
    [ -d "$d/adw-gtk3" ] && { base=adw-gtk3; break; }
  done
  if [ "$1" = light ]; then scheme=prefer-light gtk=$base; else scheme=prefer-dark gtk=$base-dark; fi
  if [ "$DRY" = true ]; then
    icons="$("$SCRIPTS_DIR/icon-theme" "$1" --dry-run 2>> "$LOG")"
  else
    icons="$("$SCRIPTS_DIR/icon-theme" "$1" 2>> "$LOG")"
  fi
  run gsettings set org.gnome.desktop.interface color-scheme "$scheme"
  run gsettings set org.gnome.desktop.interface gtk-theme "$gtk"
  [ -z "$icons" ] || run gsettings set org.gnome.desktop.interface icon-theme "$icons"
}

# ---- Aplicacion -----------------------------------------------------------

# Avatar (Fase 10 B2): recorte cuadrado de 512 al centro del wallpaper
# ("Del fondo", lo de siempre) o de la imagen propia. De un GIF, el primer
# cuadro. Si la imagen propia no se puede leer, ~/.face queda como estaba
# (nunca se cambia en silencio por el wallpaper) y sale con 1.
make_face() { # wallpaper
  command -v magick >/dev/null 2>&1 || { log "avatar: falta magick"; return 1; }
  local src="$1"
  if [ "$("$SETTINGS" get appearance.avatar 2>/dev/null)" = image ]; then
    src="$("$SETTINGS" get appearance.avatarImage 2>/dev/null)"
    if [ ! -r "$src" ] || ! magick identify "$src[0]" >/dev/null 2>&1; then
      log "avatar: no se puede leer la imagen propia: $src (~/.face sin cambios)"
      return 1
    fi
  fi
  case "${src,,}" in *.gif) src="${src}[0]" ;; esac
  run magick "$src" -auto-orient -gravity center -resize 512x512^ -extent 512x512 "$HOME/.face.tmp.png" >/dev/null 2>&1 \
    && run mv -f "$HOME/.face.tmp.png" "$HOME/.face"
}

run() { # comando... (en --dry-run solo se registra)
  if [ "$DRY" = true ]; then
    log "  dry: $*"
  else
    "$@"
  fi
}

apply() { # wallpaper scheme contrast source no_system seed rule mode
  local wp="$1" scheme="$2" contrast="$3" source="$4" no_system="${5:-false}" seed="${6:-}" rule="${7:-legacy}" mode="${8:-dark}" t0 rc
  t0=$(date +%s%N)
  log "aplicar: $wp (esquema=${scheme:-defecto} contraste=${contrast:-defecto} semilla=${seed:-?} regla=$rule modo=$mode origen=$source)$([ "$DRY" = true ] && echo " [dry-run]")"

  # 1. Wallpaper. Con Quickshell lo cambia la shell al leer el JSON de colores
  #    (paso 4), junto con la paleta. Con hyprpaper, por IPC (0.8.x solo
  #    expone "wallpaper" y "listactive").
  if [ "$(wallpaper_backend)" = hyprpaper ]; then
    run hyprctl hyprpaper wallpaper ",$wp" >/dev/null
  fi

  # 2. Persistir para el proximo arranque (hyprpaper.conf hace source de esto).
  if [ "$DRY" = true ]; then
    log "  dry: escribir $CURRENT_CONF"
  else
    cat > "$CURRENT_CONF" <<EOF
wallpaper {
    monitor =
    path = $wp
    fit_mode = cover
}
EOF
  fi

  # 3. ~/.face (avatar del bloqueo, del greeter y de Plymouth) ANTES de
  #    matugen: el hook de Plymouth lo lee; antes corrian en paralelo (KI-S1).
  make_face "$wp" || true

  # 4. Paleta y plantillas, con las opciones ya resueltas al pedir (B8a). Antes,
  #    los colores de estado fijos para este contraste (P8.7); sin ellos matugen
  #    no puede renderizar (import_json_files).
  local args
  mapfile -t args < <(matugen_args "$wp" "$scheme" "$contrast" "$seed" "$rule" "$mode")
  # Paleta de codigo (Fase 18) y colores de estado en un solo paso: con la misma semilla, esquema,
  # contraste y modo (temas viejos sin semilla: desde la imagen); matugen importa los dos JSON.
  local code_src=(--image "$wp")
  [ "${rule:-legacy}" != legacy ] && [ -n "$seed" ] && code_src=(--seed "$seed")
  [ -n "$scheme" ] && code_src+=(--scheme "$scheme")
  if [ "$DRY" = true ]; then
    log "  dry: palette code ${code_src[*]} --mode $mode --contrast ${contrast:-0} --write (+ estado)"
    log "  dry: matugen ${args[*]}"
    sleep "$DRY_DELAY"
    rc=0
  elif command -v matugen >/dev/null 2>&1; then
    "$PALETTE" code "${code_src[@]}" --mode "$mode" --contrast "${contrast:-0}" --write 2>> "$LOG"
    matugen "${args[@]}" >/dev/null 2>&1
    rc=$?
  else
    rc=127
  fi
  # GTK, portales e iconos, despues de las plantillas (gtk.css ya en el modo).
  [ "$rc" = 0 ] && desktop_mode "$mode"

  # El estado e historial se escriben al PEDIR, no aca (Fase 3 B5): si no, un
  # deshacer pedido mientras se aplicaba un tema operaba sobre un historial
  # viejo, y un destino intermedio de varios deshacer seguidos volvia a
  # entrar arriba al terminar de aplicarse.
  log "listo: matugen rc=$rc en $(( ($(date +%s%N) - t0) / 1000000 )) ms"

  # 5. Validacion del sistema de color sobre la paleta nueva (P8.7): solo queda
  #    en el log, nunca frena una aplicacion.
  if [ "$DRY" != true ] && [ "$rc" = 0 ]; then
    "$PALETTE" check --palette "$COLORS_JSON" --quiet 2>&1 | sed 's/^/  palette: /' >> "$LOG"
  fi

  # 6. Temas de arranque/login, diferidos.
  [ "$no_system" = true ] || schedule_system "$wp" "$scheme" "$contrast" "$seed" "$rule"
}

# ---- Pasada de sistema (SDDM, Plymouth, GRUB), diferida -------------------

matugen_args() { # wallpaper scheme contrast seed rule mode -> argumentos de matugen image
  local a
  if [ "${5:-legacy}" = legacy ]; then
    # Como antes de B8a: el candidato mas saturado (temas del historial viejo).
    a=(image "$1" --prefer saturation)
    [ -n "$2" ] && a+=(-t "$2")
    [ -n "$3" ] && a+=(--contrast "$3")
  else
    # La semilla elegida: closest-to-fallback con ella como respaldo elige
    # exactamente ese candidato (o la usa tal cual si la imagen no tiene color).
    a=(image "$1" -t "$2" --contrast "$3" -r gaussian --prefer closest-to-fallback --fallback-color "$4")
  fi
  a+=(-m "${6:-dark}")
  printf '%s\n' "${a[@]}"
}

schedule_system() { # wallpaper scheme contrast seed rule
  local token
  token="$(date +%s%N)"
  jq -n --arg wp "$1" --arg scheme "$2" --arg contrast "$3" --arg seed "${4:-}" --arg rule "${5:-legacy}" \
        --arg token "$token" --argjson dry "$DRY" \
    '{wallpaper: $wp, scheme: $scheme, contrast: $contrast, seed: $seed, rule: $rule, token: $token, dry: $dry}' \
    > "$SYSTEM_PENDING.tmp" && mv "$SYSTEM_PENDING.tmp" "$SYSTEM_PENDING"
  log "sistema: pendiente en ${SYSTEM_DELAY} s (token $token)"
  setsid -f "$SCRIPTS_DIR/$(basename "$0")" --system-run "$token" < /dev/null > /dev/null 2>&1
}

run_system() { # token esperado ("" = el que haya pendiente)
  exec 8> "$SYSTEM_LOCK"
  flock 8
  [ -s "$SYSTEM_PENDING" ] || { log "sistema: nada pendiente"; return 0; }
  local job token
  job="$(cat "$SYSTEM_PENDING")"
  token="$(jq -r .token <<< "$job")"
  if [ -n "$1" ] && [ "$1" != "$token" ]; then
    log "sistema: token $1 reemplazado por uno mas nuevo, se omite"
    return 0
  fi
  local wp scheme contrast seed rule t0 rc
  wp="$(jq -r .wallpaper <<< "$job")"; scheme="$(jq -r .scheme <<< "$job")"; contrast="$(jq -r .contrast <<< "$job")"
  seed="$(jq -r '.seed // ""' <<< "$job")"; rule="$(jq -r '.rule // "legacy"' <<< "$job")"
  DRY="$(jq -r .dry <<< "$job")"
  local args
  # Siempre oscura (D-P55-3): arranque y login no cambian con el modo.
  mapfile -t args < <(matugen_args "$wp" "$scheme" "$contrast" "$seed" "$rule" dark)
  t0=$(date +%s%N)
  log "sistema: aplicar $wp$([ "$DRY" = true ] && echo " [dry-run]")"
  if [ "$DRY" = true ]; then
    log "  dry: palette status --mode dark --contrast ${contrast:-0} --write ($SYSTEM_STATUS)"
    log "  dry: matugen -c $SYSTEM_CFG ${args[*]}"
    log "  dry: sddm-theme-stage && sudo -n /usr/local/bin/sync-sddm-theme"
    rc=0
  else
    PALETTE_STATUS_OUT="$SYSTEM_STATUS" "$PALETTE" status --mode dark --contrast "${contrast:-0}" --write 2>> "$LOG"
    matugen -c "$SYSTEM_CFG" "${args[@]}" >/dev/null 2>&1
    rc=$?
    # El greeter (Fase 9 B3): se arma como el usuario despues de que matugen
    # termino (no escribe en orden, KI-C2) y la copia root lo instala. Plymouth
    # y GRUB sincronizan desde sus propios post_hook.
    "$SCRIPTS_DIR/sddm-theme-stage" 2>> "$LOG" || log "sistema: sddm-theme-stage fallo"
    sudo -n /usr/local/bin/sync-sddm-theme >/dev/null 2>&1 || log "sistema: sync-sddm-theme fallo o no hay regla sudoers"
  fi
  # Solo se borra si nadie agendo otro mientras tanto.
  if [ "$(jq -r .token "$SYSTEM_PENDING" 2>/dev/null)" = "$token" ]; then rm -f "$SYSTEM_PENDING"; fi
  log "sistema: listo rc=$rc en $(( ($(date +%s%N) - t0) / 1000000 )) ms"
}

# ---- Cola (ultimo pedido gana) --------------------------------------------

take_request() { # imprime el pedido pendiente y lo consume; 1 si no hay
  [ -s "$REQUEST" ] || return 1
  mv "$REQUEST" "$REQUEST.taken" 2>/dev/null || return 1
  cat "$REQUEST.taken"
  rm -f "$REQUEST.taken"
}

worker() {
  while :; do
    exec 9> "$LOCK"
    if ! flock -n 9; then
      # Otro worker esta aplicando: tomara este pedido al terminar.
      log "worker: ya hay uno activo, se deja el pedido en cola"
      exit 0
    fi
    local req
    while req=$(take_request); do
      DRY=$(jq -r '.dry' <<< "$req")
      apply "$(jq -r '.wallpaper' <<< "$req")" \
            "$(jq -r '.scheme // ""' <<< "$req")" \
            "$(jq -r '.contrast // "" | tostring' <<< "$req")" \
            "$(jq -r '.source' <<< "$req")" \
            "$(jq -r '.no_system // false' <<< "$req")" \
            "$(jq -r '.seed // ""' <<< "$req")" \
            "$(jq -r '.rule // "legacy"' <<< "$req")" \
            "$(jq -r '.mode // "dark"' <<< "$req")"
    done
    flock -u 9
    exec 9>&-
    # Un pedido que llego justo despues de soltar el lock no se pierde.
    [ -s "$REQUEST" ] || break
  done
  # Log acotado.
  if [ "$(wc -l < "$LOG")" -gt "$LOG_MAX" ]; then
    tail -n "$LOG_MAX" "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
  fi
}

# ---- Entrada --------------------------------------------------------------

if [ "${1:-}" = "--worker" ]; then
  init_state
  worker
  exit 0
fi
if [ "${1:-}" = "--system-run" ]; then
  sleep "$SYSTEM_DELAY"
  run_system "${2:-}"
  exit 0
fi
if [ "${1:-}" = "--flush-system" ]; then
  run_system ""
  exit 0
fi
# Avatar elegido en el centro de configuracion (Fase 10 B2): ~/.face ya (el
# bloqueo lo lee directo) y, con el tema actual, la pasada del sistema
# (greeter y Plymouth) agendada como siempre: 60 s, el ultimo gana.
# Idioma (Fase 15 B3): el greeter y el pie de GRUB lo toman en la pasada del
# sistema; con el tema actual, agendada como siempre (60 s, el ultimo gana).
if [ "${1:-}" = "--face" ] || [ "${1:-}" = "--system" ]; then
  DRY=false; [ "${2:-}" = --dry-run ] && DRY=true
  init_state
  cur="$(jq -c '.current // empty' "$STATE")"
  cwp="$(jq -r '.wallpaper // empty' <<< "$cur")"
  [ -n "$cwp" ] || die "$(i18n_tr "%1: no theme applied yet" "${1#--}")"
  if [ "$1" = "--face" ]; then
    make_face "$cwp" || die "$(i18n_tr "avatar: couldn't remake ~/.face (see the log)")"
    log "avatar: ~/.face rehecho"
  fi
  schedule_system "$cwp" "$(jq -r '.scheme // ""' <<< "$cur")" "$(jq -r '.contrast // ""' <<< "$cur")" \
    "$(jq -r '.seed // ""' <<< "$cur")" "$(jq -r '.rule // "legacy"' <<< "$cur")"
  exit 0
fi
# Solo el modo (P5.5): el tema actual tal cual (wallpaper, esquema, contraste,
# semilla) en el modo efectivo de ahora; nada si ya esta en ese modo. Lo llama
# settings-apply al cambiar appearance.colorMode. Sin pasada de sistema.
if [ "${1:-}" = "--reapply" ]; then
  DRY=false rsource=settings rforce=false
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --source) rsource="${2:-}"; shift 2 ;;
      --force) rforce=true; shift ;;
      --dry-run) DRY=true; shift ;;
      *) die "$(i18n_tr "unknown option for %1: %2" --reapply "$1")" ;;
    esac
  done
  case "$rsource" in settings|ipc) ;; *) die "$(i18n_tr "unknown source: %1" "$rsource")" ;; esac
  init_state
  cur="$(jq -c '.current // empty' "$STATE")"
  cwp="$(jq -r '.wallpaper // empty' <<< "$cur")"
  [ -n "$cwp" ] && [ -f "$cwp" ] || { log "reaplicar: no hay un tema aplicado"; exit 0; }
  rmode="$(resolve_mode "$cwp")"
  if [ "$rforce" != true ] && [ "$rmode" = "$(jq -r '.mode // "dark"' <<< "$cur")" ]; then
    log "reaplicar: el tema actual ya esta en modo $rmode"
    exit 0
  fi
  rscheme="$(jq -r '.scheme // ""' <<< "$cur")"; rcontrast="$(jq -r '.contrast // "" | tostring' <<< "$cur")"
  rseed="$(jq -r '.seed // ""' <<< "$cur")"; rrule="$(jq -r '.rule // "legacy"' <<< "$cur")"
  record_apply "$cwp" "$rscheme" "$rcontrast" "$rsource" "$rseed" "$rrule" "$rmode"
  jq -n --arg wp "$cwp" --arg scheme "$rscheme" --arg contrast "$rcontrast" --arg seed "$rseed" --arg rule "$rrule" \
        --arg mode "$rmode" --arg source "$rsource" --argjson dry "$DRY" \
    '{wallpaper: $wp, scheme: $scheme, contrast: $contrast, seed: $seed, rule: $rule, mode: $mode, source: $source,
      dry: $dry, no_system: true}' \
    > "$REQUEST.$$" && mv "$REQUEST.$$" "$REQUEST"
  log "reaplicar: $cwp en modo $rmode (origen=$rsource)"
  setsid -f "$SCRIPTS_DIR/$(basename "$0")" --worker < /dev/null > /dev/null 2>&1
  exit 0
fi
if [ "${1:-}" = "--favorite" ]; then
  [ $# -eq 3 ] || usage
  fav="$(readlink -f -- "$2")"
  [ -f "$fav" ] || die "$(i18n_tr "it doesn't exist: %1" "$2")"
  case "$3" in on|off|toggle) ;; *) die "$(i18n_tr "favorite: use %1" "on|off|toggle")" ;; esac
  init_state
  _set_favorite() {
    jq --arg wp "$fav" --arg op "$3" '
      (.favorites // []) as $f
      | ($f | index($wp)) as $i
      | .favorites = (if ($op == "on" or ($op == "toggle" and $i == null))
                      then (if $i == null then $f + [$wp] else $f end)
                      else ($f | map(select(. != $wp))) end)' "$STATE" > "$STATE.tmp" \
      && mv "$STATE.tmp" "$STATE"
  }
  with_state_lock _set_favorite "$@"
  log "favorito: $3 $fav"
  exit 0
fi
if [ "${1:-}" = "--undo" ]; then
  notify_undo=true undo_dry=false
  for a in "${@:2}"; do
    case "$a" in
      --no-notify) notify_undo=false ;;
      --dry-run) undo_dry=true ;;
      *) die "$(i18n_tr "unknown option for %1: %2" --undo "$a")" ;;
    esac
  done
  init_state
  # Saca la entrada actual del historial y salta las que apuntan a archivos
  # que ya no existen; el nuevo tope es el tema a restaurar. Todo bajo el lock
  # del estado, al momento del pedido: varios deshacer seguidos retroceden un
  # paso cada uno y la cola aplica solo el ultimo destino.
  _pop_history() {
    local hist n k wp
    hist="$(jq -c '.history // []' "$STATE")"
    n="$(jq 'length' <<< "$hist")"
    k=1
    while [ "$k" -lt "$n" ]; do
      wp="$(jq -r ".[$k].wallpaper" <<< "$hist")"
      [ -f "$wp" ] && break
      log "deshacer: se salta $wp (no existe)"
      k=$((k + 1))
    done
    [ "$k" -lt "$n" ] || return 1
    jq --argjson k "$k" '.history = .history[$k:] | .current = .history[0]' "$STATE" > "$STATE.tmp" \
      && mv "$STATE.tmp" "$STATE"
  }
  if ! with_state_lock _pop_history; then
    log "deshacer: nada que deshacer"
    [ "$notify_undo" = true ] && command -v notify-send >/dev/null 2>&1 \
      && notify-send "$("$SCRIPTS_DIR/i18n" tr "Theme")" "$("$SCRIPTS_DIR/i18n" tr "There's nothing to undo")" -i edit-undo -t 2500
    exit 0
  fi
  target="$(jq -c '.history[0]' "$STATE")"
  twp="$(jq -r .wallpaper <<< "$target")"
  jq -n --argjson e "$target" \
    '{wallpaper: $e.wallpaper, scheme: $e.scheme, contrast: ($e.contrast | if . == null then null else tostring end),
      seed: ($e.seed // null), rule: ($e.rule // "legacy"), mode: ($e.mode // "dark"),
      source: "undo", dry: $dry, no_system: false}' --argjson dry "$undo_dry" \
    > "$REQUEST.$$" && mv "$REQUEST.$$" "$REQUEST"
  log "deshacer: pedido de $twp"
  # El modo restaurado vuelve tambien al almacen (salvo "auto"): si no, el
  # proximo wallpaper saldria en el modo deshecho. El --reapply que dispara
  # el cambio no hace nada: el tema actual ya es el restaurado.
  tmode="$(jq -r '.mode // "dark"' <<< "$target")"
  smode="$("$SETTINGS" get appearance.colorMode 2>/dev/null)"
  if [ "$undo_dry" != true ] && [ "$smode" != auto ] && [ "$smode" != "$tmode" ]; then
    "$SETTINGS" set appearance.colorMode "$tmode" >/dev/null 2>> "$LOG" || log "deshacer: no se pudo volver el modo a $tmode"
  fi
  [ "$notify_undo" = true ] && command -v notify-send >/dev/null 2>&1 \
    && notify-send "$("$SCRIPTS_DIR/i18n" tr "Theme")" "$("$SCRIPTS_DIR/i18n" tr "Undone: %1" "$(basename "$twp")")" -i edit-undo -t 2500
  setsid -f "$SCRIPTS_DIR/$(basename "$0")" --worker < /dev/null > /dev/null 2>&1
  exit 0
fi
if [ "${1:-}" = "--backend" ]; then
  [ $# -eq 2 ] || usage
  case "$2" in quickshell|hyprpaper|status) ;; *) die "$(i18n_tr "backend: use %1" "quickshell|hyprpaper|status")" ;; esac
  init_state
  if [ "$2" = status ]; then
    wallpaper_backend
    exit 0
  fi
  # Espera (max ~3 s) a que una capa con ese namespace este (1) o no (0) mapeada.
  wait_layer() { # namespace 1|0
    local i
    for i in $(seq 30); do
      if hyprctl layers -j 2>/dev/null | jq -e --arg ns "$1" \
           '[.. | objects | select(.namespace? == $ns)] | length > 0' >/dev/null; then
        [ "$2" = 1 ] && return 0
      else
        [ "$2" = 0 ] && return 0
      fi
      sleep 0.1
    done
    return 1
  }
  _set_backend() {
    jq --arg b "$1" '.prefs = ((.prefs // {}) + {wallpaper_backend: $b})' "$STATE" > "$STATE.tmp" \
      && mv "$STATE.tmp" "$STATE"
  }
  # El orden evita ver el fondo liso en el cambio: el que entra se dibuja
  # antes de que se vaya el otro.
  if [ "$2" = hyprpaper ]; then
    if ! pgrep -x hyprpaper >/dev/null; then
      setsid -f hyprpaper < /dev/null > /dev/null 2>&1
      wait_layer hyprpaper 1 || log "backend: hyprpaper no mapeo su capa a tiempo"
      sleep 1.5 # que dibuje y termine la animacion de entrada de su capa
    fi
    with_state_lock _set_backend hyprpaper
  else
    with_state_lock _set_backend quickshell
    if pgrep -x hyprpaper >/dev/null; then
      wait_layer quickshell-wallpaper 1 || log "backend: la capa de Quickshell no aparecio a tiempo"
      sleep 1.5 # decodificar la imagen (hasta ~1 s) y dibujarla
      pkill -x hyprpaper
      for _ in $(seq 20); do pgrep -x hyprpaper >/dev/null || break; sleep 0.1; done
    fi
  fi
  log "backend: $2"
  exit 0
fi
if [ "${1:-}" = "--tag" ]; then
  [ $# -eq 4 ] || usage
  twp="$(readlink -f -- "$2")"
  [ -f "$twp" ] || die "$(i18n_tr "it doesn't exist: %1" "$2")"
  case "$3" in add|remove) ;; *) die "$(i18n_tr "tag: use %1" "add|remove")" ;; esac
  # Formato (decision B4c): minusculas, sin espacios en los bordes, espacios
  # internos -> "-", maximo 24 caracteres. ${t,,} respeta el locale (acentos).
  tag="${4,,}"
  tag="$(printf '%s' "$tag" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/-/g')"
  tag="${tag:0:24}"
  [ -n "$tag" ] || die "$(i18n_tr "empty tag")"
  init_state
  _set_tag() {
    jq --arg wp "$twp" --arg op "$3" --arg tag "$tag" '
      .tags = (.tags // {})
      | .tags[$wp] = ((.tags[$wp] // []) as $t
                      | if $op == "add" then ($t + [$tag] | unique) else ($t | map(select(. != $tag))) end)
      | if (.tags[$wp] | length) == 0 then del(.tags[$wp]) else . end' "$STATE" > "$STATE.tmp" \
      && mv "$STATE.tmp" "$STATE"
  }
  with_state_lock _set_tag "$@"
  log "etiqueta: $3 \"$tag\" $twp"
  exit 0
fi

# Excepciones por wallpaper (Fase 3 B8a). Tras cada cambio se refresca la cache: la galeria y la vista previa muestran la paleta
# con las opciones nuevas (y aplicar da lo mismo que la vista previa).
refresh_cache() {
  setsid -f "$SCRIPTS_DIR/wallpaper-cache.sh" < /dev/null > /dev/null 2>&1
}
if [ "${1:-}" = "--override" ]; then
  [ $# -ge 3 ] || usage
  owp="$(readlink -f -- "$2")"
  [ -f "$owp" ] || die "$(i18n_tr "it doesn't exist: %1" "$2")"
  init_state
  # "default": quitar solo ese campo (y la excepcion entera si queda vacia).
  if [ "${4:-}" = default ] && { [ "$3" = seed ] || [ "$3" = scheme ]; }; then
    _set_override() {
      jq --arg wp "$owp" --arg k "$3" '.overrides = (.overrides // {})
        | .overrides[$wp] = ((.overrides[$wp] // {}) | del(.[$k]))
        | if (.overrides[$wp] | length) == 0 then .overrides |= del(.[$wp]) else . end' "$STATE" > "$STATE.tmp" \
        && mv "$STATE.tmp" "$STATE"
    }
    with_state_lock _set_override "$@"
    log "override: $owp $3 predeterminado"
    refresh_cache
    exit 0
  fi
  case "$3" in
    seed)
      [ $# -eq 4 ] || usage
      [[ "$4" =~ ^#[0-9a-fA-F]{6}$ ]] || die "$(i18n_tr "invalid seed (#rrggbb): %1" "$4")"
      oseed="${4,,}"
      # Tiene que ser uno de los candidatos de la imagen (matugen elige el mas
      # cercano: otro color no daria lo mismo en la vista previa y al aplicar),
      # salvo que la imagen no tenga color (solo el de respaldo): ahi vale
      # cualquiera (colores predefinidos, B8h).
      mapfile -t cands < <(candidates_of "$owp")
      if ! { [ "${#cands[@]}" -eq 1 ] && [ "${cands[0]}" = "$MATUGEN_FALLBACK" ]; }; then
        printf '%s\n' "${cands[@]}" | grep -qx "$oseed" || die "$(i18n_tr "the seed isn't a candidate of the image: %1 (candidates: %2)" "$oseed" "${cands[*]}")"
      fi
      _set_override() { jq --arg wp "$owp" --arg v "$oseed" '.overrides = (.overrides // {}) | .overrides[$wp] = ((.overrides[$wp] // {}) + {seed: $v})' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"; } ;;
    scheme)
      [ $# -eq 4 ] || usage
      [[ " $SCHEMES " == *" $4 "* ]] || die "$(i18n_tr "unknown scheme: %1" "$4")"
      _set_override() { jq --arg wp "$owp" --arg v "$4" '.overrides = (.overrides // {}) | .overrides[$wp] = ((.overrides[$wp] // {}) + {scheme: $v})' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"; } ;;
    reset)
      _set_override() { jq --arg wp "$owp" '.overrides = ((.overrides // {}) | del(.[$wp]))' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"; } ;;
    *) die "$(i18n_tr "override: use %1" "seed <#hex>|scheme <type>|reset")" ;;
  esac
  with_state_lock _set_override "$@"
  log "override: $owp ${*:3}"
  refresh_cache
  exit 0
fi

wallpaper="" scheme="" contrast="" seed="" source="ipc" DRY=false NO_SYSTEM=false
while [ $# -gt 0 ]; do
  case "$1" in
    --scheme)   scheme="${2:-}"; shift 2 ;;
    --seed)     seed="${2:-}"; shift 2 ;;
    --contrast) contrast="${2:-}"; shift 2 ;;
    --source)   source="${2:-}"; shift 2 ;;
    --dry-run)  DRY=true; shift ;;
    --no-system) NO_SYSTEM=true; shift ;;
    -h|--help)  usage ;;
    -*)         die "$(i18n_tr "unknown option: %1" "$1")" ;;
    *)          [ -z "$wallpaper" ] || die "$(i18n_tr "more than one wallpaper")"; wallpaper="$1"; shift ;;
  esac
done

[ -n "$wallpaper" ] || usage
[ -f "$wallpaper" ] || die "$(i18n_tr "it doesn't exist: %1" "$wallpaper")"
wallpaper="$(readlink -f -- "$wallpaper")"
case "${wallpaper,,}" in
  *.png|*.jpg|*.jpeg|*.webp|*.gif) ;;
  *) die "$(i18n_tr "unsupported format: %1" "$wallpaper")" ;;
esac
if [ -n "$scheme" ]; then
  [[ " $SCHEMES " == *" $scheme "* ]] || die "$(i18n_tr "unknown scheme: %1" "$scheme")"
fi
if [ -n "$contrast" ]; then
  awk -v c="$contrast" 'BEGIN { exit !(c ~ /^-?[0-9]*\.?[0-9]+$/ && c >= -1 && c <= 1) }' \
    || die "$(i18n_tr "contrast out of range (-1..1): %1" "$contrast")"
fi
case "$source" in gallery|undo|ipc|settings) ;; *) die "$(i18n_tr "unknown source: %1" "$source")" ;; esac
if [ -n "$seed" ]; then
  [[ "$seed" =~ ^#[0-9a-fA-F]{6}$ ]] || die "$(i18n_tr "invalid seed (#rrggbb): %1" "$seed")"
fi

# Opciones efectivas (B8a), resueltas una vez: viajan en el pedido y el historial.
init_state
read -r scheme contrast seed <<< "$(resolve_opts "$wallpaper" "$scheme" "$contrast" "$seed")"
mode="$(resolve_mode "$wallpaper")"

# Historial al pedir (bajo el lock del estado): refleja la intencion aunque la
# aplicacion todavia este en cola; "Actual" se ve al instante en la galeria.
record_apply "$wallpaper" "$scheme" "$contrast" "$source" "$seed" "$RULE" "$mode"

# Pedido atomico: el ultimo en escribirse gana.
jq -n --arg wp "$wallpaper" --arg scheme "$scheme" --arg contrast "$contrast" --arg seed "$seed" --arg rule "$RULE" \
      --arg mode "$mode" --arg source "$source" --argjson dry "$DRY" --argjson no_system "$NO_SYSTEM" \
  '{wallpaper: $wp, scheme: $scheme, contrast: $contrast, seed: $seed, rule: $rule, mode: $mode, source: $source, dry: $dry,
    no_system: $no_system}' \
  > "$REQUEST.$$" && mv "$REQUEST.$$" "$REQUEST"
log "pedido: $wallpaper (origen=$source esquema=$scheme contraste=$contrast semilla=$seed modo=$mode)"

# Worker desacoplado: el atajo de teclado vuelve al instante.
setsid -f "$SCRIPTS_DIR/$(basename "$0")" --worker < /dev/null > /dev/null 2>&1
exit 0
