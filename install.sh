#!/usr/bin/env bash
# Instalador de estos dotfiles (Fase 19): Arch Linux y sus derivadas (EndeavourOS, CachyOS,
# Manjaro, Garuda, Artix...). Modular: install/lib (funciones), install/steps (un archivo por
# paso), install/packages (las listas como datos). Cada paso se puede correr solo.
#
#   ./install.sh [comando] [opciones]        ./install.sh --help
#
# Idempotente: correrlo otra vez solo hace lo que falte. Nunca como root; pide sudo una vez.
# Los pasos de sistema (SDDM, Plymouth, GRUB, GPU hibrida) estan en el README.
# shellcheck disable=SC2034  # AUR_HELPER, SKIP_SYSUPDATE, FORCE... los leen los pasos (install/steps)
set -euo pipefail

REPO_DIR=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)
INSTALL_DIR="$REPO_DIR/install"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
DRY=false YES=false NO_AUR=false SKIP_SYSUPDATE=false FORCE=false WITH_SYSTEM=false
SYSTEM_STEPS=()
PROFILE='' WITH='' WITHOUT='' AUR_HELPER='' LOG=''
export REPO_DIR INSTALL_DIR

for f in "$INSTALL_DIR"/lib/*.sh "$INSTALL_DIR"/steps/*.sh; do
    # shellcheck source=/dev/null
    . "$f"
done

usage() {
    cat <<USAGE
$(tr_ "Usage: %1 [command] [options]" "./install.sh")

$(tr_ "Commands:")
  install      $(tr_ "everything below, in order (default)")
  deps         $(tr_ "packages of the profile (repositories and AUR) and version check")
  services     $(tr_ "NetworkManager, bluetooth, power profiles")
  files        $(tr_ "link the configuration (existing files are backed up first)")
  first-run    $(tr_ "first color palette, ~/.face")
  apps         $(tr_ "set up the personal apps (profile full)")
  system [sddm|plymouth|grub|gpu]
               $(tr_ "optional system steps (login screen, boot splash, GRUB theme, GPU); all if none given")
  doctor       $(tr_ "check this installation (changes nothing)")
  uninstall    $(tr_ "remove the links, restore the backup, optionally the packages")

$(tr_ "Options:")
  -y, --yes               $(tr_ "no questions: take the default answers")
  -n, --dry-run           $(tr_ "show every command without running it")
  --with-system           $(tr_ "install: also the system steps (with --yes, without asking)")
  --profile minimal|full  $(tr_ "minimal: the desktop; full: also dev tools and personal apps (default: full, or the last one used)")
  --with G1,G2            $(tr_ "add package groups (dev, apps)")
  --without G1,G2         $(tr_ "leave package groups out")
  --no-aur                $(tr_ "no AUR: install the repository alternatives")
  --aur-helper yay|paru   $(tr_ "which AUR helper to use")
  --skip-sysupdate        $(tr_ "don't update the system first (not recommended on Arch)")
  --force                 $(tr_ "first-run: regenerate the palette even if it exists")
  --lang es|en|ja         $(tr_ "language of the messages")
USAGE
}

CMD=install HELP=false
while [ $# -gt 0 ]; do
    case "$1" in
        install|deps|services|files|first-run|apps|doctor|uninstall|system) CMD=$1 ;;
        sddm|plymouth|grub|gpu) [ "$CMD" = system ] || { err "Unknown option: %1" "$1"; exit 2; }; SYSTEM_STEPS+=("$1") ;;
        --with-system) WITH_SYSTEM=true ;;
        -y|--yes) YES=true ;;
        -n|--dry-run) DRY=true ;;
        --profile) PROFILE=${2:-}; shift ;;
        --profile=*) PROFILE=${1#*=} ;;
        --with) WITH=${2:-}; shift ;;
        --with=*) WITH=${1#*=} ;;
        --without) WITHOUT=${2:-}; shift ;;
        --without=*) WITHOUT=${1#*=} ;;
        --no-aur) NO_AUR=true ;;
        --aur-helper) AUR_HELPER=${2:-}; shift ;;
        --aur-helper=*) AUR_HELPER=${1#*=} ;;
        --skip-sysupdate) SKIP_SYSUPDATE=true ;;
        --force) FORCE=true ;;
        --lang) export I18N_LANG=${2:-}; shift ;;
        --lang=*) export I18N_LANG=${1#*=} ;;
        -h|--help) HELP=true ;;
        *) err "Unknown option: %1" "$1"; usage >&2; exit 2 ;;
    esac
    shift
done
$HELP && { usage; exit 0; }
case "$PROFILE" in
    "") PROFILE=$(cat "$STATE/install-profile" 2>/dev/null || echo full) ;;
    minimal|full) ;;
    *) err "Unknown profile: %1 (minimal or full)" "$PROFILE"; exit 2 ;;
esac
export DRY YES
exec 3>&1; DRY_FD=3   # do_ muestra los comandos en seco aunque su salida vaya a /dev/null

[ "$CMD" = doctor ] && exec "$INSTALL_DIR/doctor.sh"

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/install-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$LOG")"
log_ "instalador: $CMD perfil=$PROFILE dry=$DRY yes=$YES no_aur=$NO_AUR with=$WITH without=$WITHOUT"
trap '[ -n "$SUDO_KEEPALIVE" ] && kill "$SUDO_KEEPALIVE" 2>/dev/null; true' EXIT

# run PASO...: corre los pasos en orden; el primero que falla para todo (y lo dice).
run() {
    local s
    for s in "$@"; do
        log_ "paso: $s"
        if ! "step_$s"; then
            err "The step %1 failed: stopping (log: %2)" "$s" "$LOG"
            step_summary
            exit 1
        fi
    done
    step_summary
}

case "$CMD" in
    install)   run preflight packages services files first_run apps system_gate ;;
    deps)      run preflight packages ;;
    services)  detect_distro; run services ;;
    files)     detect_distro; run files ;;
    first-run) detect_distro; run first_run ;;
    apps)      detect_distro; run apps ;;
    uninstall) detect_distro; run uninstall ;;
    system)    detect_distro; run system ;;
esac
