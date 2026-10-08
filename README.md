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
defecto. Al final imprime los pasos manuales que no se pueden automatizar
a ciegas: tu identidad de git, la GPU hibrida (bus PCI distinto por
equipo), y SDDM/Plymouth/GRUB (cada uno necesita su propio sudoers
puntual con tu usuario, y GRUB ademas depende del bootloader/particionado
especifico de tu equipo). Los pasos de abajo son la version
detallada/manual de lo mismo, por si preferis ir de a uno o algo falla.

## Stack

| Categoria | Herramienta |
|---|---|
| Compositor | Hyprland (config Lua modular) |
| Barra | Quickshell (QML, ver seccion Quickshell abajo) |
| Launcher | Quickshell (`SUPER+D`, ver seccion Quickshell abajo) |
| Selector de ventanas | Quickshell (`SUPER+TAB`) |
| Notificaciones + control center | Quickshell (ver seccion Quickshell abajo) |
| Lockscreen | Quickshell (`dotshell/lock.qml`, vigilado por `scripts/lock`); hyprlock solo de emergencia |
| Login manager | SDDM (tema propio, ver `sddm/`) |
| Splash de arranque | Plymouth (colores dinamicos, ver seccion Plymouth abajo) |
| Menu de arranque | GRUB (theme propio con matugen, ver seccion GRUB abajo) |
| Idle | Hypridle |
| Wallpaper | hyprpaper |
| Filtro de luz azul | hyprsunset (horario o del atardecer al amanecer, desde Configuracion -> Pantallas) |
| Polkit | hyprpolkitagent |
| Capturas | grim + slurp (pantalla congelada con hyprpicker, opcional) + satty, vista previa de Quickshell |
| Grabacion | wf-recorder con VA-API (Radeon), pill de Quickshell |
| Visor / reproductor | Loupe / mpv (apps por defecto de imagenes y video) |
| Portapapeles | panel de Quickshell (`SUPER + SHIFT + V`) sobre cliphist + wl-clip-persist |
| Color picker | hyprpicker |
| Selector de emoji | panel de Quickshell (`SUPER + .`), datos Unicode/CLDR en español e inglés |
| Dashboard | Quickshell (`SUPER + A`): inicio, hoy (calendario y clima), sistema y escritorios |
| Multimedia | reproductor de Quickshell (pill de la barra, dashboard y teclas multimedia) |
| Calendario y clima | vista Hoy del dashboard (clima de Open-Meteo, ubicacion elegida a mano) |
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
sudo pacman -S --needed satty cliphist wl-clip-persist \
  hyprpolkitagent hyprshutdown hyprsunset hyprpicker hyprpaper hyprlock hypridle \
  qt5ct qt6ct nwg-look papirus-icon-theme ttf-jetbrains-mono-nerd noto-fonts-emoji python-pillow python-gobject xdg-desktop-portal-gtk wtype \
  gvfs tumbler thunar network-manager-applet blueman pavucontrol brightnessctl \
  jq btop wireplumber pipewire-pulse pipewire-alsa stow gnome-themes-extra wf-recorder mpv loupe \
  matugen quickshell bluez-utils fzf zsh starship zoxide eza bat ttf-nerd-fonts-symbols-mono ttf-material-symbols-variable \
  yazi tdf fd imagemagick 7zip resvg cava fastfetch pacman-contrib \
  dust duf procs tealdeer glow xh zellij plymouth \
  neovim nodejs npm ripgrep tree-sitter-cli spotify-launcher

yay -S --needed bibata-cursor-theme-bin papirus-folders spicetify-bin
# Fuentes del design system: Plus Jakarta Sans (interfaz) y Maple Mono NF
# (codigo/terminal, con glyphs Nerd Font)
yay -S --needed ttf-plus-jakarta-sans maplemono-nf

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

Para ver si hay algo corriendo en la NVIDIA ahora mismo: `nvidia-smi --query-compute-apps=pid,process_name --format=csv,noheader`
(o la vista Sistema del dashboard, `SUPER + A` y `S`, que muestra su estado sin despertarla).

## 3. Aplicar la config con Stow

```bash
cd ~/Dotfiles
mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.bak  # backup del autogenerado
stow hypr quickshell kitty gtk-3.0 gtk-4.0 qt5ct qt6ct zsh bat yazi nvim btop thunar matugen spicetify fastfetch git
```

Quickshell (ver seccion Quickshell abajo -- barra, notificaciones Y
control center, y la pantalla de bloqueo), kitty (incluida la tab bar), GTK, Qt
(qt5ct/qt6ct), starship, yazi (flavor
`matugen`, ver `yazi/.config/yazi/theme.toml`), Neovim (colorscheme
base16 propio, ver `nvim/.config/nvim/lua/plugins/colorscheme.lua`), btop
(theme `matugen`), satty (100% generado, `~/.config/satty/config.toml`,
no trackeado en el repo -- igual que starship), cava (100% generado,
`~/.config/cava/config`, tampoco trackeado -- ver seccion `### cava`
abajo), fastfetch (via ANSI de kitty + alias generado, ver `### fastfetch`
abajo), zellij (100% generado, ver `### zellij` abajo), glow (via
`GLOW_STYLE`, ver `### glow` abajo), SDDM, los iconos de carpeta de
Papirus-Dark y los bordes de Hyprland toman su paleta de un
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

Para cambiar de wallpaper (y recolorear todo junto) usa `SUPER+SHIFT+W`: la
galeria de Quickshell (busqueda, etiquetas, favoritos, recientes, vista
previa con `Espacio` y opciones de color por wallpaper o para todos).
`SUPER+SHIFT+Z` vuelve al tema anterior. Todo pasa por
`hypr/.config/hypr/scripts/theme-apply.sh`, que tambien sirve desde una
terminal (por ejemplo si Quickshell no esta corriendo):

```bash
~/.config/hypr/scripts/theme-apply.sh ~/Pictures/Wallpapers/imagen_161.png
```

Ademas regenera `~/.face` -- la imagen "de usuario" que dibujan la
pantalla de bloqueo (arriba del campo de contrasena), la de inicio de
sesion y Plymouth -- como un recorte cuadrado centrado (512x512, via
`magick`) del mismo wallpaper: el avatar cambia solo junto con el resto del
theming. Para usar una foto tuya: centro de configuracion (`SUPER+I`),
Apariencia, Avatar, "Imagen propia" y "Elegir…". Se recorta igual, se aplica
al momento en el bloqueo (y en el login y el arranque con el pase del
sistema, un minuto despues) y los cambios de fondo ya no la pisan
(`theme-apply.sh --face` la rehace a mano).

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
gradiente grave -> agudo usa solo colores de identidad del wallpaper
(tertiary -> secondary -> primary): es decorativo, asi que no lleva colores
de estado (ver "Colores de estado" mas abajo). Si
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
que `fzf.sh`) con flags `--logo-color-N`/`--color-*`; con el logo
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

### Quickshell

La barra (`quickshell/.config/quickshell/dotshell/`) esta escrita en QML
sobre [Quickshell](https://quickshell.org) en vez de Waybar -- se lanza
con `qs -c dotshell` (autostart en `autostart.lua`). Reemplaza a Waybar del todo.

- **Colores**: matugen escribe `~/.cache/matugen/quickshell-colors.json`
  (plantilla `templates/quickshell-colors.json`) y `Colors.qml` lo lee y lo
  sigue solo, con transicion. `Colors.qml` es una `SemanticPalette`
  (`SemanticPalette.qml`, la unica capa semantica): los modulos usan alias
  con significado (`Colors.accent`, `Colors.warning`, `Colors.textMuted`...)
  y nunca los roles crudos de Material You.
- **Colores de estado** (Fase 8, P8.7): `danger`, `warning` y `success` son
  fijos -- no cambian con el wallpaper, el esquema ni el contraste, solo
  con el modo claro/oscuro. Los genera `hypr/.config/hypr/scripts/palette
  status` (semillas en `dotshell/data/palette.rules.json`) y `theme-apply.sh`
  los deja en `~/.cache/matugen/status.json` antes de cada matugen, que los
  importa para todas las plantillas (kitty, btop, nvim, zellij...: el verde,
  amarillo y rojo de la terminal son siempre los mismos). `palette check`
  valida el sistema de color (contrastes, colores fijos, colores literales en
  el QML, tabla semantica de las plantillas).
- **Estructura**: `shell.qml` (entry point + los `IpcHandler` de abajo),
  `modules/Bar.qml` (`PanelWindow`, una instancia por pantalla via
  `Variants` sobre `Quickshell.screens`; arma la disposicion que guarda
  `bar.layout`: izquierda, centro -- al centro de la pantalla de verdad -- y
  derecha), `modules/BarEntry.qml` (el modulo de cada id),
  `modules/Pill.qml` (contenedor redondeado reutilizable) y un archivo por
  modulo (`Workspaces`, `Mpris`,
  `Clock`, `Update`, `Network`, `Bluetooth`, `Tray`, `Microphone`,
  `Battery`, `IdleToggle`, `Power`). `Volume`/`Backlight` no tienen icono
  en la barra (a pedido del usuario, ver OSD abajo) -- se instancian
  igual, sin pantalla, directo en `shell.qml`, porque siguen siendo los
  que miran Pipewire/sysfs y disparan el OSD.
- **Dropdowns de red/bluetooth** (`modules/NetworkDropdown.qml` +
  `BluetoothDropdown.qml`): paneles propios en QML en vez de mandar a un
  menu fzf en una terminal -- lista de redes/dispositivos reales, click
  para conectar (red con campo de contraseña inline si hace falta via
  `WifiNetwork.connectWithPsk()`), toggle de wifi/bluetooth. `Tray.qml`
  filtra los ids `"nm-applet"`/`"blueman"` para no duplicar el icono.
- **Control center + notificaciones** (`modules/ControlCenter.qml` +
  `NotificationToast.qml` + `NotificationState.qml`): reemplaza a swaync
  del todo. `NotificationState.qml` envuelve un `NotificationServer`
  (servicio DBus `org.freedesktop.Notifications` -- por eso reemplaza a
  swaync en vez de convivir con el, solo un proceso puede ser el dueño a
  la vez) y expone el historial + una cola de toasts + "no molestar"
  (con DND activo, la notificación queda en el historial pero no
  aparece como toast). `ControlCenter.qml` reproduce lo que daba
  `swaync/config.json`: historial con "limpiar todo", grid de accesos
  rápidos (wifi/bluetooth/luz nocturna -- esta última es la misma opcion que
  Configuracion -> Pantallas, `display.nightLight.enabled`), perfil de energia y DND;
  el reproductor y el estado del equipo (incluida la NVIDIA) estan en el
  dashboard. `SUPER+N`/`SUPER+SHIFT+N` (ver
  `binds.lua`) reemplazan a `swaync-client -t -sw`/`-C`.
- **OSD** (`modules/Osd.qml` + `OsdState.qml`): popup temporal
  (icono + barra de nivel) para volumen/mic/brillo, reemplaza a los
  `notify-send` que se usaban antes para esto. Reactivo a cualquier
  origen del cambio (scroll, teclas de volumen/brillo del teclado,
  pavucontrol, etc.), no solo a un click en la barra -- justamente por
  eso `Volume`/`Backlight` necesitan seguir corriendo aunque no tengan
  icono. La bateria sigue con `notify-send` real para sus umbrales de
  warning/critical/full (esas SI tienen que persistir, no autoocultarse).
- **Reactividad real** (sin polling) via los servicios nativos de
  Quickshell: `Quickshell.Hyprland` (workspaces/eventos por el socket de
  Hyprland), `Quickshell.Services.Pipewire` (audio),
  `Quickshell.Services.UPower` (bateria), `Quickshell.Services.SystemTray`
  (bandeja -- StatusNotifierItem, muestra nm-applet/blueman-applet),
  `Quickshell.Services.Mpris` y `Quickshell.Wayland.IdleInhibitor`. CPU,
  memoria y temperatura no tienen servicio nativo (se leen de `/proc` y
  `sysfs` con `FileView`) asi que se sacaron de la barra por decision
  propia, no por limitacion tecnica de Quickshell.
- **Actualizaciones y mantenimiento** (`MaintenanceState.qml`,
  `hypr/.config/hypr/scripts/maintenance`): la pill de la barra solo informa
  (actualizaciones, al dia, error o reinicio pendiente; clic = actualizar en
  una terminal, clic derecho = revisar ya). La explicacion esta en la vista
  Mantenimiento del dashboard. Revisa al arrancar, cada hora y despues de cada
  operacion de pacman; cerrado no hace nada mas.
- **Menu de energia y sesion** (`modules/PowerMenu.qml`, `SUPER+M` y el
  boton de la barra): bloquear, suspender, cerrar sesion, reiniciar y apagar;
  las tres ultimas piden confirmacion y cierran las aplicaciones antes (via
  `hyprshutdown`).
- **Historial del portapapeles** (`modules/Clipboard.qml`, `SUPER+SHIFT+V`):
  lista con busqueda, filtros (Todo / Texto / Imagenes / Enlaces, `Tab`) y
  vista previa de texto e imagenes a la derecha. `Enter` copia, `Supr`
  borra, `Ctrl+P` pausa el historial (lo copiado no se guarda hasta
  reanudar; reiniciar lo reanuda), `Ctrl+Supr` vacia (con confirmacion).
  Lo guarda `hypr/.config/hypr/scripts/clipboard-store`, que corre delante
  de `cliphist` en los `wl-paste --watch` de `autostart.lua` y **no guarda**
  lo que parece sensible: claves privadas, tokens (GitHub, APIs, JWT),
  `PASSWORD=`/`SECRET=`/`TOKEN=` y cadenas con forma de contrasena, lo que
  una app marca como contrasena, las apps listadas en
  `hypr/.config/hypr/clipboard-exclude.conf` (vacia por defecto) e imagenes
  de mas de 10 MB. Lo copiado se pega igual; solo no entra al historial.
  Las vistas previas de imagen se decodifican en `$XDG_RUNTIME_DIR` (RAM) y
  se borran al cerrar el panel. `clipboard-store --scan` cuenta entradas
  sensibles viejas y `--purge-sensitive` las borra (solo imprime cuantas).
  Es la unica interfaz del historial.
- **Selector de emoji** (`modules/Emoji.qml` + `EmojiState.qml`,
  `SUPER+.`): rejilla con pestañas de categoria (Recientes, Caras, Personas,
  ...), busqueda por comienzo de palabra en espanol e ingles sin tildes
  (`gato`, `cat`, `corazon`), franja con el emoji grande y el tono de piel.
  `Enter` escribe el emoji en la ventana activa (`wtype`, sin copiarlo),
  `Ctrl+Enter` solo lo copia, `Tab` cambia de categoria, `Ctrl+T` o un clic
  en los puntos cambian el tono (global, se recuerda). Guarda los ultimos 30
  en `~/.local/state/dotfiles/emoji.json`. Los datos
  (`dotshell/data/emoji.json`, 1914 emojis) los genera a mano
  `hypr/.config/hypr/scripts/emoji-data` desde la lista oficial Unicode 17.0 y
  CLDR 48 (fijados por sha256; licencia en `data/LICENSE-unicode`). Para
  dibujar rapido usa un PNG por emoji en `~/.cache/dotfiles/emoji/72`, que
  `emoji-data --ensure-images` crea al iniciar el shell si faltan (≈ 20 s,
  necesita `python-pillow`); mientras tanto dibuja texto con Noto Color Emoji.
- **Launcher** (`modules/Launcher.qml` + `LauncherState.qml`, `SUPER+D`):
  campo de búsqueda con fuzzy match
  propio (subsecuencia, sin librería externa) sobre nombre/`genericName`/
  `keywords` de `Quickshell.DesktopEntries`, orden alfabético sin
  búsqueda, resaltado de lo que matchea, tamaño de ventana dinámico según
  cantidad de resultados.
- **Selector de ventanas** (`modules/Switcher.qml` + `SwitcherState.qml`,
  `SUPER+Tab`): tarjetas con vista previa de cada ventana (capturada una vez
  al abrir, tambien de otros workspaces), workspace (S = especial), icono y
  titulo, por uso reciente. Con Super apretado, `Tab` / `Shift+Tab` mueven y
  soltar Super cambia (un `SUPER+Tab` rapido vuelve a la ventana anterior);
  si Super ya se solto, flechas, `Enter` o clic, y escribir filtra. `Esc`
  cancela, `Supr` cierra la ventana elegida. Solo se capturan ventanas de al
  menos 24x24 (con muchas ventanas en un workspace algunas quedan con tamano
  negativo y capturarlas tumbaba el shell); las demas muestran el icono.
- **Reloj** (`modules/Clock.qml`): la hora (24 h) y, con una ubicacion
  elegida, el clima (icono y temperatura; atenuado si los datos son viejos o
  no se pudo actualizar). Solo informa: sin accion al clic.
- **Reproductor** (`MediaState.qml`, `modules/Mpris.qml`): la pill muestra el
  titulo y el estado (ecualizador sonando, pausa en pausa); clic central
  pausa. Las teclas multimedia (`binds.lua`) usan el mismo reproductor via
  `qs -c dotshell ipc call media next|previous|playPause`, tambien con la
  pantalla bloqueada. Se ignoran los reproductores "proxy" (playerctld).
- **Dashboard** (`modules/Dashboard.qml` y sus vistas, `DashboardState.qml`):
  el centro de la shell. **Se abre solo con `SUPER+A`** (ningun modulo de la
  barra lo abre), centrado bajo la barra del monitor enfocado; `Esc` o
  `SUPER+A` lo cierran. Una sola superficie con zonas, en cinco vistas:
  - **Inicio**: hora, fecha, avisos (actualizaciones y mantenimiento, que
    abren esa vista; notificaciones, no molestar; solo si los hay) y clima; el reproductor como protagonista
    mientras hay uno (portada grande, progreso con busqueda, cinco controles,
    transicion al cambiar de cancion); debajo, las **zonas**, que elegis vos
    (Fase 11 B4): de fabrica el estado general del equipo ("Todo en orden" y
    cuatro medidores) y los escritorios en miniatura; ademas el calendario del
    mes y las proximas horas del clima (con ciudad). Cada una compacta o
    ancha, en el orden que quieras, o ninguna. Sin musica, el reloj crece y
    el panel se acorta.
    **Editar Inicio**: el lapiz (al pasar el raton por las zonas), `Ctrl+E` o
    Configuracion -> Dashboard -> "Editar Inicio". Las zonas se ven con
    contorno punteado: arrastrar las ordena, el boton de tamano y la cruz;
    abajo, "Agregar". Con el teclado: `Tab` elige, flechas mueven, `T`
    tamano, `Supr` quita, `A` agregar (flechas + `Enter`), `Esc` / `Enter`
    terminan. Una zona que no esta no consulta nada.
  - **Hoy**: calendario del mes y el clima con una frase ("Sensacion 30°. Hoy
    entre 18° y 33°, sin lluvia a la vista."), las proximas 12 h y 5 dias. El
    clima viene de [Open-Meteo](https://open-meteo.com) (sin clave; datos
    CC BY 4.0) via `hypr/.config/hypr/scripts/weather-fetch` (cache en
    `~/.cache/dotfiles/weather.json`). **Sin ubicacion no se consulta nada**;
    la ciudad se elige aca (`C`) o en Configuracion -> Dashboard, se guarda
    solo en este equipo (`dashboard.weather.location` en
    `~/.config/dotfiles/settings.json`, fuera del repo) redondeada a ~10 km y
    se consulta cada 30 min. Grados en °C o °F (Configuracion).
  - **Sistema**: el estado en palabras, procesador, memoria, almacenamiento y
    energia (con el perfil), las aplicaciones que mas usan (agrupadas por
    aplicacion, no por proceso), la red y las graficas (la NVIDIA sin
    despertarla).
  - **Escritorios**: cada workspace como la pantalla real a escala (fondo,
    barra, gaps, bordes y la captura de cada ventana, tomada una vez al abrir
    la vista); clic en una ventana va a esa ventana, en el fondo al
    workspace.
  - **Mantenimiento**: primero si el sistema esta bien y que conviene hacer
    ("El sistema funciona correctamente, pero hay 2 elementos que requieren
    atencion."), despues lo que requiere atencion y lo recomendado, con cuatro
    severidades (informacion, recomendacion, advertencia, accion importante);
    lo que esta bien, en una sola linea. Actualizaciones, reinicio pendiente
    (kernel o driver NVIDIA), servicios caidos (se pueden ocultar), paquetes
    huerfanos, caches, papelera, diario y volcados de error. El detalle
    (paquetes, servicios, comandos exactos) solo al desplegar. **Las acciones
    abren una terminal visible** que muestra los comandos y pide
    confirmacion; `sudo` pide la contrasena ahi, nunca desde la shell.
  Teclado: `Tab` recorre las zonas de Inicio, `Enter` abre la vista de la
  zona, `H`/`S`/`E`/`M` abren Hoy/Sistema/Escritorios/Mantenimiento desde cualquier lugar,
  `Esc`/`Retroceso` vuelven; `1`-`9` van a ese workspace; con el foco en el
  reproductor, `Espacio`, flechas (-/+10 s), `N`/`P`. Cerrado no corre nada
  (ni muestreo del equipo ni seguimiento de ventanas); todo respeta "reducir
  movimiento".
- **Capturas y grabacion** (`CaptureState.qml`, `modules/CapturePreview.qml`,
  `modules/RecordingPill.qml`; scripts `screenshot`, `record`,
  `capture-select`): tras cada captura la zona destella, la imagen vuela a
  una tarjeta abajo a la derecha (6 s, en pausa con el puntero encima) con
  Anotar (satty sobre el mismo archivo), copiar, copiar la ruta, abrir,
  carpeta (Yazi con el archivo elegido) y papelera con Deshacer; doble clic en
  la miniatura = Anotar / Reproducir. La region se elige con la pantalla
  congelada (se puede apagar) y las ventanas como destino. Mientras se graba, una pill en la
  barra (tiempo, clic para parar) y marcas en las esquinas de la zona. Graba
  con VA-API en la Radeon (`LIBVA_DRIVER_NAME=radeonsi` solo para
  wf-recorder).
- **Binds** (`binds.lua`): `SUPER+SHIFT+B` muestra/oculta la barra
  (`qs -c dotshell ipc call bar toggle`, afecta a todas las pantallas a la
  vez via el singleton `BarVisibility.qml`) y
  `SUPER+SHIFT+CTRL+B` fuerza un reload duro
  (`qs -c dotshell ipc call shell reload`, recrea las ventanas) --
  equivalentes a las señales `SIGUSR1`/`SIGUSR2` que aceptaba Waybar.
- Para depurar en vivo: `qs -c dotshell log -f` (logs) y
  `qs -c dotshell ipc show` (lista los `IpcHandler` disponibles).

### Centro de configuracion

Una ventana, "Configuracion", con todas las opciones del ecosistema. Se abre
con `SUPER+I`, con el engranaje del centro de control (`SUPER+N`) o con un
enlace directo:

```sh
~/.config/hypr/scripts/settings-ui                        # abrir (o traer la que esta abierta)
~/.config/hypr/scripts/settings-ui open system            # una pagina
~/.config/hypr/scripts/settings-ui open capture.cardSeconds   # una opcion: su pagina, iluminada
```

Es una instancia de Quickshell aparte de la shell
(`dotshell/settings.qml`, como el bloqueo): cerrada no hay ningun proceso, y
reiniciar la shell no la cierra. Una sola ventana a la vez (un segundo
`SUPER+I` la trae al frente). Flota al centro a 1100 x 720 (regla
`settings-center` en `rules.lua`).

- **Inicio**: el tema actual ("Cambiar fondo" abre la galeria, "Opciones de
  tema" lleva a Apariencia), tres opciones rapidas (reducir movimiento,
  transparencia, alto contraste) y **Tus cambios**: cada opcion cambiada,
  con su valor, el de fabrica y volver; clic en una lleva a su fila.
- **Una pagina por categoria** (Apariencia, Accesibilidad, Barra, Dashboard,
  Capturas, Multimedia, Notificaciones, Sistema, Pantallas, Energia, Teclado y
  raton, Bloqueo e inicio, Atajos). Las paginas
  se arman solas desde `dotshell/data/settings.schema.json`: una clave nueva
  aparece en su pagina, con el control de su tipo, y se encuentra al buscar.
  Una categoria sin opciones no aparece. Cada fila dice si esta "Cambiada" y
  cuando se aplica ("La proxima vez", "Reinicia la shell"); las avanzadas
  quedan plegadas al final de la pagina. "Restablecer la pagina" vuelve todo
  a fabrica (pregunta antes).
- **Apariencia** (Fase 10 B2): arriba el tema actual -- con que esquema y
  contraste se aplico; si los de "todos los wallpapers" son otros,
  "Aplicar al tema actual" lo reaplica con ellos (el boton "Tema global" de
  la galeria trae aca) --, la fuente de la interfaz y la de codigo (las
  instaladas que cubren el castellano, cada una escrita en si misma; la
  shell, el bloqueo y el login las usan; si una se desinstala, vuelve la de
  fabrica y Diagnostico lo dice) y el **avatar**: del fondo o una imagen
  propia (selector de archivos del portal, GTK).
- **Accesibilidad**: reducir movimiento (la shell y tambien las animaciones
  de las ventanas), alto contraste, **tamano del
  texto** (Normal, Grande 112 %, Muy grande 125 %: solo el texto, iconos y
  alturas quedan igual; tambien el bloqueo y el login) y **foco siempre
  visible** (un anillo alrededor de lo que tiene el foco del teclado).
- **Ventanas** (en Apariencia, Fase 10 B3): espacios, esquinas, borde,
  opacidad, desenfoque y sombras de Hyprland.
- **Teclado y raton**: distribuciones del teclado (la primera es la principal;
  con mas de una, una combinacion las alterna), repeticion de teclas, Bloq
  Num, el foco que sigue al raton, velocidad y aceleracion del puntero, y el
  touchpad (desplazamiento natural, tocar para hacer clic, desactivar
  mientras se escribe, clic derecho con dos dedos, velocidad).
- **Energia**: bajar el brillo, bloquear, apagar la pantalla y suspender
  tras un tiempo sin uso (cada uno puede ser "Nunca"), suspender tambien
  enchufado o solo con bateria, y no entrar en reposo mientras suena algo.
- **Pantallas** (Fase 10 B5): una tarjeta por pantalla con resolucion,
  frecuencia, escala (solo las que dejan un espacio entero, con el espacio que
  queda), rotacion, volteada, VRR, duplicar y, plegado, color avanzado (8/10
  bits, perfiles sRGB / DCI-P3 / Display P3 / Adobe RGB / amplio / EDID / HDR,
  brillo y saturacion de lo SDR en HDR). Con dos o mas, la **disposicion** se
  arrastra (se pega a los bordes; dos superpuestas no se pueden aplicar) y se
  puede apagar una (nunca la ultima). Lo que la pantalla no dice soportar
  (segun su EDID, `scripts/display-caps`) se muestra con una nota. **Cada
  cambio se prueba**: al aplicar arriba aparece "¿Mantener esta
  configuracion?" con 15 s; sin "Mantener" vuelve la anterior (lo cuenta un
  proceso aparte: vuelve aunque la pantalla quede negra o la ventana se
  cierre). VRR se aplica recargando Hyprland (un parpadeo). "Frecuencia alta
  solo enchufado" baja la integrada a 60 Hz con bateria (con aviso).
  **Luz nocturna**: encendida o no (tambien desde el centro de control),
  horario o del atardecer al amanecer (con la ciudad del clima), temperatura y
  un paso mas calido de madrugada. La config versionada de monitores
  (`modules/monitors.lua`) es generica: lo de tu equipo vive en tu almacen.
- **Barra**: la **disposicion** (Fase 11 B1) en tres columnas (izquierda,
  centro, derecha): se arrastra cada modulo a otro lugar, dentro o fuera de
  una pildora, se agregan espacios, y lo que se suelta en Disponibles se
  quita; al senalar un modulo se marca en la barra (con teclado: flechas para
  moverlo, Supr para quitarlo). Modulos para agregar desde Disponibles (Fase
  11 B2; ninguno viene puesto): distribucion del teclado (con dos o mas; clic
  pasa a la siguiente), Bloq Mayus / Bloq Num (solo mientras estan
  activados), ventana activa, avisos (campana con punto o numero; clic abre el
  centro de control), privacidad (pantalla compartida, microfono o camara en
  uso, en amarillo), el lanzador, recursos (procesador, memoria, temperatura;
  amarillo por encima de un umbral) y velocidad de la red -- estos dos solo
  leen el sistema mientras estan en la barra, cada `system.sampleSeconds`.
  Escritorios: solo los de cada pantalla, sin los vacios, o con el icono de
  cada ventana. Informacion al pasar el raton (la fecha completa, la bateria,
  el titulo entero...) y la rueda sobre la barra para volumen o brillo,
  apagadas de fabrica. **Posicion** (Fase 11 B3): la barra en cualquier
  borde (arriba, abajo, izquierda, derecha) y su grosor (32-48 px); a un
  costado los modulos se apilan (el reloj en dos lineas, solo iconos), y el
  centro de control, el OSD, los avisos y los menus se ubican desde ese
  borde. Estilo flotante (pildoras sueltas), solida (pegada al borde, un
  solo fondo) o transparente, y "mostrar solo mientras se mantiene Super"
  (aparece al mantener la tecla, tras un breve retardo: encima de las
  ventanas, con fondo, o empujandolas mientras se ve; Fase 11 B3b).
  En que pantallas va la barra. Reloj de 24 o
  12 h y la fecha al lado, cambiar de escritorio con la rueda, y la pill de
  musica con el titulo o solo el icono (Fase 10 B4).
- **Dashboard**: las zonas Sistema y Escritorios del inicio, la ciudad del
  clima (la misma busqueda que en la vista Hoy; "Quitar" deja de consultar)
  y °C / °F.
- **Capturas**: copiar al portapapeles, congelar la pantalla al elegir, PNG o
  JPEG; al grabar, audio (sin audio, el sonido del equipo, el microfono o
  ambos: una mezcla temporal de PipeWire que se quita al terminar) y 30 o
  60 fotogramas.
- **Multimedia**: el reproductor preferido (el que la barra y el dashboard
  muestran si esta abierto), ignorar los navegadores y el volumen maximo con
  las teclas (100, 125 o 150 %).
- **Notificaciones**: donde aparecen (arriba a la derecha, arriba al centro,
  abajo a la derecha), cuantas a la vez (las demas esperan), un sonido al
  llegar y avisos del sistema en el OSD: Bloq Mayus, cambio de distribucion
  y cargador conectado o no (apagados de fabrica).
- **Atajos**: la misma lista que la guia (`SUPER+/`), con busqueda; se relee
  de Hyprland cada vez que se abre la pagina.

Lo que va a Hyprland o a hypridle se aplica al momento (sin recargar
Hyprland): `scripts/settings-apply` genera
`~/.local/state/dotfiles/hypr-overrides.lua` (solo lo que cambiaste;
`hyprland.lua` lo carga al final, la config del repo es la de fabrica) y
`~/.local/state/dotfiles/hypridle.conf` (hypridle arranca con esa), y las
reglas de pantalla (en los mismos overrides) y
`~/.local/state/dotfiles/hyprsunset/hypr/hyprsunset.conf` (luz nocturna; hyprsunset arranca con `XDG_CONFIG_HOME` apuntando ahi: no acepta una ruta). Si
Hyprland usa otro valor (por ejemplo en modo juego), la fila lo dice. El modo
juego (`SUPER+ALT+G`) apaga desenfoque, sombras y animaciones y al salir
vuelven tus valores.
- **Acerca de**: versiones, Diagnostico (valores que el motor no aplico y
  por que, fuentes que ya no estan), tus cambios como archivo y el README.
- **Buscar** (`Ctrl+F`): etiqueta, descripcion, palabras clave, sin tildes;
  Enter lleva a la opcion y la ilumina. `Ctrl+Tab` / `Ctrl+AvPag` cambian
  de pagina, Tab recorre los controles (la pagina se desplaza hasta el que
  tiene el foco), las flechas, `RePag` / `AvPag` e `Inicio` / `Fin` desplazan
  la pagina, la barra de la derecha se arrastra o se cliquea, y Esc borra la
  busqueda y despues cierra. Si la ventana es baja, la lista de paginas de la
  izquierda tambien se desplaza (rueda o su barra) y la pagina elegida queda a
  la vista.

Los valores se guardan solo a traves de `~/.config/hypr/scripts/settings`
(el unico que escribe `~/.config/dotfiles/settings.json`, y solo lo que
cambiaste); un valor que no vale no se guarda y la fila dice por que. Si un
cambio pide reiniciar la shell, arriba aparece un aviso con el boton.

Para depurar: `qs ipc -p ~/.config/quickshell/dotshell/settings.qml call
settingsui status` (pagina y opcion iluminada); los logs, con
`qs log -p ~/.config/quickshell/dotshell/settings.qml`.

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
- Plus Jakarta Sans en toda la UI y Maple Mono NF en lo monoespaciado
  (`--encore-*-font-stack`, mismas fuentes que el resto del rice,
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

El greeter (`dotfiles-login`) es la misma pantalla de entrada que el bloqueo
(ver "Bloqueo de pantalla"): hora apilada, chip de la fecha y la tarjeta de
la contrasena, con el avatar `~/.face`. Las tarjetas son acciones: Apagar,
Reiniciar, Suspender (si el equipo puede) y Sesion (un clic pasa a la
siguiente, por ejemplo Hyprland / Hyprland (uwsm)). Entra sobre el fondo
difuminado que deja Plymouth y, al iniciar sesion, sale hasta el wallpaper
nitido con el que arranca el escritorio.

Comparte el codigo con el bloqueo: `dotshell/login/` (QtQuick puro),
`Tokens.qml`, `SemanticPalette.qml` y `modules/Icon.qml`; lo propio del
greeter esta en `sddm/theme/` (`Main.qml`, `SddmAuth.qml`). La paleta la
genera matugen (`templates/sddm/Colors.qml`) en la pasada del sistema, 60 s
despues del ultimo cambio de wallpaper. `scripts/sddm-theme-stage` arma el
tema completo como vos en `~/.cache/matugen/sddm-login/` (con el wallpaper y
el avatar) y la copia root de `sync-sddm-theme` solo lo instala en
`/usr/share/sddm/themes/dotfiles-login` (sin argumentos, rechaza enlaces
simbolicos): SDDM corre como el usuario `sddm` y no puede leer tu home.

Setup (una vez, con sudo):

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

# Arma e instala el tema por primera vez y lo activa
~/.config/hypr/scripts/sddm-theme-stage
sudo /usr/local/bin/sync-sddm-theme
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=dotfiles-login\n' | sudo tee /etc/sddm.conf.d/theme.conf
```

Si editas `sync-sddm-theme.sh`, hay que repetir el primer `install` para
que el cambio aplique (la copia en `/usr/local/bin` es la que realmente
corre, no la del repo). Para probar el tema sin cerrar sesion:
`sddm-greeter-qt6 --test-mode --theme ~/.cache/matugen/sddm-login` (los
errores de QML van al journal: `journalctl --user -e`).

Si el greeter no cargara: `Ctrl+Alt+F3`, entrar, y
`sudo sed -i 's/^Current=.*/Current=maldives/' /etc/sddm.conf.d/theme.conf`
y `sudo systemctl restart sddm` (maldives viene con SDDM).

### Bloqueo de pantalla

El bloqueo es una instancia de Quickshell aparte de la shell
(`dotshell/lock.qml`), con la composicion "Material You": a la izquierda la
hora apilada (horas en el color de acento, minutos en el del texto) y el
chip de la fecha; a la derecha las tarjetas "de un vistazo" y la tarjeta de
la contrasena (avatar `~/.face`, usuario, campo y la linea de Bloq Mayus o
del error), sobre el wallpaper difuminado. El campo esta en todas las
pantallas (un solo texto compartido) y tiene un lugar fijo: las tarjetas
crecen hacia arriba. Es la misma pantalla que el greeter (codigo
compartido en `dotshell/login/`): entra desde el escritorio (el fondo se
difumina; reloj, tarjetas y tarjeta de la contrasena, en ese orden) y al
desbloquear el candado se abre y sale todo hasta el wallpaper nitido. Nada
se mueve si nada cambia; con "Reducir movimiento", todo es inmediato. Siempre lo lanza `~/.config/hypr/scripts/lock`, que lo
vigila:

- `SUPER+L`, el menu de energia y el control center llaman `lock --user`;
  hypridle (inactividad y antes de suspender) llama `lock`.
- Si el bloqueo se cae con la sesion bloqueada, se relanza solo; a la
  tercera caida, o si no llega a bloquear en 3 s, abre el **hyprlock de
  emergencia** (`hyprlock-emergency.conf`: sin tema ni archivos generados).
- Al volver de una suspension, hypridle llama `lock --resume`: el bloqueo
  se recrea (Hyprland no le devuelve el teclado a la superficie anterior).
- `SUPER+CTRL+ALT+L` (funciona con la sesion bloqueada): si el bloqueo no
  acepta la contrasena, lo cambia por el hyprlock de emergencia. Nunca
  desbloquea.
- La contrasena la verifica PAM con `dotshell/lock/pam/dotfiles-lock`
  (`pam_unix` + `pam_faillock`: 3 intentos fallidos, 10 min de espera).
- Registro: `journalctl -t dotfiles-lock`.

#### De un vistazo

Cada tarjeta aparece solo si tiene algo que decir y ninguna hace nada (el
cursor esta oculto; las teclas de volumen, brillo y multimedia siguen
funcionando). Se apagan una por una en el centro de configuracion
(`SUPER+I`), pagina "Bloqueo e inicio" (`lock.glance.*`):

- **Clima**: temperatura y estado del cielo, sin la ubicacion; si los datos
  tienen mas de 2 horas, no aparece. El bloqueo nunca consulta la red.
- **Musica**: mientras algo suena, el titulo y debajo el artista (o el
  reproductor); nunca la portada. Se ve con la sesion bloqueada: si no
  queres que se vea, apagalo en "Bloqueo e inicio".
- **Bateria**: solo funcionando con bateria, con el color de aviso en los
  umbrales de bateria baja y critica.
- **Avisos**: cuantos llegaron mientras estaba bloqueado, nunca el
  contenido; con No molestar activo, no aparece.

"Bloq Mayus activado" aparece bajo el campo mientras este activo (siempre:
evita intentos fallidos, que cuentan tambien para `sudo`).

#### Recuperacion manual (desde una TTY)

Si `SUPER+CTRL+ALT+L` no alcanza o la pantalla dice "lockscreen died":

1. `Ctrl+Alt+F3` y entrar con tu usuario (pide la contrasena).
2. **Solo si el bloqueo sigue vivo** (congelado, no "lockscreen died"):
   `pkill -f "qs -p .*lock.qml"`. Con "lockscreen died" ya no existe: no
   imprime nada y se puede saltear.
3. `hyprctl --instance 0 eval 'hl.clear_crashed_lockscreen()'`
   - `ok`: la sesion quedo desbloqueada.
   - `error: ... session is not locked`: ya estaba desbloqueada (por
     ejemplo, el paso 3 ya se habia hecho).
   - Cualquier otra cosa: pasos 6 y 7.
4. `Ctrl+Alt+F1`: la sesion, desbloqueada.
5. Cerrar la TTY: `Ctrl+Alt+F3`, `exit`, `Ctrl+Alt+F1` (si no, queda una
   sesion abierta en tty3).

Solo si el paso 3 no funciona:

6. `hyprctl --instance 0 eval 'hl.config({ misc = { allow_session_lock_restore = true } })'`
7. `hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock --config ~/.config/hypr/hyprlock-emergency.conf")'`,
   `Ctrl+Alt+F1` y la contrasena; despues el paso 5.
8. Ultimo recurso (cierra la sesion): `loginctl terminate-session <n>`
   (`loginctl list-sessions` da el numero).

Lo mismo funciona por SSH (sin los cambios de TTY; `exit` cierra la
sesion SSH).

### Plymouth (splash de arranque)

Theme "Script" propio (`plymouth/theme/dotfiles-matugen.plymouth`, la
unica parte estatica -- no lleva colores). Todo lo visual lo genera
`matugen/.config/matugen/templates/plymouth.script` +
`hypr/.config/hypr/scripts/generate-plymouth-assets.sh` (ImageMagick, sin
sudo, corre como `post_hook` en cada cambio de wallpaper):

- **Fondo**: el wallpaper activo con blur fuerte + oscurecido + vignette
  radial (mismo criterio que el fondo de la pantalla de bloqueo, pero horneado en
  la imagen porque Plymouth Script no tiene filtro de blur propio).
- **Avatar**: `~/.face` (el mismo recorte cuadrado que usa la pantalla de bloqueo, ver
  `theme-apply.sh`) recortado en circulo, centrado en el hueco
  transparente que deja el anillo del spinner.
- **Spinner**: un anillo de 270 grados (24 frames rotando) tenido con
  `primary`, alrededor del avatar.
- **Label + progreso**: "Arch Linux" fijo abajo al centro y el porcentaje
  de boot en la esquina inferior izquierda, ambos con `on_surface`/`primary`.
- Fade-in de todo el conjunto en los primeros frames (sin fade-out
  simetrico al salir -- el plugin "script" no da una forma confiable de
  retrasar el quit para animarlo, y el boot de este equipo ya es
  demasiado rapido como para que valga el riesgo).

Mismo motivo y patron que SDDM: Plymouth corre dentro del **initramfs**
(antes de montar el disco de verdad), no puede leer `~/.config` en vivo,
asi que necesita: 1) un paso de setup con sudo (una vez), y 2) que cada
cambio de wallpaper reconstruya el initramfs (`mkinitcpio -P`, lo hace
`plymouth-set-default-theme -R`) en vez de solo copiar un CSS. El
`post_hook` del template `plymouth` en `config.toml` ya dispara todo eso
solo, en background, via el mismo mecanismo `sudo -n` a un script puntual
que SDDM (no sudo sin restricciones -- ver el comentario ahi mismo):

```bash
# Copia root-owned del script (mismo motivo que sync-sddm-theme: el
# sudoers NO apunta al de este repo, que vos podes editar)
sudo install -m 755 -o root -g root \
  hypr/.config/hypr/scripts/sync-plymouth-theme.sh /usr/local/bin/sync-plymouth-theme

# Regla de sudoers, acotada a ESE script puntual -- validar con visudo antes
# de instalar cualquier cambio de sudoers, un error ahi rompe sudo entero:
echo 'h3n ALL=(root) NOPASSWD: /usr/local/bin/sync-plymouth-theme' > /tmp/matugen-plymouth-sudoers
visudo -c -f /tmp/matugen-plymouth-sudoers && \
  sudo install -m 440 -o root -g root /tmp/matugen-plymouth-sudoers /etc/sudoers.d/matugen-plymouth
rm /tmp/matugen-plymouth-sudoers

# Genera el theme por primera vez, lo copia a /usr/share y lo fija como
# default (plymouth-set-default-theme -R reconstruye el initramfs solo,
# pero todavia no hace nada visible sin el paso de mkinitcpio de abajo)
sudo /usr/local/bin/sync-plymouth-theme

# Hook de mkinitcpio: "plymouth" va justo despues de "udev", antes de
# "autodetect" (formato busybox/HOOKS clasico, no systemd) -- editar
# /etc/mkinitcpio.conf a mano:
#   HOOKS=(base udev plymouth autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)

# IMPORTANTE: este equipo arranca con una UKI (Unified Kernel Image,
# /boot/EFI/Linux/arch-linux-zen.efi, ver preset en
# /etc/mkinitcpio.d/linux-zen.preset) generada directo por mkinitcpio, NO
# con el esquema separado vmlinuz+initramfs+GRUB_CMDLINE_LINUX_DEFAULT.
# `bootctl status` confirma que el cmdline realmente usado en cada arranque
# sale de /etc/kernel/cmdline (NO de /etc/default/grub -- grub.cfg en este
# equipo ni siquiera tiene una entrada real para arrancar linux-zen). Para
# "splash" el archivo correcto a editar es ese:
#   sudoedit /etc/kernel/cmdline
#   # agregar " quiet splash" al final de la linea existente

sudo mkinitcpio -P
```

Si tu equipo SI arranca por el esquema clasico GRUB (revisa con `bootctl
status`: si el cmdline mostrado en "Default Boot Loader Entry" no coincide
con `/etc/kernel/cmdline`, es tu caso), el paso de cmdline es en
`/etc/default/grub` (`GRUB_CMDLINE_LINUX_DEFAULT`) seguido de `sudo
grub-mkconfig -o /boot/grub/grub.cfg`, y la red de seguridad es la
clasica: en el menu de GRUB presionar `e` sobre la entrada y editar el
cmdline en caliente.

Si editas `sync-plymouth-theme.sh` o `generate-plymouth-assets.sh`, hay
que repetir el primer `install` (mismo motivo que SDDM).

#### Arranque real de este equipo: fallback UEFI en vez de GRUB

En esta maquina puntual, las entradas NVRAM de GRUB y Limine quedaron
apuntando a archivos `.efi` que ya no existen (`efibootmgr -v` las lista,
pero `/boot/EFI/GRUB/` y `/boot/EFI/limine/` no estan) -- el firmware
prueba cada una en `BootOrder`, todas fallan, y termina cayendo al path de
fallback generico que exige la spec UEFI cuando una entrada no tiene
archivo explicito: `/boot/EFI/BOOT/BOOTX64.EFI`. Eso resulto ser un
binario standalone de GRUB con su config **embebida y congelada** desde
que se genero -- nunca ve los cambios que hacemos en `/etc/kernel/cmdline`
o `mkinitcpio.conf`. Se confirma con:

```bash
efibootmgr -v   # BootCurrent: <n> -- si esa entrada no tiene un \path\archivo.efi
                # explicito, tu firmware tambien esta cayendo al fallback
```

La solucion que se aplico ahi fue sacar a GRUB de la ecuacion: una UKI es
un ejecutable EFI valido por si sola, asi que `BOOTX64.EFI` es
directamente una copia de `arch-linux-zen.efi`. `sync-plymouth-theme.sh`
mantiene esa copia al dia solo (via un `cp` a un temporal + `mv` atomico,
asi que si algo falla a mitad de camino -- por ejemplo la ESP sin espacio
-- `BOOTX64.EFI` queda intacto en vez de corrupto), **si el archivo ya
existe** (guard pensado para no tocar equipos que arrancan por una entrada
NVRAM normal, donde este path no se usa).

**Ojo con el tamano de la ESP**: en este equipo es de apenas 1GB, y cada
UKI pesa ~280MB. Con `arch-linux-zen.efi` + `BOOTX64.EFI` ya se usan
~560MB -- evita guardar backups manuales de la UKI completa ahi (nos paso:
`cp` se quedo sin espacio a mitad de copia y truncamos `BOOTX64.EFI`, hubo
que recuperarlo). Como red de emergencia liviana alcanza con guardar el
GRUB standalone original (160KB, bootea a Arch sin Plymouth pero bootea):

```bash
sudo cp /boot/EFI/BOOT/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI.grub-backup
```

Si algo sale mal despues de eso, la mayoria de los firmwares UEFI dejan
arrancar un `.efi` especifico desde su propio menu de boot (F9/F11/Esc al
encender, "Boot from file"), sin necesitar un USB live.

### GRUB (menu de arranque)

Theme propio (fondo con blur+vignette del wallpaper, avatar `~/.face` en
circulo, anillo de progreso atado al countdown real de `GRUB_TIMEOUT`,
highlight de seleccion tipo "pill" redondeada, tipografia Plus Jakarta
Sans -- la fuente de interfaz del rice) generado por matugen, mismo
patron que SDDM/Plymouth: `matugen/.config/matugen/templates/grub-theme.txt`
(template) + `hypr/.config/hypr/scripts/generate-grub-assets.sh`
(ImageMagick, sin sudo) + `hypr/.config/hypr/scripts/sync-grub-theme.sh`
(root, copia a `/boot/grub/themes/` y corre `grub-mkconfig`). Las fuentes
(`grub/theme/font.pf2` y `font-bold.pf2`) son estaticas -- generadas UNA
VEZ con `grub-mkfont` a partir de Plus Jakarta Sans, con nombre
propio (`--name`) para no depender de que fuente trae GRUB instalada de
fabrica:

```bash
grub-mkfont -o grub/theme/font.pf2 -s 16 --name "DotfilesSans" \
  /usr/share/fonts/TTF/PlusJakartaSans-Regular.ttf
grub-mkfont -o grub/theme/font-bold.pf2 -s 28 --name "DotfilesSansSemiBold" \
  /usr/share/fonts/TTF/PlusJakartaSans-SemiBold.ttf
```

(`grub-mkconfig` detecta y carga solo los `.pf2` que encuentra en la
carpeta del theme -- no hace falta un `loadfont` a mano.)

**Arranque real de este equipo (importante, groundeado con la Wiki):**
GRUB estaba instalado (`/boot/grub/x86_64-efi/` completo) pero sin
entrada NVRAM viva ni `grub.cfg` real -- alguien la borro en una migracion
de bootloader anterior (ver seccion "Arranque real de este equipo" de
Plymouth arriba, mismo hallazgo). Restaurado con:

```bash
sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
```

La entrada de arranque real es un `chainloader` directo a la UKI (NO los
comandos `linux`/`initrd`, que reconstruirian el cmdline con
`GRUB_CMDLINE_LINUX_DEFAULT` y perderian el `quiet splash` embebido) --
mismo patron que la Wiki documenta para chainloadear `bootmgfw.efi` de
Windows. En `/etc/grub.d/40_custom`:

```
menuentry "Arch Linux" --class arch --class gnu-linux --class gnu --class os {
    insmod part_gpt
    insmod fat
    insmod chain
    search --no-floppy --fs-uuid --set=root <UUID-de-tu-ESP-en-fstab>
    chainloader /EFI/Linux/<tu-uki>.efi
}
```

`GRUB_DEFAULT="Arch Linux"` en `/etc/default/grub` (por nombre, no por
indice `0` -- la entrada "UEFI Firmware Settings" que agrega
`grub-mkconfig` puede quedar antes en el archivo). `os-prober` no esta
instalado a proposito (sin dual-boot en este equipo).

Setup del theme (mismo patron sudoers que SDDM/Plymouth):

```bash
sudo install -m 755 -o root -g root \
  hypr/.config/hypr/scripts/sync-grub-theme.sh /usr/local/bin/sync-grub-theme

echo 'h3n ALL=(root) NOPASSWD: /usr/local/bin/sync-grub-theme' > /tmp/matugen-grub-sudoers
visudo -c -f /tmp/matugen-grub-sudoers && \
  sudo install -m 440 -o root -g root /tmp/matugen-grub-sudoers /etc/sudoers.d/matugen-grub
rm /tmp/matugen-grub-sudoers

sudo /usr/local/bin/sync-grub-theme
```

**Probar sin comprometer el arranque normal**: `efibootmgr --bootnext <numero-de-entrada>`
arranca por esa entrada UNA sola vez (no toca `BootOrder`), ideal para
probar un `grub-install`/theme nuevo antes de hacerlo permanente:

```bash
efibootmgr -v                       # anota el numero de tu entrada GRUB
sudo efibootmgr --bootnext <numero>
# reiniciar, confirmar que anda bien, RECIEN AHI:
sudo efibootmgr --bootorder <numero>,<resto-del-orden-que-ya-tenias>
```

Si editas `sync-grub-theme.sh` o `generate-grub-assets.sh`, hay que
repetir el primer `install` (mismo motivo que SDDM/Plymouth).

## 4. Relogueate

Cerra sesion y volve a entrar (SDDM) para que las variables de entorno
(cursor, Qt, GPU) se apliquen desde cero. `hyprctl reload` alcanza para
cambios de binds/reglas/apariencia, pero no para `hl.env(...)`.

`qt5ct.conf`/`qt6ct.conf` ya vienen configurados (paleta custom apuntando al
esquema de matugen, iconos Papirus-Dark, estilo Fusion) -- no hace falta
correr `qt5ct`/`qt6ct` a mano salvo que quieras retocar algo mas (fuente,
efectos, etc.), en cuyo caso la GUI lee y guarda sobre el mismo archivo.

## Atajos

En el sistema: **`SUPER + /`** abre la guia de atajos (buscable, siempre al
dia). La tabla de abajo se genera desde la misma fuente -- la descripcion de
cada atajo en `hypr/.config/hypr/modules/binds.lua`, leida de Hyprland -- con
`hypr/.config/hypr/scripts/keybinds readme`, que reescribe solo la tabla
entre los marcadores; no se edita a mano. `keybinds readme --check` avisa si
quedo desactualizada y `keybinds check` falla si algun atajo no tiene
descripcion.

<!-- keybinds:start (generado: hypr/.config/hypr/scripts/keybinds readme) -->
**Shell**

| Atajo | Acción |
|---|---|
| `Super` + `D` | Lanzador de aplicaciones |
| `Super` + `Tab` o `Super` + `Shift` + `Tab` | Cambiar de ventana |
| `Super` + `A` | Dashboard |
| `Super` + `N` | Centro de control |
| `Super` + `Shift` + `N` | Limpiar notificaciones |
| `Super` + `Shift` + `B` | Mostrar u ocultar la barra |
| `Super` + `Ctrl` + `Shift` + `B` | Recargar la shell |
| `Super` + `Shift` + `V` | Portapapeles |
| `Super` + `.` | Emoji |
| `Super` + `/` | Guía de atajos |
| `SUPER_L` | Mostrar barra (mantener) |

**Programas**

| Atajo | Acción |
|---|---|
| `Super` + `Intro` | Terminal |
| `Super` + `E` | Archivos |
| `Super` + `B` | Navegador |
| `Super` + `Shift` + `C` | Selector de color |

**Sistema**

| Atajo | Acción |
|---|---|
| `Super` + `I` | Configuración |
| `Super` + `L` | Bloquear la pantalla |
| `Super` + `Ctrl` + `Alt` + `L` | Bloqueo de emergencia |
| `Super` + `M` | Energía y sesión |
| `Super` + `Shift` + `M` | Cerrar sesión |
| `Super` + `Ctrl` + `Shift` + `M` | Salida de emergencia |
| `Super` + `Alt` + `G` | Modo juego |
| `Caps_Lock` | Estado de Bloq Mayús |
| `Num_Lock` | Estado de Bloq Num |

**Ventanas**

| Atajo | Acción |
|---|---|
| `Super` + `Q` | Cerrar la ventana |
| `Super` + `Shift` + `Q` | Forzar el cierre |
| `Super` + `V` | Flotante |
| `Super` + `F` | Pantalla completa |
| `Super` + `Shift` + `P` | Fijar en todas partes |
| `Super` + `C` | Centrar |
| `Super` + `P` | Pseudomosaico |
| `Super` + `J` | Alternar la división |
| `Super` + `G` | Agrupar |
| `Super` + `Shift` + `G` | Bloquear el grupo |
| `Super` + `Flechas` | Mover el foco |
| `Super` + `Shift` + `Flechas` | Mover la ventana |
| `Super` + `Ctrl` + `Flechas` | Cambiar el tamaño |
| `Super` + `Clic izq.` / `Ctrl izq.` | Mover con el ratón |
| `Super` + `Clic der.` / `Alt izq.` | Redimensionar con el ratón |
| `Super` + `R` | Modo cambiar tamaño |

**Escritorios**

| Atajo | Acción |
|---|---|
| `Super` + `1 … 0` | Ir al escritorio |
| `Super` + `Shift` + `1 … 0` | Mover al escritorio |
| `Super` + `Rueda` | Recorrer escritorios |
| `Super` + `S` | Escritorio especial |
| `Super` + `Shift` + `S` | Mover al especial |
| `Super` + `Alt` + `L` | Cambiar la distribución |

**Capturas**

| Atajo | Acción |
|---|---|
| `Impr` | Capturar el monitor |
| `Super` + `Impr` | Capturar una región |
| `Super` + `Shift` + `Impr` | Capturar la ventana |
| `Super` + `Alt` + `R` | Grabar una zona |
| `Super` + `Alt` + `Shift` + `R` | Grabar el monitor |

**Tema**

| Atajo | Acción |
|---|---|
| `Super` + `Shift` + `W` | Galería de fondos |
| `Super` + `Shift` + `Z` | Deshacer el último tema |

**Multimedia**

| Atajo | Acción |
|---|---|
| `Subir volumen` / `Bajar volumen` | Volumen |
| `Silencio` | Silenciar |
| `Micrófono` | Silenciar el micrófono |
| `Subir brillo` / `Bajar brillo` | Brillo |
| `Anterior` / `Siguiente` | Pista siguiente o anterior |
| `Reproducir/Pausa` | Reproducir o pausar |

**Modo cambiar tamaño** (modo: `Super` + `R`, sale con `Esc`/`Intro`)

| Atajo | Acción |
|---|---|
| `Flechas` | Cambiar el tamaño |
| `Esc` / `Intro` | Salir del modo |
<!-- keybinds:end -->
