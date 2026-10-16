# shellcheck shell=bash
# Paso 2 (Fase 19 B2): los paquetes del perfil (repos y AUR) y las versiones minimas. Una
# version vieja (Manjaro estable) para aqui con el motivo: la config no funcionaria (D-P19-4).

step_packages() {
    local groups pkgs
    [ -n "${INIT:-}" ] || detect_init
    mapfile -t groups < <(profile_groups "$PROFILE")
    info "Packages (profile %1: %2)" "$PROFILE" "${groups[*]}"
    mapfile -t pkgs < <(package_list "${groups[@]}")
    # uwsm (la sesion "Hyprland (uwsm)") es un gestor de sesion de systemd: sin systemd, la sesion
    # "Hyprland" normal. La config no depende de el.
    if [ "$INIT" != systemd ]; then
        local keep=() p
        for p in "${pkgs[@]}"; do [ "$p" = uwsm ] || keep+=("$p"); done
        pkgs=("${keep[@]}")
        skipped "uwsm (needs systemd: use the plain Hyprland session)"
    fi
    pkg_install "${pkgs[@]}" || return 1
    aur_install "${groups[@]}"
    [ "${DRY:-false}" = true ] || { mkdir -p "$STATE"; printf '%s\n' "$PROFILE" > "$STATE/install-profile"; }
    check_versions
}

# check_versions: 1 si algo de MIN_VERSIONS esta instalado pero es viejo (lo dice).
check_versions() {
    local mv p min v bad=0
    for mv in $MIN_VERSIONS; do
        p=${mv%%:*}; min=${mv#*:}; v=$(pkg_version "$p")
        if [ -z "$v" ]; then
            [ "${DRY:-false}" = true ] || { err "%1 is not installed" "$p"; bad=1; }
        elif version_at_least "$p" "$min"; then ok "%1 %2 (needs %3 or newer)" "$p" "$v" "$min"
        else err "%1 %2 is too old: the configuration needs %3 or newer" "$p" "$v" "$min"; bad=1; fi
    done
    if [ $bad -ne 0 ]; then
        err "Stopping before linking the configuration: it would not work with these versions"
        [ "$DISTRO_ID" = manjaro ] && warn "On Manjaro, switch to the unstable branch (sudo pacman-mirrors --api --set-branch unstable) or wait for the update"
        return 1
    fi
}
