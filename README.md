# Dotfiles -- Hyprland

Config completa de Hyprland 0.56+ (API Lua `hl.*`) + stack de escritorio,
gestionada con [GNU Stow](https://www.gnu.org/software/stow/).
Pensada para: AMD Ryzen 5 8645HS (iGPU Radeon 760M) + NVIDIA RTX 3050 6GB
(iGPU siempre activa, NVIDIA solo on-demand).

## Instalacion rapida

```bash
git clone <este-repo> ~/Dotfiles && cd ~/Dotfiles
./install.sh
```

Automatiza paquetes, stow, la primera paleta de matugen y la shell por
defecto. Al final imprime 3 pasos manuales que no
se pueden automatizar a ciegas: tu identidad de git, la GPU hibrida
(bus PCI distinto por equipo) y SDDM (sudoers puntual con tu usuario). Los
pasos de abajo son la version detallada/manual de lo mismo, por si preferis
ir de a uno o algo falla.

## Stack

| Categoria | Herramienta |
|---|---|
| Compositor | Hyprland (config Lua modular) |
| Barra | Waybar |
| Launcher | Rofi (+ hyprlauncher como alternativa, `SUPER+SHIFT+D`) |
| Notificaciones | SwayNC |
| Lockscreen | Hyprlock |
| Login manager | SDDM (tema propio, ver `sddm/`) |
| Idle | Hypridle |
| Wallpaper | hyprpaper |
| Filtro de luz azul | hyprsunset |
| Polkit | hyprpolkitagent |
| Capturas | grim + slurp + satty |
| Grabacion | wf-recorder |
| Portapapeles | cliphist + wl-clip-persist |
| Color picker | hyprpicker |
| Selector de emoji | rofimoji (`SUPER + .`) |
| Spotify | spicetify + spicetify-marketplace (ver `spicetify/`) |
| Visualizador de audio | cava (colores dinamicos, ver seccion cava abajo) |
| System info / fetch | fastfetch (ver `fastfetch/`) |
| Multiplexor de terminal | zellij (colores dinamicos, ver seccion zellij abajo) |
| Markdown en terminal | glow (colores dinamicos, ver seccion glow abajo) |
| `du`/`df`/`ps` modernos | dust / duf / procs (heredan el ANSI de kitty, sin theming propio) |
| Cliente HTTP | xh (alias `http`) |
| Ejemplos de uso rapido | tealdeer (`tldr`) |
| Paleta de colores dinamica | matugen (Material You a partir del wallpaper) |

| Terminal | kitty |
| Explorador de archivos | Thunar |

## 1. Instalar paquetes

```bash
sudo pacman -S --needed waybar rofi swaync satty cliphist wl-clip-persist \
  hyprpolkitagent hyprshutdown hyprsunset hyprpicker hyprpaper hyprlock hypridle \
  qt5ct qt6ct nwg-look papirus-icon-theme ttf-jetbrains-mono-nerd rofimoji wtype \
  gvfs tumbler thunar network-manager-applet blueman pavucontrol playerctl \
  jq btop wireplumber pipewire-pulse pipewire-alsa stow gnome-themes-extra wf-recorder \
  matugen bluez-utils fzf zsh starship zoxide eza bat ttf-nerd-fonts-symbols-mono \
  yazi tdf fd imagemagick 7zip resvg cava fastfetch \
  dust duf procs tealdeer glow xh zellij \
  neovim nodejs npm ripgrep tree-sitter-cli spotify-launcher

yay -S --needed bibata-cursor-theme-bin papirus-folders spicetify-bin

# papirus-folders necesita una copia LOCAL del tema para no pedir sudo en
# cada cambio de wallpaper (matugen lo llama automaticamente, sin terminal).
# Papirus-Dark es en su mayoria symlinks relativos al tema base "Papirus"
# (ej. 48x48 -> ../Papirus/48x48), asi que hay que copiar los dos:
mkdir -p ~/.local/share/icons
cp -r /usr/share/icons/Papirus /usr/share/icons/Papirus-Dark ~/.local/share/icons/
```

`pipewire`/`wireplumber` son criticos: sin ellos no funciona el audio (`wpctl`)
ni el screen sharing. Si ya tenias `pipewire-media-session`, desinstalalo (conflictua).

## 2. GPU hibrida (AMD iGPU + NVIDIA)

La config ya fija `AQ_DRM_DEVICES` a `/dev/dri/gpu-amd:/dev/dri/gpu-nvidia`,
asi que Hyprland arranca siempre con la iGPU. Esos son alias sin `:` en el
nombre creados por la regla udev `/etc/udev/rules.d/71-gpu-drm-aliases.rules`
(necesaria porque `AQ_DRM_DEVICES` separa la lista con `:`, y las rutas
`/dev/dri/by-path/pci-0000:XX:00.0-card` ya traen `:` en el propio nombre,
lo que rompe el parseo de Aquamarine y hace crashear a Hyprland con
`CBackend::create() failed!`). Instalala asi si es un equipo nuevo:

```bash
sudo tee /etc/udev/rules.d/71-gpu-drm-aliases.rules <<'EOF'
SUBSYSTEM=="drm", KERNEL=="card[0-9]*", ENV{ID_PATH}=="pci-0000:06:00.0", SYMLINK+="dri/gpu-amd"
SUBSYSTEM=="drm", KERNEL=="card[0-9]*", ENV{ID_PATH}=="pci-0000:01:00.0", SYMLINK+="dri/gpu-nvidia"
EOF
sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=drm
```

(ajusta las direcciones PCI `pci-0000:06:00.0` / `pci-0000:01:00.0` si en tu
equipo la AMD y la NVIDIA estan en otro bus; verificalo con
`udevadm info -q property -n /dev/dri/card0 | grep ID_PATH` para cada card).

Para que el modeset de NVIDIA funcione bien (offload puntual, suspend/resume,
VA-API) falta habilitarlo:

```bash
echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf

# opcional pero recomendado: cargar amdgpu antes que nvidia en el initramfs
# para evitar cuelgues de ~1 min en apps Electron al bootear.
# Editar /etc/mkinitcpio.conf y dejar la linea MODULES asi:
#   MODULES=(amdgpu nvidia nvidia_modeset nvidia_uvm nvidia_drm)
sudo mkinitcpio -P

sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
```

Para correr algo puntual en la NVIDIA (juegos, Blender, etc.):

```bash
~/.config/hypr/scripts/nvidia-offload steam
# o en Steam: opciones de lanzamiento -> ~/.config/hypr/scripts/nvidia-offload %command%
```

El modulo `custom/gpu` de Waybar muestra si hay algo corriendo en la NVIDIA ahora mismo.

## 3. Aplicar la config con Stow

```bash
cd ~/Dotfiles
mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.bak  # backup del autogenerado
stow hypr waybar rofi swaync kitty gtk-3.0 gtk-4.0 qt5ct qt6ct zsh bat yazi nvim btop thunar matugen spicetify fastfetch git
```

Waybar, swaync, rofi, kitty (incluida la tab bar), hyprlock, GTK, Qt
(qt5ct/qt6ct), starship, yazi (flavor `matugen`, ver
`yazi/.config/yazi/theme.toml`), Neovim (colorscheme base16 propio, ver
`nvim/.config/nvim/lua/plugins/colorscheme.lua`), btop (theme `matugen`),
satty (100% generado, `~/.config/satty/config.toml`, no trackeado en el
repo -- igual que starship), cava (100% generado, `~/.config/cava/config`,
tampoco trackeado -- ver seccion `### cava` abajo), fastfetch (via ANSI de
kitty + alias generado, ver `### fastfetch` abajo), zellij (100% generado,
ver `### zellij` abajo), glow (via `GLOW_STYLE`, ver `### glow` abajo), SDDM,
los iconos de carpeta de Papirus-Dark y los bordes de Hyprland
toman su paleta de un
wallpaper via matugen (`matugen/.config/matugen/`) en vez de tener los
colores hardcodeados. `bat` no necesita template propio: usa el tema
`ansi`, que delega el color a los 16 colores ANSI que ya define kitty.
`~/.config/starship.toml` es 100% generado por matugen (no
esta trackeado en el repo, solo el template en
`matugen/.config/matugen/templates/starship.toml`). Despues del `stow` hay que
generarla una vez a mano, si no `@import`/`include`/`source`/`require`/
`color_scheme_path` de esas apps apuntan a archivos que todavia no existen:

```bash
matugen image ~/Pictures/Wallpapers/imagen_161.png
```

Para cambiar de wallpaper (y recolorear todo junto) usa `SUPER+SHIFT+W`
(`hypr/.config/hypr/scripts/wallpaper-selector.sh`), que aplica el fondo con
hyprpaper, corre `matugen image` con el wallpaper elegido y regenera
`~/.face` -- la imagen "de usuario" que dibuja hyprlock arriba del reloj de
palabras (`image { path = ~/.face }` en `hyprlock.conf`) -- como un recorte
cuadrado centrado (512x512, via `magick`) del mismo wallpaper. No hace falta
poner una foto real: el avatar del lockscreen cambia solo junto con el resto
del theming. Si preferis una foto tuya en vez del recorte del wallpaper,
sobreescribi `~/.face` a mano despues de cambiar de fondo (el selector la
va a volver a pisar en el proximo cambio).

Shell: zsh (con [zinit](https://github.com/zdharma-continuum/zinit) para
plugins -- se clona solo la primera vez que abris una terminal, no hace
falta instalarlo a mano). Para que sea la shell por defecto:

```bash
chsh -s /usr/bin/zsh
```

Neovim: config modular en `nvim/.config/nvim/lua/` (lazy.nvim + mason/LSP +
treesitter + telescope + blink.cmp + gitsigns + lualine/which-key +
flash.nvim (navegacion, ver `keys` en `lua/plugins/flash.lua` -- pisa
`s`/`S`/`r`/`R` a proposito) + render-markdown.nvim + yazi.nvim como
explorador + snacks.nvim (dashboard, notificaciones, indent guides, zen
mode con `<leader>z`)).
`lazy.nvim` se clona e instala todo solo la primera vez que abris `nvim`
(tarda un rato). LSP servers (`lua_ls`, `bashls`, `pyright`, `jsonls`,
`yamlls`, `marksman`, `taplo`) y formatters (`stylua`, `shfmt`) se instalan
solos via mason -- `bashls`/`pyright`/`jsonls`/`yamlls` necesitan
`nodejs`/`npm`, ya estan en la lista de arriba. `nvim-treesitter` esta
fijado a la branch `main` (`master` esta congelada y no soporta Neovim
0.12+) y necesita `tree-sitter-cli` para compilar parsers -- tambien ya
esta en la lista.

### cava

`~/.config/cava/config` es 100% generado por matugen (no esta trackeado en
el repo, solo el template en `matugen/.config/matugen/templates/cava.conf`)
-- cava no soporta `include`/import para separar colores del resto de la
config. `background`/`foreground` quedan en `'default'` para que se vea el
fondo con blur de la terminal detras (mismo mecanismo que
`background_opacity` en `kitty.conf`) en vez de un fondo solido, y el
gradiente reutiliza el mismo esquema "semaforo" verde -> amarillo -> rojo
que ya usa `btop.theme` (grave -> agudo en vez de bajo -> alto uso). Si
cava ya esta corriendo, el `post_hook` del template le manda `SIGUSR2` para
recargar solo los colores (sin reiniciar el analisis de audio) en cada
cambio de wallpaper.

### fastfetch

A diferencia de cava, `~/.config/fastfetch/config.jsonc` (paquete stow
propio, `fastfetch/`) es un archivo real y estatico -- se edita a mano sin
tocar matugen. El diseño actual (estilo "Catnap", caja dibujada a mano con
`key` custom por modulo) colorea cada linea con codigos ANSI crudos
(`{#31}`, `{#34}`, `{#35}`...) que resuelven contra la paleta `color0-15`
que matugen le genera a kitty (`kitty/colors.conf`) -- mismo mecanismo de
delegacion que ya usa `bat` con su tema `ansi`, cambia el wallpaper y
cambian los colores sin regenerar nada. Tambien existe un
`alias fastfetch=...` generado por matugen en
`~/.cache/matugen/fastfetch-opts.sh` (sourceado desde `.zshrc`, mismo patron
que `fzf-opts.sh`) con flags `--logo-color-N`/`--color-*`; con el logo
desactivado (`"type": "none"`) solo le pone color al texto de valor
(columna derecha) via `--color-output`. Se abre solo al abrir una terminal
nueva (ultima linea de `.zshrc`).

### zellij

`~/.config/zellij/config.kdl` es 100% generado por matugen (no esta
trackeado en el repo, no hay paquete stow `zellij/` -- solo el template en
`matugen/.config/matugen/templates/zellij-config.kdl`). zellij soporta
`theme_dir` para cargar temas desde archivos sueltos (como el flavor.toml de
yazi), pero esa directiva no expande `~`/`$HOME` (probado: tira `IoError` si
no es una ruta absoluta literal) -- como este repo tiene que servir para
cualquier `$HOME`, el theme va embebido directo en el config completo en vez
de un archivo separado. Los colores van en RGB decimal (`fg 227 225 233`),
no hex -- formato real de zellij 0.45, verificado con
`zellij setup --dump-config`. zellij corre un servidor por sesion: una
sesion ya abierta no recoge un cambio de wallpaper hasta reiniciarla
(`zellij kill-all-sessions -y`); las sesiones nuevas si toman los colores
actualizados.

### glow

El estilo de glow (`glow-style.json`, formato de
[glamour](https://github.com/charmbracelet/glamour)) tambien es 100%
generado por matugen, basado en el `dark.json` oficial de glamour con los
campos de color reemplazados. La clave `style` de `~/.config/glow/glow.yml`
resulta no funcionar (probado, glow la ignora en silencio) -- la variable de
entorno `GLOW_STYLE` si, asi que `.zshrc` la exporta apuntando siempre a
`~/.cache/matugen/glow-style.json`. Un detalle no obvio del propio template:
glamour usa `{{.text}}` como placeholder interno en el campo `format` de
`image_text`, que choca con la sintaxis `{{ }}` de matugen (rompe el parseo
de TODO el archivo, no solo esa linea) -- esta escapado en el template como
`\u007b\u007b.text\u007d\u007d` (unicode escape de JSON -- sin llaves
literales en el template, matugen ni se entera -- que se decodifica de
vuelta a llaves reales cuando glow parsea el JSON generado) para que
matugen no intente interpretarlo como una variable propia.

### Spotify (spicetify + Marketplace)

`user.css` parte de [catppuccin/spicetify](https://github.com/catppuccin/spicetify)
(MIT, ver `spicetify/.config/spicetify/Themes/matugen/LICENSE-catppuccin`) --
la base de catppuccin queda sin cambios, solo consume las variables
`--spice-*` que spicetify genera a partir de `color.ini`. Ese `color.ini`
es 100% generado por matugen (un unico esquema `[matugen]`, no los 4
sabores fijos de catppuccin). No se porto `theme.js` (selector manual de
color de acento): dependia de 14 GIFs de ecualizador pre-generados por
acento fijo, que no encaja con un esquema dinamico de un solo acento -- el
unico efecto es que el icono animado de "reproduciendo ahora" no anima, el
resto del tema no se ve afectado.

Encima de esa base, personalizacion propia (seccion final de `user.css`,
por separado de lo heredado de catppuccin):
- Fuente JetBrainsMono Nerd Font Propo en toda la UI (`--encore-*-font-stack`,
  variables reales confirmadas grep-eando el CSS ya parcheado de Spotify --
  no estan documentadas por spicetify).
- Barra de reproduccion con `backdrop-filter: blur()` (esto es CSS normal
  que Chromium/Electron si puede hacer sobre su propio contenido -- no
  tiene nada que ver con que Hyprland no pueda blurear detras de la
  ventana de Spotify, son dos cosas distintas).
- Portadas de album con el mismo `border-radius` que las ventanas de
  Hyprland (`decoration.rounding`, `lookandfeel.lua`).
- Barra de progreso y boton de play con el color de acento en vez del gris
  por defecto.

A diferencia del resto, spicetify no lee `color.ini` en vivo: lo "hornea"
dentro de los archivos ya parcheados de Spotify recien al correr
`spicetify apply` (lo hace solo el `post_hook` del template en cada cambio
de wallpaper). Si Spotify ya estaba abierto, hay que cerrarlo y volver a
abrirlo para ver los colores nuevos.

Setup inicial (una sola vez, despues del primer `matugen image`):

```bash
spicetify config current_theme matugen color_scheme matugen
spicetify apply
```

Marketplace (para instalar temas/extensiones community desde la propia UI
de Spotify) via el instalador oficial -- solo toca `~/.config/spicetify/`,
sin sudo:

```bash
curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.sh | sh
```

(el instalador respeta el `current_theme` que ya configuraste arriba --
solo pisa el tema si no hay ninguno seteado).

### SDDM (pantalla de login)

Tema propio (`sddm/theme/`, adaptado de
[catppuccin/sddm](https://github.com/catppuccin/sddm) -- MIT, ver
`sddm/theme/LICENSE-catppuccin`) recoloreado por matugen. A diferencia de
todo lo demas, SDDM corre como servicio de sistema (usuario `sddm`, antes
del login), no como vos, asi que necesita un paso de setup con sudo. Una
vez hecho, se recolorea solo en cada cambio de wallpaper, igual que el
resto (via `sudo -n` a un script puntual, no sudo sin restricciones -- ver
el comentario en `matugen/.config/matugen/config.toml`, template
`sddm-sleepbutton`):

```bash
# Copia root-owned del script (el sudoers NO apunta al de este repo, que
# vos podes editar -- si no, NOPASSWD equivaldria a sudo sin restricciones)
sudo install -m 755 -o root -g root \
  hypr/.config/hypr/scripts/sync-sddm-theme.sh /usr/local/bin/sync-sddm-theme

# Regla de sudoers, acotada a ESE script puntual -- validar con visudo antes
# de instalar cualquier cambio de sudoers, un error ahi rompe sudo entero:
echo 'h3n ALL=(root) NOPASSWD: /usr/local/bin/sync-sddm-theme' > /tmp/matugen-sddm-sudoers
visudo -c -f /tmp/matugen-sddm-sudoers && \
  sudo install -m 440 -o root -g root /tmp/matugen-sddm-sudoers /etc/sudoers.d/matugen-sddm
rm /tmp/matugen-sddm-sudoers

# Genera el tema por primera vez y lo activa
sudo /usr/local/bin/sync-sddm-theme
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=dotfiles-matugen\n' | sudo tee /etc/sddm.conf.d/theme.conf
```

Si editas `sync-sddm-theme.sh`, hay que repetir el primer `install` para
que el cambio aplique (la copia en `/usr/local/bin` es la que realmente
corre, no la del repo).

## 4. Relogueate

Cerra sesion y volve a entrar (SDDM) para que las variables de entorno
(cursor, Qt, GPU) se apliquen desde cero. `hyprctl reload` alcanza para
cambios de binds/reglas/apariencia, pero no para `hl.env(...)`.

`qt5ct.conf`/`qt6ct.conf` ya vienen configurados (paleta custom apuntando al
esquema de matugen, iconos Papirus-Dark, estilo Fusion) -- no hace falta
correr `qt5ct`/`qt6ct` a mano salvo que quieras retocar algo mas (fuente,
efectos, etc.), en cuyo caso la GUI lee y guarda sobre el mismo archivo.

## Atajos principales

| Atajo | Accion |
|---|---|
| `SUPER + Return` | Terminal (kitty) |
| `SUPER + D` | Launcher (rofi) |
| `SUPER + SHIFT + D` | Launcher alterno (hyprlauncher) |
| `SUPER + Tab` | Selector de ventanas |
| `SUPER + E` | Explorador de archivos (thunar) |
| `SUPER + Q` / `SHIFT+Q` | Cerrar / forzar cierre de ventana |
| `SUPER + V` | Flotar ventana |
| `SUPER + F` | Fullscreen |
| `SUPER + SHIFT + P` | Fijar ventana (pin) |
| `SUPER + G` | Agrupar ventanas |
| `SUPER + flechas` | Cambiar foco |
| `SUPER + SHIFT + flechas` | Mover ventana |
| `SUPER + CTRL + flechas` | Redimensionar (o `SUPER+R` -> submap resize) |
| `SUPER + [0-9]` / `SHIFT+[0-9]` | Ir a / mover a workspace |
| `SUPER + S` / `SHIFT+S` | Scratchpad (workspace especial) |
| `SUPER + ALT + L` | Ciclar layout dwindle/master/scrolling |
| `SUPER + L` | Bloquear pantalla |
| `SUPER + M` | Menu de energia (bloquear/suspender/cerrar sesion/reiniciar/apagar) |
| `SUPER + SHIFT + M` | Salida forzada de Hyprland (sin confirmar) |
| `SUPER + N` / `SHIFT+N` | Panel de notificaciones / limpiar todo |
| `SUPER + SHIFT + C` | Color picker |
| `SUPER + .` | Selector de emoji (rofimoji) |
| `SUPER + SHIFT + V` | Historial de portapapeles |
| `SUPER + SHIFT + W` | Selector de wallpaper (recolorea todo con matugen) |
| `Print` / `SUPER+Print` / `SUPER+SHIFT+Print` | Captura completa / region / ventana |
| `SUPER + ALT + R` | Grabar pantalla (toggle) |

Ver `hypr/.config/hypr/modules/binds.lua` para la lista completa.
