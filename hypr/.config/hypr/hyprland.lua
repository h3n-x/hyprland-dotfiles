-- ============================================================================
-- Hyprland -- config principal (API Lua "hl.*", Hyprland 0.56.2+)
-- HP Victus 15 fb2xxx -- AMD Ryzen 5 8645HS (iGPU Radeon 760M) + NVIDIA RTX 3050 6GB
-- Gestionado con GNU Stow desde /home/h3n/Dotfiles/hypr -> ~/.config/hypr
--
-- Cada require() carga su modulo en un "scope" de error separado: si uno
-- falla, el resto se sigue cargando igual. Ver https://wiki.hypr.land/configuring/core/
-- ============================================================================

require("modules.env")          -- variables de entorno (GPU hibrida, cursor, Qt/GTK, Electron)
require("modules.monitors")     -- monitores
require("modules.lookandfeel")  -- general, decoration, blur, sombras, animaciones
require("modules.layouts")      -- dwindle / master / scrolling
require("modules.input")        -- teclado, touchpad, gestos, dispositivos
require("modules.binds")        -- keybinds y submaps
require("modules.rules")        -- window / layer / workspace rules
require("modules.autostart")    -- apps que arrancan junto con Hyprland
