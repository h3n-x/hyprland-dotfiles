# shellcheck shell=bash
# Paso final (Fase 19 B2): lo hecho, lo omitido y por que, y lo que queda (pasos de sistema,
# volver a entrar).

step_summary() {
    local s
    echo
    info "Summary"
    for s in "${SUMMARY_DONE[@]}"; do printf '\033[1;32m ✓\033[0m %s\n' "$s"; done
    for s in "${SUMMARY_SKIPPED[@]}"; do printf '\033[2m · %s\033[0m\n' "$(tr_ "Skipped: %1" "$s")"; done
    [ "${DRY:-false}" = true ] && ok "Dry run: nothing was changed"
    [ -n "${LOG:-}" ] && [ -s "$LOG" ] && ok "Log: %1" "$LOG"
    echo
    info "Optional system steps (they need sudo and differ per machine): see the README"
    printf '   %s\n' "$(tr_ "Login screen (SDDM), boot splash (Plymouth), GRUB theme, hybrid GPU")"
    if $SUMMARY_RELOGIN; then
        if [ "${INIT:-systemd}" = systemd ]; then warn "Log out and back in (session %1) so the environment variables apply from the start" "Hyprland (uwsm)"
        else warn "Log out and back in (session %1) so the environment variables apply from the start" "Hyprland"; fi
    fi
    return 0
}
