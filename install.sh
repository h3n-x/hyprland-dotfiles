#!/bin/bash
# Instalador de este dotfiles (Hyprland + matugen). Pensado para Arch/pacman.
#
# Que SI automatiza: paquetes (pacman/yay), copia de iconos Papirus-Dark,
# stow de toda la config, primer `matugen image` (con un wallpaper semilla
# si todavia no elegiste ninguno), perfil de LibreWolf, spicetify + Marketplace
# para Spotify, shell por defecto.
#
# Que NO automatiza (se imprime como instrucciones al final, ver README):
# SDDM, Plymouth, GRUB y la GPU hibrida AMD+NVIDIA. Necesitan sudo con
# pasos que varian por equipo (bus PCI de cada GPU, usuario NOPASSWD
# puntual, HOOKS/bootloader/particionado de cada quien) -- no es sensato
# meterlos en un script que alguien mas va a correr a ciegas.
#
# Idempotente: correrlo de nuevo no rompe nada ya instalado.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m!!\033[0m %s\n' "$1"; }
ok()    { printf '\033[1;32m✓\033[0m %s\n' "$1"; }

command -v pacman >/dev/null 2>&1 || {
  echo "Este instalador es para Arch/pacman. Segui el README a mano en otra distro." >&2
  exit 1
}

# -----------------------------------------------------------------------
# 1. Paquetes
# -----------------------------------------------------------------------
info "Instalando paquetes (pacman)..."
sudo pacman -S --needed --noconfirm waybar rofi swaync satty cliphist wl-clip-persist \
  hyprpolkitagent hyprshutdown hyprsunset hyprpicker hyprpaper hyprlock hypridle \
  qt5ct qt6ct nwg-look papirus-icon-theme ttf-jetbrains-mono-nerd rofimoji wtype \
  gvfs tumbler thunar network-manager-applet blueman pavucontrol playerctl \
  jq btop wireplumber pipewire-pulse pipewire-alsa stow gnome-themes-extra wf-recorder \
  matugen bluez-utils fzf zsh starship zoxide eza bat ttf-nerd-fonts-symbols-mono \
  yazi tdf fd imagemagick 7zip resvg cava fastfetch \
  dust duf procs tealdeer glow xh zellij plymouth \
  neovim nodejs npm ripgrep tree-sitter-cli spotify-launcher

if command -v yay >/dev/null 2>&1; then
  info "Instalando paquetes AUR (yay)..."
  yay -S --needed --noconfirm bibata-cursor-theme-bin papirus-folders spicetify-bin
else
  warn "yay no esta instalado -- omitiendo bibata-cursor-theme-bin y papirus-folders."
  warn "Instalalos a mano despues (necesitas un AUR helper): yay -S bibata-cursor-theme-bin papirus-folders"
fi

# papirus-folders necesita una copia LOCAL del tema para no pedir sudo en
# cada cambio de wallpaper (matugen lo llama automaticamente, sin terminal).
# Papirus-Dark es en su mayoria symlinks relativos a Papirus, hay que copiar
# los dos.
if [ -d /usr/share/icons/Papirus ] && [ ! -d ~/.local/share/icons/Papirus ]; then
  info "Copiando tema de iconos Papirus a ~/.local/share/icons (para papirus-folders sin sudo)..."
  mkdir -p ~/.local/share/icons
  cp -r /usr/share/icons/Papirus /usr/share/icons/Papirus-Dark ~/.local/share/icons/
fi

# -----------------------------------------------------------------------
# 2. Stow
# -----------------------------------------------------------------------
info "Aplicando config con stow..."

if [ -f ~/.config/hypr/hyprland.lua ] && [ ! -L ~/.config/hypr/hyprland.lua ]; then
  info "Backup de ~/.config/hypr/hyprland.lua (autogenerado) -> hyprland.lua.bak"
  mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.bak
fi

# "git" queda afuera del stow automatico a proposito: git/.gitconfig trae
# la identidad (nombre/email) de quien armo este repo -- stowearlo sin
# preguntar le pisaria la identidad de git a cualquier otra persona que
# clone esto. Editalo primero, despues `stow git` a mano.
stow hypr waybar rofi swaync kitty gtk-3.0 gtk-4.0 qt5ct qt6ct zsh bat yazi nvim btop thunar matugen spicetify fastfetch
ok "Stow aplicado (excepto 'git', ver nota al final)."

# -----------------------------------------------------------------------
# 3. Primer wallpaper + matugen
# -----------------------------------------------------------------------
info "Generando la paleta de colores por primera vez..."

WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLPAPERS_DIR"

seed=$(find "$WALLPAPERS_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | sort | head -1)

if [ -z "$seed" ]; then
  warn "No hay ningun wallpaper en $WALLPAPERS_DIR -- genero uno de relleno para arrancar."
  seed="$WALLPAPERS_DIR/matugen-seed.png"
  magick -size 1920x1080 gradient:'#1a1a2e-#8b5cf6' "$seed"
fi

matugen image "$seed" --prefer saturation
ok "Paleta generada a partir de $(basename "$seed"). Cambiala cuando quieras con SUPER+SHIFT+W."

# ~/.face: imagen "de usuario" que dibuja hyprlock (ver hyprlock.conf).
# Recorte cuadrado centrado del wallpaper semilla -- wallpaper-selector.sh
# la regenera igual en cada cambio de fondo, ver README.
if command -v magick >/dev/null 2>&1; then
  magick "$seed" -gravity center -resize 512x512^ -extent 512x512 ~/.face
  ok "~/.face generado a partir de $(basename "$seed")."
fi

# -----------------------------------------------------------------------
# 4. LibreWolf
# -----------------------------------------------------------------------
if command -v librewolf >/dev/null 2>&1; then
  if [ -f "$HOME/.config/librewolf/librewolf/profiles.ini" ]; then
    info "Vinculando perfil de LibreWolf..."
    "$REPO_DIR/librewolf/link-profile.sh"
  else
    warn "LibreWolf esta instalado pero nunca corrio -- abrilo una vez y despues corre:"
    warn "  $REPO_DIR/librewolf/link-profile.sh"
  fi
else
  warn "LibreWolf no esta instalado -- omitiendo. Instalalo (fuera de los repos oficiales de Arch) y corre:"
  warn "  $REPO_DIR/librewolf/link-profile.sh"
fi

# -----------------------------------------------------------------------
# 5. Spotify (spicetify + Marketplace)
# -----------------------------------------------------------------------
if command -v spicetify >/dev/null 2>&1; then
  info "Configurando spicetify (tema matugen)..."
  spicetify config current_theme matugen color_scheme matugen >/dev/null
  spicetify apply >/dev/null 2>&1 || warn "spicetify apply fallo -- corre 'spicetify apply' a mano para ver el error."

  if [ ! -d "$HOME/.config/spicetify/CustomApps/marketplace" ]; then
    info "Instalando spicetify-marketplace..."
    curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.sh | sh >/dev/null 2>&1 \
      || warn "Fallo la instalacion de Marketplace -- corre el instalador a mano (ver README)."
  fi
  ok "spicetify configurado. Si Spotify ya estaba abierto, cerralo y volve a abrirlo para ver los colores."
else
  warn "spicetify no esta instalado (es AUR: spicetify-bin) -- omitiendo. Instalalo y corre:"
  warn "  spicetify config current_theme matugen color_scheme matugen && spicetify apply"
fi

# -----------------------------------------------------------------------
# 6. tealdeer (necesita bajar el cache de paginas la primera vez)
# -----------------------------------------------------------------------
if command -v tldr >/dev/null 2>&1; then
  tldr --update >/dev/null 2>&1 && ok "Cache de tealdeer (tldr) actualizado." \
    || warn "No se pudo actualizar el cache de tldr -- corre 'tldr --update' a mano."
fi

# -----------------------------------------------------------------------
# 7. Shell por defecto
# -----------------------------------------------------------------------
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
  info "Cambiando la shell por defecto a zsh (te va a pedir tu contraseña)..."
  chsh -s "$(command -v zsh)" || warn "No se pudo cambiar la shell -- corre 'chsh -s $(command -v zsh)' a mano."
else
  ok "zsh ya es la shell por defecto."
fi

# -----------------------------------------------------------------------
# Resumen final
# -----------------------------------------------------------------------
cat <<EOF

────────────────────────────────────────────────────────────────────────
✓ Instalacion base completa. Faltan 5 cosas manuales:

1. git/.gitconfig -- tiene MI identidad (nombre/email), no la tuya:
     nvim $REPO_DIR/git/.gitconfig   # cambia [user] name/email
     stow git

2. GPU hibrida AMD+NVIDIA (si tu equipo tiene las dos) -- los bus PCI son
   distintos en cada maquina, hay que verificarlos a mano. Ver seccion
   "2. GPU hibrida" del README.

3. SDDM (pantalla de login) -- necesita una regla de sudoers puntual con
   TU usuario ($USER), no se puede automatizar sin pedirte la contraseña
   a ciegas. Ver seccion "SDDM (pantalla de login)" del README -- son 4
   comandos, copiar/pegar.

4. Plymouth (splash de arranque) -- opcional. Necesita otra regla de
   sudoers puntual, editar HOOKS de mkinitcpio.conf y agregar "splash" al
   cmdline del kernel (el archivo exacto depende de si tu equipo usa UKI o
   el esquema clasico -- ver seccion "Plymouth" del README) -- pasos con
   sudo que varian segun tu bootloader, por eso tampoco se automatizan.

5. GRUB (menu de arranque, opcional) -- theme propio con matugen, mas
   otra regla de sudoers puntual y (si GRUB no esta bien instalado en tu
   equipo) un `grub-install`/`grub-mkconfig`. Muy especifico de cada
   maquina (bootloader, ESP, particionado) -- ver seccion "GRUB" del
   README, con cuidado.

Despues de eso: cerra sesion y volve a entrar para que las variables de
entorno (cursor, Qt, GPU) se apliquen desde cero.
────────────────────────────────────────────────────────────────────────
EOF
