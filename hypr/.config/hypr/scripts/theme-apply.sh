#!/bin/bash

# Punto de entrada unico para aplicar un tema (wallpaper + paleta), Fase 3 B0.
# Lo llaman el selector de rofi y, mas adelante, la galeria, deshacer y la IPC.
#
#   theme-apply.sh <wallpaper> [--scheme <tipo>] [--contrast <-1..1>]
#                  [--source rofi|gallery|undo|ipc] [--dry-run] [--no-system]
#   theme-apply.sh --flush-system   (corre ya el trabajo de sistema pendiente)
#   theme-apply.sh --favorite <wallpaper> on|off|toggle   (galeria, Fase 3 B3)
#   theme-apply.sh --tag <wallpaper> add|remove <etiqueta>  (galeria, Fase 3 B4)
#
# Una sola aplicacion a la vez: cada llamada deja su pedido en un archivo (el
# ultimo pisa al anterior) y solo un proceso "worker", protegido con flock,
# los aplica en orden. Si elegis varios wallpapers seguidos se aplica solo el
# ultimo y nunca corren dos matugen a la vez (KI-S11).
#
# Los pasos son los mismos que hacia wallpaper-selector.sh, con ~/.face
# generado ANTES de matugen: el hook de Plymouth lo usa como avatar (KI-S1).
# Estado e historial: ~/.local/state/dotfiles/wallpapers.json (fuera del repo).
#
# Dos velocidades (Fase 3 B2): matugen corre al instante con config.toml (lo
# que se ve en la sesion); los temas de arranque/login (config-system.toml:
# SDDM, Plymouth, GRUB) quedan como trabajo pendiente y un "debouncer" los
# regenera una sola vez, 60 s despues del ultimo cambio. Cada cambio nuevo
# reemplaza el pendiente. Si la sesion termina antes, autostart.lua corre
# --flush-system al iniciar la siguiente.
#
# --dry-run no ejecuta hyprctl, magick ni matugen: solo registra lo que haria
# (para pruebas; usar THEME_STATE_DIR/THEME_LOG_DIR para no tocar el estado
# real, THEME_SYSTEM_DELAY para acortar la espera). --no-system no agenda la
# pasada de sistema.

set -uo pipefail

SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"
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
SYSTEM_DELAY="${THEME_SYSTEM_DELAY:-60}"
LOG_DIR="${THEME_LOG_DIR:-$HOME/.cache/dotfiles}"
LOG="$LOG_DIR/theme-apply.log"
CURRENT_CONF="$HOME/.config/hypr/current-wallpaper.conf"
HISTORY_MAX=50
LOG_MAX=500
# Solo en --dry-run: cuanto "tarda" la aplicacion simulada (probar la cola).
DRY_DELAY="${THEME_DRY_DELAY:-1}"

SCHEMES="scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot scheme-vibrant scheme-smart"

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
  sed -n '6,10p' "$0" | sed 's/^# \{0,3\}//' >&2
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
       favorites: [], tags: {}, prefs: {scheme: null, contrast: null}}' > "$STATE.tmp" \
    && mv "$STATE.tmp" "$STATE"
}

record_apply() { with_state_lock _record_apply "$@"; }
_record_apply() { # wallpaper scheme contrast source
  jq --arg wp "$1" --arg scheme "$2" --arg contrast "$3" --arg source "$4" \
     --arg now "$(date -Iseconds)" --argjson max "$HISTORY_MAX" '
    {wallpaper: $wp,
     scheme: (if $scheme == "" then null else $scheme end),
     contrast: (if $contrast == "" then null else ($contrast | tonumber) end),
     mode: "dark", applied_at: $now, source: $source} as $e
    | .current = $e
    | .history = ([$e] + (.history // []))[:$max]' "$STATE" > "$STATE.tmp" \
    && mv "$STATE.tmp" "$STATE"
}

# ---- Aplicacion -----------------------------------------------------------

run() { # comando... (en --dry-run solo se registra)
  if [ "$DRY" = true ]; then
    log "  dry: $*"
  else
    "$@"
  fi
}

apply() { # wallpaper scheme contrast source no_system
  local wp="$1" scheme="$2" contrast="$3" source="$4" no_system="${5:-false}" t0 rc
  t0=$(date +%s%N)
  log "aplicar: $wp (esquema=${scheme:-defecto} contraste=${contrast:-defecto} origen=$source)$([ "$DRY" = true ] && echo " [dry-run]")"

  # 1. Wallpaper (hyprpaper 0.8.x solo expone "wallpaper" y "listactive" por IPC).
  run hyprctl hyprpaper wallpaper ",$wp" >/dev/null

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

  # 3. ~/.face (avatar de hyprlock y Plymouth) ANTES de matugen: el hook de
  #    Plymouth lo lee; antes corrian en paralelo (KI-S1). De un GIF, el
  #    primer cuadro.
  if command -v magick >/dev/null 2>&1; then
    local src="$wp"
    case "${wp,,}" in *.gif) src="${wp}[0]" ;; esac
    run magick "$src" -gravity center -resize 512x512^ -extent 512x512 "$HOME/.face" >/dev/null 2>&1
  fi

  # 4. Paleta y plantillas. --prefer evita el prompt interactivo de matugen.
  #    Sin --scheme/--contrast se usan los defaults de siempre.
  local args
  mapfile -t args < <(matugen_args "$wp" "$scheme" "$contrast")
  if [ "$DRY" = true ]; then
    log "  dry: matugen ${args[*]}"
    sleep "$DRY_DELAY"
    rc=0
  elif command -v matugen >/dev/null 2>&1; then
    matugen "${args[@]}" >/dev/null 2>&1
    rc=$?
  else
    rc=127
  fi

  # 5. Estado e historial.
  record_apply "$wp" "$scheme" "$contrast" "$source"
  log "listo: matugen rc=$rc en $(( ($(date +%s%N) - t0) / 1000000 )) ms"

  # 6. Temas de arranque/login, diferidos.
  [ "$no_system" = true ] || schedule_system "$wp" "$scheme" "$contrast"
}

# ---- Pasada de sistema (SDDM, Plymouth, GRUB), diferida -------------------

matugen_args() { # wallpaper scheme contrast -> argumentos de matugen image
  local a=(image "$1" --prefer saturation)
  [ -n "$2" ] && a+=(-t "$2")
  [ -n "$3" ] && a+=(--contrast "$3")
  printf '%s\n' "${a[@]}"
}

schedule_system() { # wallpaper scheme contrast
  local token
  token="$(date +%s%N)"
  jq -n --arg wp "$1" --arg scheme "$2" --arg contrast "$3" --arg token "$token" --argjson dry "$DRY" \
    '{wallpaper: $wp, scheme: $scheme, contrast: $contrast, token: $token, dry: $dry}' \
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
  local wp scheme contrast t0 rc
  wp="$(jq -r .wallpaper <<< "$job")"; scheme="$(jq -r .scheme <<< "$job")"; contrast="$(jq -r .contrast <<< "$job")"
  DRY="$(jq -r .dry <<< "$job")"
  local args
  mapfile -t args < <(matugen_args "$wp" "$scheme" "$contrast")
  t0=$(date +%s%N)
  log "sistema: aplicar $wp$([ "$DRY" = true ] && echo " [dry-run]")"
  if [ "$DRY" = true ]; then
    log "  dry: matugen -c $SYSTEM_CFG ${args[*]}"
    log "  dry: sudo -n /usr/local/bin/sync-sddm-theme"
    rc=0
  else
    matugen -c "$SYSTEM_CFG" "${args[@]}" >/dev/null 2>&1
    rc=$?
    # SDDM despues de escribir sus 9 archivos (KI-C2); Plymouth y GRUB
    # sincronizan desde sus propios post_hook.
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
            "$(jq -r '.no_system // false' <<< "$req")"
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
if [ "${1:-}" = "--favorite" ]; then
  [ $# -eq 3 ] || usage
  fav="$(readlink -f -- "$2")"
  [ -f "$fav" ] || die "no existe: $2"
  case "$3" in on|off|toggle) ;; *) die "favorito: usar on|off|toggle" ;; esac
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
if [ "${1:-}" = "--tag" ]; then
  [ $# -eq 4 ] || usage
  twp="$(readlink -f -- "$2")"
  [ -f "$twp" ] || die "no existe: $2"
  case "$3" in add|remove) ;; *) die "etiqueta: usar add|remove" ;; esac
  # Formato (decision B4c): minusculas, sin espacios en los bordes, espacios
  # internos -> "-", maximo 24 caracteres. ${t,,} respeta el locale (acentos).
  tag="${4,,}"
  tag="$(printf '%s' "$tag" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/-/g')"
  tag="${tag:0:24}"
  [ -n "$tag" ] || die "etiqueta vacia"
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

wallpaper="" scheme="" contrast="" source="ipc" DRY=false NO_SYSTEM=false
while [ $# -gt 0 ]; do
  case "$1" in
    --scheme)   scheme="${2:-}"; shift 2 ;;
    --contrast) contrast="${2:-}"; shift 2 ;;
    --source)   source="${2:-}"; shift 2 ;;
    --dry-run)  DRY=true; shift ;;
    --no-system) NO_SYSTEM=true; shift ;;
    -h|--help)  usage ;;
    -*)         die "opcion desconocida: $1" ;;
    *)          [ -z "$wallpaper" ] || die "mas de un wallpaper"; wallpaper="$1"; shift ;;
  esac
done

[ -n "$wallpaper" ] || usage
[ -f "$wallpaper" ] || die "no existe: $wallpaper"
wallpaper="$(readlink -f -- "$wallpaper")"
case "${wallpaper,,}" in
  *.png|*.jpg|*.jpeg|*.webp|*.gif) ;;
  *) die "formato no soportado: $wallpaper" ;;
esac
if [ -n "$scheme" ]; then
  [[ " $SCHEMES " == *" $scheme "* ]] || die "esquema desconocido: $scheme"
fi
if [ -n "$contrast" ]; then
  awk -v c="$contrast" 'BEGIN { exit !(c ~ /^-?[0-9]*\.?[0-9]+$/ && c >= -1 && c <= 1) }' \
    || die "contraste fuera de rango (-1..1): $contrast"
fi
case "$source" in rofi|gallery|undo|ipc) ;; *) die "origen desconocido: $source" ;; esac

# Pedido atomico: el ultimo en escribirse gana.
jq -n --arg wp "$wallpaper" --arg scheme "$scheme" --arg contrast "$contrast" \
      --arg source "$source" --argjson dry "$DRY" --argjson no_system "$NO_SYSTEM" \
  '{wallpaper: $wp, scheme: (if $scheme == "" then null else $scheme end),
    contrast: (if $contrast == "" then null else $contrast end), source: $source, dry: $dry,
    no_system: $no_system}' \
  > "$REQUEST.$$" && mv "$REQUEST.$$" "$REQUEST"
log "pedido: $wallpaper (origen=$source)"

# Worker desacoplado: el atajo de teclado vuelve al instante.
setsid -f "$SCRIPTS_DIR/$(basename "$0")" --worker < /dev/null > /dev/null 2>&1
exit 0
