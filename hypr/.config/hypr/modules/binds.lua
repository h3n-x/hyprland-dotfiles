-- ============================================================================
-- Keybinds
-- https://wiki.hypr.land/configuring/core/binds/
-- https://wiki.hypr.land/configuring/core/dispatchers/
-- ============================================================================

local mainMod = "SUPER"

local terminal    = "kitty"
local launcher     = "rofi -show drun -show-icons"
local windowSwitch  = "rofi -show window -show-icons"
local altLauncher    = "hyprlauncher"
local fileManager      = "thunar"
local browser           = "librewolf"

local scripts = os.getenv("HOME") .. "/.config/hypr/scripts"

-- ---------------------------------------------------------------------------
-- Programas y utilidades
-- ---------------------------------------------------------------------------
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(altLauncher))
hl.bind(mainMod .. " + TAB",    hl.dsp.exec_cmd(windowSwitch))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd(browser))

hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd(scripts .. "/lock.sh"))
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd(scripts .. "/power-menu.sh")) -- bloquear/suspender/cerrar sesion/reiniciar/apagar
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit()) -- salida forzada de Hyprland, sin confirmar

hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -C"))
hl.bind(mainMod .. " + SHIFT + B",        hl.dsp.exec_cmd("killall -SIGUSR1 waybar")) -- mostrar/ocultar
hl.bind(mainMod .. " + SHIFT + CTRL + B", hl.dsp.exec_cmd("killall -SIGUSR2 waybar")) -- recargar config + estilo

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(scripts .. "/clipboard-menu"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(scripts .. "/wallpaper-selector.sh"))

-- Capturas y grabacion (ver scripts/screenshot y scripts/record)
hl.bind("Print",                   hl.dsp.exec_cmd(scripts .. "/screenshot full"))
hl.bind(mainMod .. " + Print",     hl.dsp.exec_cmd(scripts .. "/screenshot region"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(scripts .. "/screenshot window"))
hl.bind(mainMod .. " + ALT + R",   hl.dsp.exec_cmd(scripts .. "/record toggle"))

-- ---------------------------------------------------------------------------
-- Gestion de ventanas
-- ---------------------------------------------------------------------------
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pin())          -- fijar ventana sobre todos los workspaces
hl.bind(mainMod .. " + C",         hl.dsp.window.center())
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())          -- dwindle
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))    -- dwindle
hl.bind(mainMod .. " + G",         hl.dsp.group.toggle())
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.lock_active())

-- Foco con flechas
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Mover ventana con flechas
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Redimensionar con flechas (repetible mientras se mantiene apretado)
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 30,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -30, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })

-- Mover/redimensionar con el mouse (o touchpad sin boton fisico via CTRL/ALT)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + Control_L", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + Alt_L",     hl.dsp.window.resize(), { mouse = true })

-- ---------------------------------------------------------------------------
-- Workspaces
-- ---------------------------------------------------------------------------
for i = 1, 10 do
    local key = i % 10 -- 10 mapea a la tecla 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- ---------------------------------------------------------------------------
-- Cambiar de layout en caliente (dwindle -> master -> scrolling -> dwindle)
-- ---------------------------------------------------------------------------
local layoutCycle = { "dwindle", "master", "scrolling" }
local layoutIdx = 1
hl.bind(mainMod .. " + ALT + L", function()
    layoutIdx = (layoutIdx % #layoutCycle) + 1
    local next_layout = layoutCycle[layoutIdx]
    hl.dispatch(hl.dsp.exec_cmd("notify-send -a Hyprland 'Layout' '" .. next_layout .. "'"))
    hl.config({ general = { layout = next_layout } })
end)

-- ---------------------------------------------------------------------------
-- Submap de resize (SUPER+R para entrar, ESC/Enter para salir)
-- ---------------------------------------------------------------------------
hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("right",  hl.dsp.window.resize({ x = 15,  y = 0,   relative = true }), { repeating = true })
    hl.bind("left",   hl.dsp.window.resize({ x = -15, y = 0,   relative = true }), { repeating = true })
    hl.bind("up",     hl.dsp.window.resize({ x = 0,   y = -15, relative = true }), { repeating = true })
    hl.bind("down",   hl.dsp.window.resize({ x = 0,   y = 15,  relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("return", hl.dsp.submap("reset"))
end)

-- ---------------------------------------------------------------------------
-- Multimedia y brillo (funcionan incluso con hyprlock activo -> locked=true)
-- ---------------------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- ---------------------------------------------------------------------------
-- Tapa del laptop (HP Victus): bloquear al cerrar. Correr `hyprctl devices`
-- para confirmar el nombre exacto del switch en este equipo y ajustar abajo.
-- ---------------------------------------------------------------------------
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprlock"), { locked = true })

-- ---------------------------------------------------------------------------
-- Global shortcuts para apps sandboxeadas (requiere XDPH, ya instalado)
-- ---------------------------------------------------------------------------
-- hl.bind(mainMod .. " + F10", hl.dsp.pass({ window = [[class:com\.obsproject\.Studio]] }))
