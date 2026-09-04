# ============================================================================
# zsh
# ============================================================================

# ---- Historial ----
HISTFILE="$HOME/.local/state/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt SHARE_HISTORY APPEND_HISTORY INC_APPEND_HISTORY

# ---- Opciones generales ----
setopt AUTO_CD CORRECT INTERACTIVE_COMMENTS
setopt COMPLETE_IN_WORD ALWAYS_TO_END

# ---- Completions ----
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ---- zinit (plugin manager -- lazy/turbo, sin daemon) ----
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-completions

# ---- Herramientas modernas ----
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ---- Alias ----
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza --icons --group-directories-first -la'
  alias lt='eza --icons --group-directories-first --tree --level=2'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah --color=auto'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
fi

command -v dust >/dev/null 2>&1 && alias du='dust'
command -v duf >/dev/null 2>&1 && alias df='duf'
command -v procs >/dev/null 2>&1 && alias ps='procs'
command -v xh >/dev/null 2>&1 && alias http='xh'

# glow: glow.yml no soporta un "style" que funcione, GLOW_STYLE si -- ver
# matugen/.config/matugen/templates/glow-style.json.
[ -f ~/.cache/matugen/glow-style.json ] && export GLOW_STYLE=~/.cache/matugen/glow-style.json

alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
command -v zoxide >/dev/null 2>&1 && alias cd='z'

alias dotfiles='cd ~/Dotfiles'
alias reload-waybar='killall -SIGUSR2 waybar'

# fastfetch: alias con los colores del wallpaper actual, generado por
# matugen (ver matugen/.config/matugen/templates/fastfetch-opts.sh).
[ -f ~/.cache/matugen/fastfetch-opts.sh ] && source ~/.cache/matugen/fastfetch-opts.sh

# ---- yazi: "y" en vez de "yazi" para que al salir te deje en el
# directorio donde navegaste (integracion oficial recomendada por yazi) ----
if command -v yazi >/dev/null 2>&1; then
  function y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi


export PATH="$HOME/.local/bin:$PATH"

# ---- ver imagenes sueltas en la terminal (kitten icat, ya incluido) ----
command -v kitty >/dev/null 2>&1 && alias icat='kitten icat'

# ---- fastfetch al abrir una terminal nueva (usa el alias con colores de
# matugen definido mas arriba, no el binario pelado) ----
command -v fastfetch >/dev/null 2>&1 && fastfetch
