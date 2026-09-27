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
| Lockscreen | Hyprlock |
| Login manager | SDDM (tema propio, ver `sddm/`) |
| Splash de arranque | Plymouth (colores dinamicos, ver seccion Plymouth abajo) |
| Menu de arranque | GRUB (theme propio con matugen, ver seccion GRUB abajo) |
| Idle | Hypridle |
| Wallpaper | hyprpaper |
| Filtro de luz azul | hyprsunset |
| Polkit | hyprpolkitagent |
| Capturas | grim + slurp (pantalla congelada con hyprpicker) + satty, vista previa de Quickshell |
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
  qt5ct qt6ct nwg-look papirus-icon-theme ttf-jetbrains-mono-nerd noto-fonts-emoji python-pillow wtype \
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
control center), kitty (incluida la tab bar), hyprlock, GTK, Qt
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

Ademas regenera `~/.face` -- la imagen "de usuario" que dibuja hyprlock
arriba del reloj de palabras (`image { path = ~/.face }` en
`hyprlock.conf`) -- como un recorte cuadrado centrado (512x512, via
`magick`) del mismo wallpaper. No hace falta poner una foto real: el avatar
del lockscreen cambia solo junto con el resto del theming. Si preferis una
foto tuya en vez del recorte del wallpaper, sobreescribi `~/.face` a mano
despues de cambiar de fondo (el proximo cambio la va a volver a pisar).

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
  `Variants` sobre `Quickshell.screens`), `modules/Pill.qml` (contenedor
  redondeado reutilizable) y un archivo por modulo (`Workspaces`, `Mpris`,
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
  rápidos (wifi/bluetooth/hyprsunset -- este último sin servicio nativo,
  se chequea con `pgrep` al abrir el panel/lock), perfil de energia y DND;
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
    transicion al cambiar de cancion); el estado general del equipo ("Todo
    en orden" y cuatro medidores) y los escritorios en miniatura. Sin musica,
    el reloj crece y el panel se acorta.
  - **Hoy**: calendario del mes y el clima con una frase ("Sensacion 30°. Hoy
    entre 18° y 33°, sin lluvia a la vista."), las proximas 12 h y 5 dias. El
    clima viene de [Open-Meteo](https://open-meteo.com) (sin clave; datos
    CC BY 4.0) via `hypr/.config/hypr/scripts/weather-fetch` (cache en
    `~/.cache/dotfiles/weather.json`). **Sin ubicacion no se consulta nada**;
    la ciudad se elige aca (`C`), se guarda solo en
    `~/.local/state/dotfiles/weather.json` (fuera del repo) redondeada a
    ~10 km y se consulta cada 30 min.
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
  congelada y las ventanas como destino. Mientras se graba, una pill en la
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

### Plymouth (splash de arranque)

Theme "Script" propio (`plymouth/theme/dotfiles-matugen.plymouth`, la
unica parte estatica -- no lleva colores). Todo lo visual lo genera
`matugen/.config/matugen/templates/plymouth.script` +
`hypr/.config/hypr/scripts/generate-plymouth-assets.sh` (ImageMagick, sin
sudo, corre como `post_hook` en cada cambio de wallpaper):

- **Fondo**: el wallpaper activo con blur fuerte + oscurecido + vignette
  radial (mismo criterio que el blur de `hyprlock.conf`, pero horneado en
  la imagen porque Plymouth Script no tiene filtro de blur propio).
- **Avatar**: `~/.face` (el mismo recorte cuadrado que usa hyprlock, ver
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
`hypr/.config/hypr/scripts/keybinds markdown`; no se edita a mano.
`keybinds check` falla si algun atajo no tiene descripcion.

<!-- keybinds:start (generado: hypr/.config/hypr/scripts/keybinds markdown) -->
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
| `Super` + `L` | Bloquear la pantalla |
| `Super` + `M` | Energía y sesión |
| `Super` + `Shift` + `M` | Cerrar sesión |
| `Super` + `Ctrl` + `Shift` + `M` | Salida de emergencia |
| `Super` + `Alt` + `G` | Modo juego |

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
