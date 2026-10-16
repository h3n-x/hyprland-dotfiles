-- ============================================================================
-- Hyprland -- config principal (API Lua "hl.*", Hyprland 0.56.2+)
-- HP Victus 15 fb2xxx -- AMD Ryzen 5 8645HS (iGPU Radeon 760M) + NVIDIA RTX 3050 6GB
-- Gestionado con GNU Stow desde ~/Dotfiles/hypr -> ~/.config/hypr
--
-- Cada require() carga su modulo en un "scope" de error separado: si uno
-- falla, el resto se sigue cargando igual. Ver https://wiki.hypr.land/configuring/core/
-- ============================================================================

require("modules.env")          -- variables de entorno (GPU detectada, cursor, Qt/GTK, Electron)
require("modules.monitors")     -- monitores
require("modules.lookandfeel")  -- general, decoration, blur, sombras, animaciones
require("modules.layouts")      -- dwindle / master / scrolling
require("modules.input")        -- teclado, touchpad, gestos, dispositivos
require("modules.binds")        -- keybinds y submaps
require("modules.rules")        -- window / layer / workspace rules
require("modules.autostart")    -- apps que arrancan junto con Hyprland

-- Opciones cambiadas en el centro de configuracion (Fase 10 B3): las genera
-- scripts/settings-apply desde ~/.config/dotfiles/settings.json, solo las que
-- difieren de esta config (que es la de fabrica). Al final, para que ganen; si
-- falta o falla, queda la de fabrica.
pcall(dofile, os.getenv("HOME") .. "/.local/state/dotfiles/hypr-overrides.lua")
