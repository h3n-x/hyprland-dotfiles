#!/usr/bin/env bash
# ============================================================================
# tray-stop.sh - Detiene aplicaciones en segundo plano registradas en el Tray
# Uso:
#   tray-stop.sh <id> [title]
# ============================================================================
set -euo pipefail

TARGET="${1:-}"
TITLE="${2:-$TARGET}"

if [ -z "$TARGET" ]; then
    echo "uso: tray-stop.sh <id> [title]" >&2
    exit 1
fi

PID=""

# 1. Intentar resolver el PID exacto a través del bus DBus de StatusNotifierItem
if command -v busctl >/dev/null 2>&1; then
    ITEMS=$(busctl --user call org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.freedesktop.DBus.Properties Get ss org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems 2>/dev/null | grep -oP ':[0-9]+\.[0-9]+/[^"\s]+' || true)
    for item in $ITEMS; do
        SERVICE="${item%%/*}"
        if echo "$item" | grep -qi "$TARGET"; then
            FOUND_PID=$(busctl --user status "$SERVICE" 2>/dev/null | grep -oP '(?<=^PID=)[0-9]+' | head -1 || true)
            if [ -n "$FOUND_PID" ]; then
                PID="$FOUND_PID"
                break
            fi
        fi
    done
fi

STOPPED=false

# 2. Si se obtuvo PID, terminar dicho proceso
if [ -n "$PID" ]; then
    if kill -TERM "$PID" 2>/dev/null; then
        STOPPED=true
        sleep 0.3
        if kill -0 "$PID" 2>/dev/null; then
            kill -KILL "$PID" 2>/dev/null || true
        fi
    fi
fi

# 3. Fallback: pkill por nombre de binario o id
if [ "$STOPPED" = false ]; then
    # Intentar coincidencia exacta o por subcadena
    if pkill -x -TERM "$TARGET" 2>/dev/null || pkill -f -TERM "$TARGET" 2>/dev/null; then
        STOPPED=true
        sleep 0.3
        pkill -x -KILL "$TARGET" 2>/dev/null || pkill -f -KILL "$TARGET" 2>/dev/null || true
    fi
fi

# 4. Notificar resultado al usuario
if [ "$STOPPED" = true ]; then
    info_msg="Se detuvo $TITLE"
    [ -n "$PID" ] && info_msg="$info_msg (PID $PID)"
    notify-send -a "Bandeja" "Aplicación detenida" "$info_msg" -i application-x-executable -t 2500
else
    notify-send -a "Bandeja" "No se pudo detener" "No se encontró el proceso activo para $TITLE" -i dialog-warning -t 2500
fi
