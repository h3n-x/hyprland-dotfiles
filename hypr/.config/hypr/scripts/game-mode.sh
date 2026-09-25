#!/usr/bin/env bash
# ============================================================================
# game-mode.sh - Modo Juego para Hyprland
# Optimiza el sistema para gaming:
#   - Perfil de energía a "performance"
#   - Pausa hypridle (evita pantalla negra con mandos)
#   - Desactiva blur y sombras en Hyprland para maximizar FPS y reducir latencia
#   - Notifica al usuario
# ============================================================================
set -euo pipefail

STATE_FILE="/tmp/gamemode-${USER}.state"

is_active() {
    [ -f "$STATE_FILE" ]
}

enable_game_mode() {
    touch "$STATE_FILE"

    # 1. Perfil de rendimiento
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set performance 2>/dev/null || true
    fi

    # 2. Pausar hypridle para que no bloquee ni apague pantalla con mandos
    pkill -STOP hypridle 2>/dev/null || true

    # 3. Optimizar Hyprland (desactivar blur y sombras para menor latencia)
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl keyword decoration:blur:enabled false >/dev/null 2>&1 || true
        hyprctl keyword decoration:shadow:enabled false >/dev/null 2>&1 || true
    fi

    notify-send -a "Modo Juego" "Modo Juego Activado" \
        "Perfil: Rendimiento | Reposo pausado | Gráficos optimizados" \
        -i input-gaming -t 3000
}

disable_game_mode() {
    rm -f "$STATE_FILE"

    # 1. Restaurar perfil equilibrado
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set balanced 2>/dev/null || true
    fi

    # 2. Reanudar hypridle
    pkill -CONT hypridle 2>/dev/null || true

    # 3. Restaurar efectos visuales de Hyprland
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl keyword decoration:blur:enabled true >/dev/null 2>&1 || true
        hyprctl keyword decoration:shadow:enabled true >/dev/null 2>&1 || true
    fi

    notify-send -a "Modo Juego" "Modo Juego Desactivado" \
        "Perfil equilibrado restaurado | Efectos visuales activos" \
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
        echo "uso: game-mode.sh [on|off|toggle|status]" >&2
        exit 1
        ;;
esac
