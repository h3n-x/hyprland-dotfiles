#!/usr/bin/env bash
# ============================================================================
# tray-stop.sh - Detiene aplicaciones en segundo plano registradas en el Tray
# Uso:
#   tray-stop.sh <id> [title]
# ============================================================================
set -euo pipefail

I18N="$(dirname "$(readlink -f "$0")")/i18n"
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
# En el idioma del usuario (Fase 15 B4).
app="$("$I18N" tr "Tray")"
if [ "$STOPPED" = true ]; then
    if [ -n "$PID" ]; then info_msg="$("$I18N" tr "%1 was stopped (PID %2)" "$TITLE" "$PID")"
    else info_msg="$("$I18N" tr "%1 was stopped" "$TITLE")"; fi
    notify-send -a "$app" "$("$I18N" tr "App stopped")" "$info_msg" -i application-x-executable -t 2500
else
    notify-send -a "$app" "$("$I18N" tr "Couldn't stop it")" "$("$I18N" tr "No running process found for %1" "$TITLE")" -i dialog-warning -t 2500
fi
