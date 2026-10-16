# shellcheck shell=bash
# Paso 5 (Fase 19 B2): la primera paleta. Wallpaper semilla (el primero de ~/Pictures/Wallpapers
# o un degradado), colores de estado y de codigo, las dos configs de matugen (la del sistema solo
# prepara SDDM/Plymouth/GRUB en ~/.cache; copiarlos es un paso de sistema), ~/.face y tldr.
# Si la paleta ya existe no se toca: elegir wallpaper es Super+Shift+W.

step_first_run() {
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/matugen" scripts="$HOME/.config/hypr/scripts" wp seed
    if [ -s "$cache/quickshell-colors.json" ] && [ -s "$cache/code.json" ] && [ "${FORCE:-false}" != true ]; then
        ok "The color palette already exists (change it with Super+Shift+W)"
    else
        [ -x "$scripts/palette" ] || { err "The configuration is not linked yet (run: ./install.sh files)"; return 1; }
        info "Generating the color palette for the first time"
        wp="$HOME/Pictures/Wallpapers"
        do_ mkdir -p "$wp"
        seed=$(find "$wp" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | sort | head -1)
        if [ -z "$seed" ]; then
            seed="$wp/matugen-seed.png"
            info "No wallpaper in %1: creating a gradient to start with" "$wp"
            do_ magick -size 1920x1080 'gradient:#1a1a2e-#8b5cf6' "$seed"
        fi
        # Colores de estado fijos y paleta de codigo (P8.7, Fase 18): matugen los importa.
        do_ "$scripts/palette" code --image "$seed" --mode dark --write || { err "palette failed"; return 1; }
        do_ matugen image "$seed" --prefer saturation -m dark >/dev/null || { err "matugen failed"; return 1; }
        do_ env PALETTE_STATUS_OUT="$cache/status-system.json" "$scripts/palette" status --mode dark --write
        do_ matugen -c "$HOME/.config/matugen/config-system.toml" image "$seed" --prefer saturation -m dark >/dev/null ||
            warn "The boot and login themes could not be prepared (they are optional)"
        # ~/.face: la imagen del bloqueo y de Plymouth (theme-apply.sh la rehace en cada cambio).
        do_ magick "$seed" -gravity center -resize '512x512^' -extent 512x512 "$HOME/.face"
        ok "Palette generated from %1" "$(basename "$seed")"
        done_ "Color palette generated from %1" "$(basename "$seed")"
    fi
    if command -v tldr >/dev/null 2>&1 && [ ! -d "${XDG_CACHE_HOME:-$HOME/.cache}/tealdeer" ]; then
        do_ tldr --update >/dev/null 2>&1 || warn "Could not download the tldr pages (run: tldr --update)"
    fi
    return 0
}
