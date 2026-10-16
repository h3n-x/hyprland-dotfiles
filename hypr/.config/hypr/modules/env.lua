-- ============================================================================
-- Variables de entorno
-- https://wiki.hypr.land/configuring/core/environment-variables/
-- https://wiki.hypr.land/nvidia/
-- ============================================================================

-- ---- GPU: detectada, no versionada (Fase 19 B1) ----
-- scripts/gpu-setup --write deja las variables de la GPU de ESTE equipo (hibrido AMD/Intel +
-- NVIDIA: AQ_DRM_DEVICES con los alias de udev y las de NVIDIA; solo NVIDIA; o ninguna) en
-- ~/.local/state/dotfiles/hypr-gpu.lua. Se carga primero porque AQ_DRM_DEVICES tiene que estar
-- antes de que Aquamarine elija la GPU. Sin el archivo (instalacion nueva) Hyprland elige solo.
pcall(dofile, (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/dotfiles/hypr-gpu.lua")

-- Fix de flickering en apps Electron/CEF (Discord/Vesktop, VSCodium, Obsidian); inocuo sin NVIDIA
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
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
