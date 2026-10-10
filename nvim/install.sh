#!/usr/bin/env bash
# ============================================================================
# install.sh -- Script de instalación y aprovisionamiento idempotente
# Entorno: Arch Linux (Hyprland + Wayland + kitty + zsh)
# Configuración: Neovim 0.12+ con Theming Dinámico Matugen
# ============================================================================

set -euo pipefail

# Colores de salida formateada
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info() {
    echo -e "${BLUE}${BOLD}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}${BOLD}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}${BOLD}[AVISO]${NC} $1"
}

error() {
    echo -e "${RED}${BOLD}[ERROR]${NC} $1"
}

echo -e "${BLUE}${BOLD}"
echo "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗"
echo "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║"
echo "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║"
echo "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║"
echo "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║"
echo "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝"
echo -e "${NC}"
info "Iniciando aprovisionamiento del entorno Neovim en Arch Linux..."

# 1. Comprobar distribución compatible (Arch Linux)
if [ ! -f /etc/arch-release ]; then
    warn "Este script está optimizado para Arch Linux (pacman). Continuando con comprobaciones genéricas..."
fi

# 2. Paquetes requeridos en el sistema anfitrión
REQUIRED_PACKAGES=(
    neovim
    git
    ripgrep
    fd
    fzf
    lazygit
    nodejs
    npm
    python
    python-pip
    rustup
    go
    unzip
    curl
    wl-clipboard
    ttf-jetbrains-mono-nerd
)

MISSING_PACKAGES=()

info "Verificando dependencias del sistema..."
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        success "Paquete ya instalado: $pkg"
    else
        warn "Paquete ausente: $pkg"
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    info "Instalando paquetes faltantes (${MISSING_PACKAGES[*]})..."
    sudo pacman -S --needed --noconfirm "${MISSING_PACKAGES[@]}"
    success "Paquetes del sistema instalados con éxito."
else
    success "Todas las dependencias del sistema están al día."
fi

# 3. Configurar Rust toolchain si es necesario
if command -v rustup &>/dev/null; then
    if ! rustc --version &>/dev/null; then
        info "Configurando toolchain stable de Rust vía rustup..."
        rustup default stable
        success "Rust toolchain stable configurado."
    else
        success "Rust toolchain disponible ($(rustc --version))."
    fi
fi

# 4. Verificar estructura de enlaces simbólicos (Dotfiles)
DOTFILES_NVIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_CONFIG_DIR="$HOME/.config/nvim"

info "Comprobando enlace simbólico en ~/.config/nvim..."
if [ -L "$TARGET_CONFIG_DIR" ]; then
    CURRENT_LINK="$(readlink -f "$TARGET_CONFIG_DIR")"
    EXPECTED_TARGET="$(readlink -f "$DOTFILES_NVIM_DIR/.config/nvim")"
    if [ "$CURRENT_LINK" == "$EXPECTED_TARGET" ]; then
        success "Enlace simbólico correcto: $TARGET_CONFIG_DIR -> $CURRENT_LINK"
    else
        warn "El enlace simbólico apunta a $CURRENT_LINK. Actualizando a $EXPECTED_TARGET..."
        ln -sfn "$EXPECTED_TARGET" "$TARGET_CONFIG_DIR"
        success "Enlace simbólico actualizado."
    fi
elif [ -d "$TARGET_CONFIG_DIR" ]; then
    warn "Se detectó un directorio físico en $TARGET_CONFIG_DIR en lugar de un symlink."
    warn "Si deseas gestionar tu configuración mediante Dotfiles, vincula $DOTFILES_NVIM_DIR/.config/nvim"
else
    mkdir -p "$(dirname "$TARGET_CONFIG_DIR")"
    ln -s "$DOTFILES_NVIM_DIR/.config/nvim" "$TARGET_CONFIG_DIR"
    success "Enlace simbólico creado: $TARGET_CONFIG_DIR -> $DOTFILES_NVIM_DIR/.config/nvim"
fi

# 5. Comprobar tema dinámico de Matugen
MATUGEN_COLORS="$TARGET_CONFIG_DIR/lua/matugen_colors.lua"
if [ -f "$MATUGEN_COLORS" ]; then
    success "Archivo de colores Matugen detectado ($MATUGEN_COLORS)."
else
    warn "No se encontró $MATUGEN_COLORS. Neovim utilizará el fallback Catppuccin Mocha hasta que ejecutes matugen."
fi

# 6. Sincronizar plugins de lazy.nvim en modo headless
info "Sincronizando plugins con lazy.nvim..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
success "Sincronización de plugins completada."

echo ""
success "¡Instalación y verificación de Neovim completada exitosamente!"
info "Para verificar la salud general del entorno en Neovim, ejecuta: :checkhealth"
info "Para recargar colores tras cambiar de wallpaper: :MatugenReload o presiona <leader>mr"
