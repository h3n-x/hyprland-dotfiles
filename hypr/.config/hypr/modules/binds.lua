-- ============================================================================
-- Keybinds
-- https://wiki.hypr.land/configuring/core/binds/
-- https://wiki.hypr.land/configuring/core/dispatchers/
--
-- Cada atajo lleva { desc = "Group · Text" } (Fase 4 B10), obligatoria: la
-- leen la guia de atajos (SUPER+/), la tabla del README (scripts/keybinds
-- markdown) y la pagina Atajos del centro de configuracion, siempre desde
-- Hyprland (hyprctl binds -j), nunca de este archivo. scripts/keybinds check
-- falla si un atajo no la tiene. En ingles (Fase 15 B3): es la clave del
-- catalogo de traducciones (contextos "keybind group" y "keybind"; i18n check
-- exige su traduccion). Grupos: Shell, Apps, System, Windows, Workspaces,
-- Capture, Theme, Media, Resize mode. Texto: verbo primero, 28 caracteres como
-- mucho; una familia (flechas, 1-0, volumen) comparte la misma descripcion y
-- la guia la muestra en una sola fila.
-- ============================================================================

local mainMod = "SUPER"

local terminal = "kitty"
local fileManager = "thunar"
local browser = "zen-browser"

local scripts = os.getenv("HOME") .. "/.config/hypr/scripts"

-- ---------------------------------------------------------------------------
-- Programas y utilidades
-- ---------------------------------------------------------------------------
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal), { desc = "Apps · Terminal" })
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs -c dotshell ipc call launcher toggle"), { desc = "Shell · App launcher" })
-- Selector de ventanas (Quickshell, Fase 4 B4): con Super apretado, TAB y
-- SHIFT+TAB mueven y soltar Super cambia; si Super ya se solto, flechas/Enter.
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("qs -c dotshell ipc call switcher next"), { desc = "Shell · Switch window" })
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.exec_cmd("qs -c dotshell ipc call switcher prev"), { desc = "Shell · Switch window" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { desc = "Apps · Files" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser), { desc = "Apps · Browser" })

-- Centro de configuracion (Quickshell, Fase 10 B1): abre la ventana o trae la
-- que esta abierta (scripts/settings-ui; tambien el engranaje del centro de control).
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(scripts .. "/settings-ui"), { desc = "System · Settings" })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(scripts .. "/lock --user"), { desc = "System · Lock the screen" })
-- Bloqueo de emergencia (Fase 9 B1, D12): con el bloqueo de Quickshell vivo
-- pero inutilizable, lo cambia por el hyprlock de emergencia (sigue pidiendo
-- la contrasena; nunca desbloquea). Sin un bloqueo en curso no hace nada.
hl.bind(mainMod .. " + CTRL + ALT + L", hl.dsp.exec_cmd(scripts .. "/lock --emergency"), { locked = true, desc = "System · Emergency lock" })
-- Menu de energia y sesion (Quickshell, Fase 4 B1). SUPER+SHIFT+M abre la
-- confirmacion de cerrar sesion (antes salia al instante).
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("qs -c dotshell ipc call power toggle"), { desc = "System · Power and session" })
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("qs -c dotshell ipc call power confirm logout"), { desc = "System · Log out" })
-- Salida de emergencia de Hyprland, sin confirmar y sin depender de Quickshell
-- (por si la shell no responde).
hl.bind(mainMod .. " + CTRL + SHIFT + M", hl.dsp.exit(), { desc = "System · Emergency exit" })

-- Dashboard (Quickshell, Fase 4 B7): Inicio, Hoy, Sistema y Escritorios, en el
-- monitor enfocado y con el foco en el reproductor si algo esta sonando.
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("qs -c dotshell ipc call dashboard toggle"), { desc = "Shell · Dashboard" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs -c dotshell ipc call controlcenter toggle"), { desc = "Shell · Control center" }) -- mostrar/ocultar
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("qs -c dotshell ipc call controlcenter clearAll"), { desc = "Shell · Clear notifications" }) -- limpiar notificaciones
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("qs -c dotshell ipc call bar toggle"), { desc = "Shell · Show or hide the bar" }) -- mostrar/ocultar
hl.bind(mainMod .. " + SHIFT + CTRL + B", hl.dsp.exec_cmd("qs -c dotshell ipc call shell reload"), { desc = "Shell · Reload the shell" }) -- reload duro (recrea ventanas)

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { desc = "Apps · Color picker" })
-- Historial del portapapeles (Quickshell, Fase 4 B2)
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("qs -c dotshell ipc call clipboard toggle"), { desc = "Shell · Clipboard" })
-- Galeria de wallpapers (Quickshell, Fase 3). Sin Quickshell corriendo:
-- theme-apply.sh <archivo> desde una terminal.
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("qs -c dotshell ipc call gallery toggle"), { desc = "Theme · Wallpaper gallery" })
-- Deshacer el ultimo cambio de tema (Fase 3 B5): vuelve al anterior del
-- historial con su esquema y contraste; notifica a que tema volvio.
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd(scripts .. "/theme-apply.sh --undo"), { desc = "Theme · Undo the last theme" })
-- Selector de emoji (Quickshell, Fase 4 B3): Enter escribe, Ctrl+Enter copia
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("qs -c dotshell ipc call emoji toggle"), { desc = "Shell · Emoji" })
-- Guia de atajos (Quickshell, Fase 4 B10): lee las descripciones de arriba.
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("qs -c dotshell ipc call keybinds toggle"), { desc = "Shell · Shortcut guide" })

-- Capturas y grabacion (Fase 4 B8, ver scripts/screenshot y scripts/record):
-- la vista previa y la pill de grabacion son de Quickshell (CaptureState).
-- Print: monitor enfocado; region con la pantalla congelada; grabar: zona
-- elegida o monitor enfocado, la misma tecla (o la pill) para parar.
hl.bind("Print", hl.dsp.exec_cmd(scripts .. "/screenshot full"), { desc = "Capture · Capture the monitor" })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(scripts .. "/screenshot region"), { desc = "Capture · Capture a region" })
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(scripts .. "/screenshot window"), { desc = "Capture · Capture the window" })
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd(scripts .. "/record toggle region"), { desc = "Capture · Record an area" })
hl.bind(mainMod .. " + ALT + SHIFT + R", hl.dsp.exec_cmd(scripts .. "/record toggle full"), { desc = "Capture · Record the monitor" })
hl.bind(mainMod .. " + ALT + G", hl.dsp.exec_cmd(scripts .. "/game-mode.sh toggle"), { desc = "System · Game mode" })

-- ---------------------------------------------------------------------------
-- Gestion de ventanas
-- ---------------------------------------------------------------------------
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { desc = "Windows · Close the window" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill(), { desc = "Windows · Force close" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { desc = "Windows · Floating" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(), { desc = "Windows · Fullscreen" })
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pin(), { desc = "Windows · Pin on every workspace" }) -- fijar ventana sobre todos los workspaces
hl.bind(mainMod .. " + C", hl.dsp.window.center(), { desc = "Windows · Center" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { desc = "Windows · Pseudotile" }) -- dwindle
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { desc = "Windows · Toggle the split" }) -- dwindle
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { desc = "Windows · Group" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.lock_active(), { desc = "Windows · Lock the group" })

-- Foco con flechas
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { desc = "Windows · Move focus" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { desc = "Windows · Move focus" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { desc = "Windows · Move focus" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { desc = "Windows · Move focus" })

-- Mover ventana con flechas
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }), { desc = "Windows · Move the window" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), { desc = "Windows · Move the window" })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }), { desc = "Windows · Move the window" })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }), { desc = "Windows · Move the window" })

-- Redimensionar con flechas (repetible mientras se mantiene apretado)
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true, desc = "Windows · Resize" })
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true, desc = "Windows · Resize" })
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true, desc = "Windows · Resize" })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true, desc = "Windows · Resize" })

-- Mover/redimensionar con el mouse (o touchpad sin boton fisico via CTRL/ALT)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, desc = "Windows · Move with the mouse" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, desc = "Windows · Resize with the mouse" })
hl.bind(mainMod .. " + Control_L", hl.dsp.window.drag(), { mouse = true, desc = "Windows · Move with the mouse" })
hl.bind(mainMod .. " + Alt_L", hl.dsp.window.resize(), { mouse = true, desc = "Windows · Resize with the mouse" })

-- ---------------------------------------------------------------------------
-- Workspaces
-- ---------------------------------------------------------------------------
for i = 1, 10 do
	local key = i % 10 -- 10 mapea a la tecla 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { desc = "Workspaces · Go to workspace" })
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { desc = "Workspaces · Move to workspace" })
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { desc = "Workspaces · Cycle workspaces" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { desc = "Workspaces · Cycle workspaces" })

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { desc = "Workspaces · Special workspace" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { desc = "Workspaces · Move to special" })

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
end, { desc = "Workspaces · Switch the layout" })

-- ---------------------------------------------------------------------------
-- Submap de resize (SUPER+R para entrar, ESC/Enter para salir)
-- ---------------------------------------------------------------------------
hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { desc = "Windows · Resize mode" })
hl.define_submap("resize", function()
	hl.bind("right", hl.dsp.window.resize({ x = 15, y = 0, relative = true }), { repeating = true, desc = "Resize mode · Resize" })
	hl.bind("left", hl.dsp.window.resize({ x = -15, y = 0, relative = true }), { repeating = true, desc = "Resize mode · Resize" })
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = -15, relative = true }), { repeating = true, desc = "Resize mode · Resize" })
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = 15, relative = true }), { repeating = true, desc = "Resize mode · Resize" })
	hl.bind("escape", hl.dsp.submap("reset"), { desc = "Resize mode · Leave the mode" })
	hl.bind("return", hl.dsp.submap("reset"), { desc = "Resize mode · Leave the mode" })
end)

-- ---------------------------------------------------------------------------
-- Multimedia y brillo (funcionan incluso con la sesion bloqueada -> locked=true)
-- ---------------------------------------------------------------------------
hl.bind(
	"XF86AudioRaiseVolume",
	-- Tope: media.volumeLimit (100, 125 o 150 %), del centro de configuracion (Fase 10 B4).
	hl.dsp.exec_cmd("sh -c 'wpctl set-volume -l \"$(~/.config/hypr/scripts/settings get media.volumeLimit)\" @DEFAULT_AUDIO_SINK@ 5%+'"),
	{ locked = true, repeating = true, desc = "Media · Volume" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true, desc = "Media · Volume" }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, desc = "Media · Mute" })
-- Bloq Mayus y Bloq Num: el estado para el aviso del OSD (Fase 10 B4) y el modulo
-- de la barra (Fase 11 B2); solo se lee si alguno lo usa. No consumen la tecla,
-- corren al soltarla (el estado ya es el final, al prender y al apagar). Al soltar
-- Bloq Mayus su modificador sigue activo (xkb lo bloquea al apretar y lo suelta al
-- soltar la segunda vez), por eso CAPS: sin el, el atajo nunca coincidia (Fase 16 B2,
-- probado en vivo). Hyprland ignora el de Bloq Num (MOD2) al comparar.
hl.bind("CAPS + Caps_Lock", hl.dsp.exec_cmd("qs -c dotshell ipc call osd keys"), { non_consuming = true, release = true, desc = "System · Caps Lock state" })
hl.bind("Num_Lock", hl.dsp.exec_cmd("qs -c dotshell ipc call osd keys"), { non_consuming = true, release = true, desc = "System · Num Lock state" })
-- Mostrar la barra mientras se mantiene Super (bar.peek, Fase 11 B3b): un atajo
-- global al apretar y otro al soltar Super_L; no consumen la tecla ni tapan otros
-- atajos de Super. Con la opcion apagada, la shell solo anota el estado.
hl.bind("SUPER_L", hl.dsp.global("quickshell:barPeek"), { ignore_mods = true, transparent = true, non_consuming = true, desc = "Shell · Show the bar (hold)" })
hl.bind("SUPER_L", hl.dsp.global("quickshell:barPeek"), { ignore_mods = true, transparent = true, non_consuming = true, release = true, desc = "Shell · Show the bar (hold)" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, desc = "Media · Mute the microphone" })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true, desc = "Media · Brightness" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true, desc = "Media · Brightness" })

-- Teclas multimedia -> reproductor de Quickshell (Fase 4 B5): el mismo
-- reproductor que muestran la pill de la barra y el dashboard.
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("qs -c dotshell ipc call media next"), { locked = true, desc = "Media · Next or previous track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("qs -c dotshell ipc call media playPause"), { locked = true, desc = "Media · Play or pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("qs -c dotshell ipc call media playPause"), { locked = true, desc = "Media · Play or pause" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("qs -c dotshell ipc call media previous"), { locked = true, desc = "Media · Next or previous track" })

-- ---------------------------------------------------------------------------
-- Tapa del laptop (HP Victus): bloquear al cerrar. Correr `hyprctl devices`
-- para confirmar el nombre exacto del switch en este equipo y ajustar abajo.
-- ---------------------------------------------------------------------------
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(scripts .. "/lock"), { locked = true })

-- ---------------------------------------------------------------------------
-- Global shortcuts para apps sandboxeadas (requiere XDPH, ya instalado)
-- ---------------------------------------------------------------------------
-- hl.bind(mainMod .. " + F10", hl.dsp.pass({ window = [[class:com\.obsproject\.Studio]] }))
