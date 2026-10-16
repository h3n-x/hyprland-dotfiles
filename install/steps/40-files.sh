# shellcheck shell=bash
# shellcheck disable=SC2034  # SUMMARY_RELOGIN lo lee el resumen
# Paso 4 (Fase 19 B2): la configuracion. stow de cada carpeta del repo; lo que ya existia en tu
# home y chocaria se mueve antes a ~/.local/state/dotfiles/backup-<fecha>/ (nada se pisa ni se
# borra). Despues: copias de Papirus, apps por defecto, fuentes de GTK, Qt, GPU y zsh.

# stow_conflicts PAQUETE...: las rutas (relativas a HOME) que stow no puede enlazar.
stow_conflicts() {
    stow -n -v -d "$REPO_DIR" -t "$HOME" "$@" 2>&1 | sed -nE \
        -e 's/.* over existing target (.+) since .*/\1/p' \
        -e 's/.*existing target is not owned by stow: (.+)$/\1/p' \
        -e 's/.* over existing directory target (.+)$/\1/p' \
        -e 's/.*existing target is neither a link nor a directory: (.+)$/\1/p'
}

step_files() {
    info "Linking the configuration"
    local pkgs conflicts f backup
    mapfile -t pkgs < <(stow_packages)
    mapfile -t conflicts < <(stow_conflicts "${pkgs[@]}" | sort -u)
    # Los que su app reescribe (thunar.xml): se quedan como estan, stow los ignora.
    local ignore=() keep=()
    for f in "${conflicts[@]}"; do
        if [[ " $REWRITTEN " == *" $f "* ]]; then ignore+=(--ignore="${f##*/}"); else keep+=("$f"); fi
    done
    conflicts=("${keep[@]}")
    if [ ${#conflicts[@]} -gt 0 ]; then
        backup="$STATE/backup-$(date +%Y%m%d-%H%M%S)"
        info "%1 existing files would be replaced: moving them to %2" "${#conflicts[@]}" "$backup"
        for f in "${conflicts[@]}"; do
            printf '   %s\n' "$f"
            do_ mkdir -p "$backup/$(dirname "$f")"
            do_ mv "$HOME/$f" "$backup/$f"
        done
        done_ "Backed up %1 files to %2" "${#conflicts[@]}" "$backup"
    fi
    do_ stow -d "$REPO_DIR" -t "$HOME" "${ignore[@]}" "${pkgs[@]}" || { err "stow failed"; return 1; }
    ok "Linked: %1" "${pkgs[*]}"
    SUMMARY_RELOGIN=true

    # git/.gitconfig lleva la identidad de quien armo el repo: no se enlaza sin que la cambies.
    skipped "git (git/.gitconfig has the author's name and email: edit it, then run: stow git)"

    qt_config || true
    if [ -x "$REPO_DIR/hypr/.config/hypr/scripts/gpu-setup" ]; then
        do_ "$REPO_DIR/hypr/.config/hypr/scripts/gpu-setup" --write
    fi

    # papirus-folders cambia el color de las carpetas en cada wallpaper sin sudo: necesita una
    # copia local del tema (Papirus-Dark y -Light son sobre todo enlaces relativos a Papirus).
    local t
    for t in Papirus Papirus-Dark Papirus-Light; do
        if [ -d "/usr/share/icons/$t" ] && [ ! -d "$HOME/.local/share/icons/$t" ]; then
            info "Copying the %1 icon theme to ~/.local/share/icons (papirus-folders without sudo)" "$t"
            do_ mkdir -p "$HOME/.local/share/icons"
            do_ cp -r "/usr/share/icons/$t" "$HOME/.local/share/icons/"
        fi
    done

    # Abrir/Reproducir de la vista previa de capturas usan xdg-open (Fase 4 B8).
    if command -v xdg-mime >/dev/null 2>&1; then
        do_ xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/webp image/gif
        do_ xdg-mime default mpv.desktop video/mp4 video/x-matroska video/webm
    fi

    # GTK en Wayland lee las fuentes de gsettings (portal de ajustes), no de settings.ini (D1).
    if command -v gsettings >/dev/null 2>&1; then
        { do_ gsettings set org.gnome.desktop.interface font-name 'Plus Jakarta Sans 10' &&
          do_ gsettings set org.gnome.desktop.interface document-font-name 'Plus Jakarta Sans 11' &&
          do_ gsettings set org.gnome.desktop.interface monospace-font-name 'Maple Mono NF 11'; } 2>/dev/null ||
            warn "Could not set the GTK fonts with gsettings (no session bus?); they are set at the first login"
    fi

    local zsh shell
    # La ruta que /etc/shells acepta (chsh rechaza otras; en Artix "command -v" da /usr/sbin/zsh).
    zsh=$(grep -m1 -E '^/(usr/)?bin/zsh$' /etc/shells 2>/dev/null || command -v zsh || true)
    shell=$(getent passwd "$USER" | cut -d: -f7)
    # Ya es zsh (/bin/zsh y /usr/bin/zsh son el mismo en Arch): nada que hacer.
    if [ -n "$zsh" ] && [ "${shell##*/}" != zsh ]; then
        if ask y "Make zsh your login shell (now %1)?" "$shell"; then
            do_ sudo chsh -s "$zsh" "$USER" && done_ "zsh is your login shell"
        else
            skipped "zsh as the login shell"
        fi
    fi
}
