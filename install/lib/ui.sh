# shellcheck shell=bash
# shellcheck disable=SC2034  # SUMMARY_* los lee el resumen (steps/90-summary.sh)
# Salida del instalador (Fase 19): mensajes en el idioma del usuario por scripts/i18n (texto
# fuente en ingles; corre desde el repo, antes del stow) y el registro en espanol.
# Se carga con `source`; usa REPO_DIR, DRY (true/false), YES (true/false) y LOG si estan definidos.

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
info() { printf '\033[1;34m==>\033[0m %s\n' "$(tr_ "$@")"; log_ "info: $*"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$(tr_ "$@")"; log_ "ok: $*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$(tr_ "$@")" >&2; log_ "aviso: $*"; }
err()  { printf '\033[1;31m ✗\033[0m %s\n' "$(tr_ "$@")" >&2; log_ "error: $*"; }

# do_ CMD...: corre el comando, o con DRY=true solo lo muestra.
do_() {
    # En seco se muestra por el descriptor 3 (la salida del instalador), asi un ">/dev/null" del
    # comando no lo esconde.
    if [ "${DRY:-false}" = true ]; then printf '   \033[2m$ %s\033[0m\n' "$*" >&"${DRY_FD:-1}"; log_ "dry: $*"; return 0; fi
    log_ "corre: $*"
    "$@"
}

# sudo_keepalive: pide sudo una vez y lo mantiene vivo mientras dure el instalador (el trap de
# install.sh cierra el proceso). En seco no hace nada.
SUDO_KEEPALIVE=''
sudo_keepalive() {
    [ "${DRY:-false}" = true ] && return 0
    [ -n "$SUDO_KEEPALIVE" ] && return 0
    sudo -v || { err "sudo is needed for this step"; return 1; }
    ( while kill -0 "$$" 2>/dev/null; do sudo -n -v 2>/dev/null; sleep 50; done ) &
    SUDO_KEEPALIVE=$!
}

# ask y|n TEXTO [ARG...]: 0 = si. Con YES=true, o sin terminal, la respuesta por defecto.
ask() {
    local def=$1 q a; shift
    q=$(tr_ "$@")
    if [ "${YES:-false}" = true ] || [ ! -t 0 ]; then
        log_ "pregunta: $* -> $def (por defecto)"
        [ "$def" = y ]; return
    fi
    if [ "$def" = y ]; then printf '\033[1;35m ?\033[0m %s [Y/n] ' "$q"; else printf '\033[1;35m ?\033[0m %s [y/N] ' "$q"; fi
    read -r a || a=
    a=${a,,}
    [ -z "$a" ] && a=$def
    log_ "pregunta: $* -> $a"
    [[ "$a" == y* || "$a" == s* ]]   # y/yes, s/si
}

# Resumen del final: lo hecho, lo omitido (y por que) y lo que pide volver a entrar.
SUMMARY_DONE=()
SUMMARY_SKIPPED=()
SUMMARY_RELOGIN=false
done_()    { SUMMARY_DONE+=("$(tr_ "$@")"); }
skipped()  { SUMMARY_SKIPPED+=("$(tr_ "$@")"); log_ "omitido: $*"; }
