# shellcheck shell=bash
# Paso 6 (Fase 19 B2, perfil full o --with apps): lo que necesitan las apps personales despues de
# instaladas. spicetify (tema matugen + Marketplace) y Java 25 por defecto.

step_apps() {
    [[ " $(profile_groups "$PROFILE" | tr '\n' ' ') " == *" apps "* ]] || { skipped "Personal apps (profile %1)" "$PROFILE"; return 0; }
    info "Personal apps"
    if command -v spicetify >/dev/null 2>&1; then
        do_ spicetify config current_theme matugen color_scheme matugen >/dev/null
        if [ "${DRY:-false}" = true ]; then do_ spicetify apply
        elif spicetify apply >/dev/null 2>&1; then ok "Spotify uses the matugen theme"
        else warn "spicetify apply failed (open Spotify once, then run: spicetify apply)"; fi
        if [ ! -d "$HOME/.config/spicetify/CustomApps/marketplace" ] &&
            ask y "Install the spicetify Marketplace (downloads its official installer)?"; then
            if [ "${DRY:-false}" = true ]; then do_ "curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.sh | sh"
            else curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.sh | sh >/dev/null 2>&1 ||
                warn "The Marketplace installer failed (see the README)"; fi
        fi
    fi
    if command -v archlinux-java >/dev/null 2>&1 && archlinux-java status 2>/dev/null | grep -q java-25-openjdk &&
        [ "$(archlinux-java get 2>/dev/null)" != java-25-openjdk ]; then
        do_ sudo archlinux-java set java-25-openjdk && ok "Java 25 is the default"
    fi
    return 0
}
