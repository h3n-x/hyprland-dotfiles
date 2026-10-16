# shellcheck shell=bash
# Configuracion de qt5ct/qt6ct por usuario (Fase 19 B1). Ya no se versiona: las apps la
# reescriben (qt6ct guarda su ventana, el tema de iconos elegido) y color_scheme_path necesita
# la ruta absoluta del home de cada uno (qt*ct no expande "~"). La plantilla vive en
# install/templates/; una vez creado, el archivo es del usuario y solo se corrige esa linea.
# Se carga con `source`; necesita lib/ui.sh, REPO_DIR y DRY.

# qt_config [--check]: deja ~/.config/qt5ct y ~/.config/qt6ct como carpetas reales con su conf.
# --check: 0 si todo esta bien, 1 si hay algo que hacer (lo lista), sin tocar nada.
qt_config() {
    local check=false pending=0 v dir conf want tpl
    [ "${1:-}" = --check ] && check=true
    for v in qt5ct qt6ct; do
        dir="$HOME/.config/$v"; conf="$dir/$v.conf"; tpl="${INSTALL_DIR:-$REPO_DIR/install}/templates/$v.conf"
        want="color_scheme_path=$HOME/.config/$v/colors/matugen.conf"
        # 1. Carpeta o archivo enlazados al repo (el stow de antes de la Fase 19): pasan a ser reales.
        if [ -L "$dir" ] || [ -L "$conf" ]; then
            pending=1
            if $check; then warn "%1 is still a link into the repository" "$dir"; continue; fi
            info "Moving %1 out of the repository (it becomes your own file)" "$dir"
            local tmp; tmp=$(mktemp -d)
            [ -e "$conf" ] && cp "$conf" "$tmp/$v.conf"
            [ -d "$dir/colors" ] && cp -r "$dir/colors" "$tmp/"
            if [ -L "$dir" ]; then do_ rm "$dir"; else do_ rm "$conf"; fi
            do_ mkdir -p "$dir"
            [ -e "$tmp/$v.conf" ] && do_ cp "$tmp/$v.conf" "$conf"
            [ -d "$tmp/colors" ] && [ ! -d "$dir/colors" ] && do_ cp -r "$tmp/colors" "$dir/"
            rm -rf "$tmp"
        fi
        # 2. No existe: la plantilla con tu home.
        if [ ! -e "$conf" ]; then
            pending=1
            if $check; then warn "%1 is missing" "$conf"; continue; fi
            info "Creating %1" "$conf"
            do_ mkdir -p "$dir"
            if [ "${DRY:-false}" = true ]; then do_ sed "s|@HOME@|$HOME|g" "$tpl"
            else sed "s|@HOME@|$HOME|g" "$tpl" > "$conf"; fi
            continue
        fi
        # 3. Existe y es tuyo: solo la ruta de la paleta, si apunta a otro home.
        if ! grep -qxF "$want" "$conf"; then
            pending=1
            if $check; then warn "%1: the color palette points elsewhere" "$conf"; continue; fi
            info "Fixing the color palette path in %1" "$conf"
            if grep -q '^color_scheme_path=' "$conf"; then
                do_ sed -i "s|^color_scheme_path=.*|$want|" "$conf"
            else
                do_ sed -i "s|^\[Appearance\]$|[Appearance]\n$want|" "$conf"
            fi
        fi
    done
    # Con --check, 1 = hay algo pendiente; al aplicar, 0 (ya quedo hecho).
    $check && return $pending
    return 0
}
