#!/usr/bin/env bash
# ============================================================================
# game-mode.sh - Modo Juego para Hyprland
# Optimiza el sistema para gaming:
#   - Perfil de energía a "performance"
#   - Pausa hypridle (evita pantalla negra con mandos)
#   - Desactiva blur, sombras y animaciones de Hyprland (hyprctl eval: con la
#     config Lua, `hyprctl keyword` no funciona, KI-C35); al salir vuelven tus
#     valores del centro de configuracion (settings-apply), no los de fabrica
#   - Notifica al usuario
# ============================================================================
set -euo pipefail

# GAMEMODE_STATE: otro archivo de estado (pruebas; settings-apply lee el mismo).
STATE_FILE="${GAMEMODE_STATE:-/tmp/gamemode-${USER}.state}"
I18N="$(dirname "$(readlink -f "$0")")/i18n"

is_active() {
    [ -f "$STATE_FILE" ]
}

# Sin blur, sombras ni animaciones. Tambien tras una recarga de la config en
# pleno modo juego (settings-apply, VRR de una pantalla: Fase 10 B5): reapply.
effects_off() {
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl eval 'hl.config({ decoration = { blur = { enabled = false }, shadow = { enabled = false } }, animations = { enabled = false } })' >/dev/null 2>&1 || true
    fi
}

enable_game_mode() {
    touch "$STATE_FILE"

    # 1. Perfil de rendimiento
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set performance 2>/dev/null || true
    fi

    # 2. Pausar hypridle para que no bloquee ni apague pantalla con mandos
    pkill -STOP hypridle 2>/dev/null || true

    # 3. Optimizar Hyprland (sin blur, sombras ni animaciones: menos latencia)
    effects_off

    notify-send -a "$("$I18N" tr "Game mode")" "$("$I18N" tr "Game mode on")" \
        "$("$I18N" tr "Profile: Performance | Idle paused | Graphics optimized")" \
        -i input-gaming -t 3000
}

disable_game_mode() {
    rm -f "$STATE_FILE"

    # 1. Restaurar perfil equilibrado
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set balanced 2>/dev/null || true
    fi

    # 2 y 3. hypridle de nuevo, con la config de ahora (pudo cambiar en pausa),
    # y los valores de Hyprland que elegiste (blur, sombras, animaciones).
    local apply="$(dirname "$(readlink -f "$0")")/settings-apply"
    "$apply" idle --restart >/dev/null 2>&1 || pkill -CONT hypridle 2>/dev/null || true
    "$apply" hypr --all >/dev/null 2>&1 || true

    notify-send -a "$("$I18N" tr "Game mode")" "$("$I18N" tr "Game mode off")" \
        "$("$I18N" tr "Balanced profile restored | Visual effects on")" \
        -i input-gaming -t 2000
}

case "${1:-toggle}" in
    on)
        enable_game_mode
        ;;
    off)
        disable_game_mode
        ;;
    toggle)
        if is_active; then
            disable_game_mode
        else
            enable_game_mode
        fi
        ;;
    reapply)
        if is_active; then effects_off; fi
        ;;
    status)
        if is_active; then
            echo "active"
            exit 0
        else
            echo "inactive"
            exit 1
        fi
        ;;
    *)
        echo "uso: game-mode.sh [on|off|toggle|reapply|status]" >&2
        exit 1
        ;;
esac
