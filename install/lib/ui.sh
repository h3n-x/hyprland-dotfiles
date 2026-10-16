# shellcheck shell=bash
# Salida del instalador (Fase 19): mensajes en el idioma del usuario por scripts/i18n (texto
# fuente en ingles; corre desde el repo, antes del stow) y el registro en espanol.
# Se carga con `source`; usa REPO_DIR, DRY (true/false) y LOG si estan definidos.

I18N_BIN="$REPO_DIR/hypr/.config/hypr/scripts/i18n"

# tr TEXTO [ARG...]: el texto traducido (sin i18n disponible, el ingles con %1.. reemplazados).
tr_() {
    if [ -x "$I18N_BIN" ] && command -v python3 >/dev/null 2>&1; then
        I18N_QML="$REPO_DIR/quickshell/.config/quickshell/dotshell" "$I18N_BIN" tr "$@" 2>/dev/null && return
    fi
    local s=$1 i=1; shift
    for a in "$@"; do s=${s//%$i/$a}; i=$((i + 1)); done
    printf '%s\n' "$s"
}

log_() { [ -n "${LOG:-}" ] && printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; return 0; }
info() { printf '\033[1;34m==>\033[0m %s\n' "$(tr_ "$@")"; log_ "info: $1"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$(tr_ "$@")"; log_ "ok: $1"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$(tr_ "$@")" >&2; log_ "aviso: $1"; }
err()  { printf '\033[1;31m ✗\033[0m %s\n' "$(tr_ "$@")" >&2; log_ "error: $1"; }

# do_ CMD...: corre el comando, o con DRY=true solo lo muestra.
do_() {
    if [ "${DRY:-false}" = true ]; then printf '   \033[2m$ %s\033[0m\n' "$*"; log_ "dry: $*"; return 0; fi
    log_ "corre: $*"
    "$@"
}
