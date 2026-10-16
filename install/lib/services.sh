# shellcheck shell=bash
# Servicios (Fase 19 B2): systemd, y en Artix OpenRC/runit/dinit/s6 (best effort, D-P19-3).
# Se carga con `source`; necesita lib/ui.sh, lib/pkg.sh, INIT e INIT_RUNNING (detect_init).

# El nombre del servicio fuera de systemd (Artix): bluetooth se llama bluetoothd.
svc_name() {
    if [ "$INIT" = systemd ]; then printf '%s\n' "$1"; return; fi
    case "$1" in bluetooth) echo bluetoothd ;; *) printf '%s\n' "$1" ;; esac
}

# svc_enabled SERVICIO: 0 si arranca con el sistema.
svc_enabled() {
    local s; s=$(svc_name "$1")
    case "$INIT" in
        systemd) systemctl is-enabled --quiet "$s" 2>/dev/null ;;
        openrc)  [ -e "/etc/runlevels/default/$s" ] ;;
        runit)   [ -e "/etc/runit/runsvdir/default/$s" ] || [ -e "/run/runit/service/$s" ] ;;
        dinit)   [ -e "/etc/dinit.d/boot.d/$s" ] ;;
        s6)      [ -e "/etc/s6/adminsv/default/contents.d/$s" ] ;;
        *)       return 1 ;;
    esac
}

# svc_enable SERVICIO PAQUETE: lo activa (y lo arranca si el init esta corriendo). En Artix
# instala antes el script del servicio (PAQUETE-openrc, -runit, -dinit, -s6).
svc_enable() {
    local s; s=$(svc_name "$1")
    svc_enabled "$1" && { ok "%1 is already enabled" "$s"; return 0; }
    case "$INIT" in
        systemd)
            if $INIT_RUNNING; then do_ sudo systemctl enable --now "$s"; else do_ sudo systemctl enable "$s"; fi ;;
        openrc|runit|dinit|s6)
            pkg_install "$2-$INIT" || { warn "Artix: no %1 script for %2; enable it by hand" "$INIT" "$s"; return 1; }
            case "$INIT" in
                openrc) do_ sudo rc-update add "$s" default && { ! $INIT_RUNNING || do_ sudo rc-service "$s" start; } ;;
                runit)  do_ sudo ln -sf "/etc/runit/sv/$s" /etc/runit/runsvdir/default/ ;;
                dinit)  if $INIT_RUNNING; then do_ sudo dinitctl enable "$s"; else do_ sudo ln -sf "../$s" "/etc/dinit.d/boot.d/$s"; fi ;;
                s6)     do_ sudo touch "/etc/s6/adminsv/default/contents.d/$s" && { ! $INIT_RUNNING || do_ sudo s6-db-reload; } ;;
            esac ;;
        *)
            warn "Unknown init system: enable %1 by hand" "$s"; return 1 ;;
    esac || { warn "Could not enable %1" "$s"; return 1; }
    ok "%1 enabled" "$s"
    done_ "Enabled %1" "$s"
}
