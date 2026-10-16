# shellcheck shell=bash
# Paso 3 (Fase 19 B2): los servicios que la shell usa. NetworkManager (menu de red), bluetooth,
# power-profiles-daemon (perfiles de energia, modo juego) salvo que otro gestor de energia ya
# este activo: se pregunta. UPower se activa solo por D-Bus; el agente de polkit lo arranca Hyprland.

step_services() {
    info "Services"
    [ -n "${INIT:-}" ] || detect_init
    svc_enable NetworkManager networkmanager
    svc_enable bluetooth bluez
    local other='' s
    for s in tlp tuned-ppd tuned auto-cpufreq; do svc_enabled "$s" && { other=$s; break; }; done
    if [ -n "$other" ] && ! svc_enabled power-profiles-daemon; then
        if ask n "%1 manages power. Switch to power-profiles-daemon (the shell's power menu needs it)?" "$other"; then
            do_ sudo systemctl disable --now "$other" 2>/dev/null || true
            svc_enable power-profiles-daemon power-profiles-daemon
        else
            skipped "power-profiles-daemon (%1 manages power; the power menu won't change anything)" "$other"
        fi
    else
        svc_enable power-profiles-daemon power-profiles-daemon
    fi
}
