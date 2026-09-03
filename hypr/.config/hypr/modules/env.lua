-- ============================================================================
-- Variables de entorno
-- https://wiki.hypr.land/configuring/core/environment-variables/
-- https://wiki.hypr.land/nvidia/
-- ============================================================================

-- ---- GPU hibrida: iGPU AMD 760M siempre, NVIDIA RTX 3050 solo on-demand ----
-- Le decimos a Aquamarine (backend grafico de Hyprland) que use la iGPU AMD
-- como dispositivo DRM primario. AQ_DRM_DEVICES separa la lista con ':', asi
-- que NO se pueden usar directamente las rutas /dev/dri/by-path/pci-0000:XX:00.0-card
-- (el ':' dentro del propio nombre rompe el parseo -> "Found no gpus to use,
-- cannot continue" -> CBackend::create() failed). En vez de eso usamos los
-- alias /dev/dri/gpu-amd y /dev/dri/gpu-nvidia creados por la regla udev
-- /etc/udev/rules.d/71-gpu-drm-aliases.rules, que apuntan por direccion PCI
-- a pci-0000:06:00.0 (AMD 760M) y pci-0000:01:00.0 (NVIDIA RTX 3050) sin ':'
-- en el nombre. El primero de la lista es el que usa Hyprland para renderizar.
hl.env("AQ_DRM_DEVICES", "/dev/dri/gpu-amd:/dev/dri/gpu-nvidia")

-- Evita problemas de compositing en buffers multi-GPU en combinaciones AMD+NVIDIA
hl.env("AQ_FORCE_LINEAR_BLIT", "0")

-- Variables NVIDIA recomendadas por la wiki (para cuando SI se usa la NVIDIA,
-- ya sea por hyprctl systeminfo, apps con nvidia-offload, o si en el futuro
-- se decide invertir el orden de AQ_DRM_DEVICES)
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- Fix de flickering en apps Electron/CEF (Discord/Vesktop, VSCodium, Obsidian) en setups NVIDIA
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- ---- Cursor ----
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")

-- ---- Toolkits GUI: forzar Wayland nativo con fallback a X11/XWayland ----
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- ---- Varios ----
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
