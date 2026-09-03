# Dotfiles -- Hyprland (HP Victus 15 fb2xxx)

Config completa de Hyprland 0.56+ (API Lua `hl.*`) + stack de escritorio,
gestionada con [GNU Stow](https://www.gnu.org/software/stow/).
Pensada para: AMD Ryzen 5 8645HS (iGPU Radeon 760M) + NVIDIA RTX 3050 6GB
(iGPU siempre activa, NVIDIA solo on-demand).

## Stack

| Categoria | Herramienta |
|---|---|
| Compositor | Hyprland (config Lua modular) |
| Barra | Waybar |
| Launcher | Rofi (+ hyprlauncher como alternativa, `SUPER+SHIFT+D`) |
| Notificaciones | SwayNC |
| Lockscreen | Hyprlock |
| Idle | Hypridle |
| Wallpaper | hyprpaper |
| Filtro de luz azul | hyprsunset |
| Polkit | hyprpolkitagent |
| Capturas | grim + slurp + satty |
| Grabacion | wf-recorder |
| Portapapeles | cliphist + wl-clip-persist |
| Color picker | hyprpicker |
| Terminal | kitty |
| Explorador de archivos | Thunar |

## 1. Instalar paquetes

```bash
sudo pacman -S --needed waybar rofi swaync satty cliphist wl-clip-persist \
  hyprpolkitagent hyprshutdown hyprsunset hyprpicker hyprpaper hyprlock hypridle \
  qt5ct qt6ct nwg-look papirus-icon-theme ttf-jetbrains-mono-nerd \
  gvfs tumbler thunar network-manager-applet blueman pavucontrol playerctl \
  jq btop wireplumber pipewire-pulse pipewire-alsa stow gnome-themes-extra wf-recorder

yay -S --needed bibata-cursor-theme-bin
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
stow hypr waybar rofi swaync kitty gtk-3.0 gtk-4.0
```

## 4. Relogueate

Cerra sesion y volve a entrar (SDDM) para que las variables de entorno
(cursor, Qt, GPU) se apliquen desde cero. `hyprctl reload` alcanza para
cambios de binds/reglas/apariencia, pero no para `hl.env(...)`.

Despues, corre `qt6ct` y `qt5ct` una vez para fijar tema/iconos Qt a mano
(las apps Qt van a quedar coherentes con el resto).

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
| `SUPER + M` | Menu de apagado (hyprshutdown) |
| `SUPER + N` / `SHIFT+N` | Panel de notificaciones / limpiar todo |
| `SUPER + SHIFT + C` | Color picker |
| `SUPER + SHIFT + V` | Historial de portapapeles |
| `Print` / `SUPER+Print` / `SUPER+SHIFT+Print` | Captura completa / region / ventana |
| `SUPER + ALT + R` | Grabar pantalla (toggle) |

Ver `hypr/.config/hypr/modules/binds.lua` para la lista completa.
