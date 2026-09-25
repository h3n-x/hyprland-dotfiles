#!/bin/bash

# Punto de entrada unico para aplicar un tema (wallpaper + paleta), Fase 3 B0.
# Lo llaman el selector de rofi y, mas adelante, la galeria, deshacer y la IPC.
#
#   theme-apply.sh <wallpaper> [--scheme <tipo>] [--contrast <-1..1>]
#                  [--source rofi|gallery|undo|ipc] [--dry-run]
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
# --dry-run no ejecuta hyprctl, magick ni matugen: solo registra lo que haria
# (para pruebas; usar THEME_STATE_DIR/THEME_LOG_DIR para no tocar el estado real).

set -uo pipefail

SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"
STATE_DIR="${THEME_STATE_DIR:-$HOME/.local/state/dotfiles}"
STATE="$STATE_DIR/wallpapers.json"
REQUEST="$STATE_DIR/theme-apply.request"
LOCK="$STATE_DIR/theme-apply.lock"
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
  sed -n '6,7p' "$0" | sed 's/^# \{0,3\}//' >&2
  exit 2
}

# ---- Estado ---------------------------------------------------------------

# Estado inicial a partir del wallpaper que ya esta aplicado, asi el
# historial arranca desde lo que hay hoy.
init_state() {
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

record_apply() { # wallpaper scheme contrast source
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

apply() { # wallpaper scheme contrast source
  local wp="$1" scheme="$2" contrast="$3" source="$4" t0 rc
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
  local args=(image "$wp" --prefer saturation)
  [ -n "$scheme" ] && args+=(-t "$scheme")
  [ -n "$contrast" ] && args+=(--contrast "$contrast")
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
            "$(jq -r '.source' <<< "$req")"
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

wallpaper="" scheme="" contrast="" source="ipc" DRY=false
while [ $# -gt 0 ]; do
  case "$1" in
    --scheme)   scheme="${2:-}"; shift 2 ;;
    --contrast) contrast="${2:-}"; shift 2 ;;
    --source)   source="${2:-}"; shift 2 ;;
    --dry-run)  DRY=true; shift ;;
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
      --arg source "$source" --argjson dry "$DRY" \
  '{wallpaper: $wp, scheme: (if $scheme == "" then null else $scheme end),
    contrast: (if $contrast == "" then null else $contrast end), source: $source, dry: $dry}' \
  > "$REQUEST.$$" && mv "$REQUEST.$$" "$REQUEST"
log "pedido: $wallpaper (origen=$source)"

# Worker desacoplado: el atajo de teclado vuelve al instante.
setsid -f "$SCRIPTS_DIR/$(basename "$0")" --worker < /dev/null > /dev/null 2>&1
exit 0
