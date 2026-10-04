-- ============================================================================
-- Keybinds
-- https://wiki.hypr.land/configuring/core/binds/
-- https://wiki.hypr.land/configuring/core/dispatchers/
--
-- Cada atajo lleva { desc = "Grupo · Texto" } (Fase 4 B10), obligatoria: la
-- leen la guia de atajos (SUPER+/), la tabla del README (scripts/keybinds
-- markdown) y el futuro centro de configuracion, siempre desde Hyprland
-- (hyprctl binds -j), nunca de este archivo. scripts/keybinds check falla si
-- un atajo no la tiene. Grupos: Shell, Programas, Sistema, Ventanas,
-- Escritorios, Capturas, Tema, Multimedia, Modo cambiar tamaño. Texto: verbo
-- primero, 28 caracteres como mucho; una familia (flechas, 1-0, volumen)
-- comparte la misma descripcion y la guia la muestra en una sola fila.
-- ============================================================================

local mainMod = "SUPER"

local terminal = "kitty"
local fileManager = "thunar"
local browser = "zen-browser"

local scripts = os.getenv("HOME") .. "/.config/hypr/scripts"

-- ---------------------------------------------------------------------------
-- Programas y utilidades
-- ---------------------------------------------------------------------------
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal), { desc = "Programas · Terminal" })
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs -c dotshell ipc call launcher toggle"), { desc = "Shell · Lanzador de aplicaciones" })
-- Selector de ventanas (Quickshell, Fase 4 B4): con Super apretado, TAB y
-- SHIFT+TAB mueven y soltar Super cambia; si Super ya se solto, flechas/Enter.
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("qs -c dotshell ipc call switcher next"), { desc = "Shell · Cambiar de ventana" })
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.exec_cmd("qs -c dotshell ipc call switcher prev"), { desc = "Shell · Cambiar de ventana" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { desc = "Programas · Archivos" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser), { desc = "Programas · Navegador" })

-- Centro de configuracion (Quickshell, Fase 10 B1): abre la ventana o trae la
-- que esta abierta (scripts/settings-ui; tambien el engranaje del centro de control).
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(scripts .. "/settings-ui"), { desc = "Sistema · Configuración" })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(scripts .. "/lock --user"), { desc = "Sistema · Bloquear la pantalla" })
-- Bloqueo de emergencia (Fase 9 B1, D12): con el bloqueo de Quickshell vivo
-- pero inutilizable, lo cambia por el hyprlock de emergencia (sigue pidiendo
-- la contrasena; nunca desbloquea). Sin un bloqueo en curso no hace nada.
hl.bind(mainMod .. " + CTRL + ALT + L", hl.dsp.exec_cmd(scripts .. "/lock --emergency"), { locked = true, desc = "Sistema · Bloqueo de emergencia" })
-- Menu de energia y sesion (Quickshell, Fase 4 B1). SUPER+SHIFT+M abre la
-- confirmacion de cerrar sesion (antes salia al instante).
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("qs -c dotshell ipc call power toggle"), { desc = "Sistema · Energía y sesión" })
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("qs -c dotshell ipc call power confirm logout"), { desc = "Sistema · Cerrar sesión" })
-- Salida de emergencia de Hyprland, sin confirmar y sin depender de Quickshell
-- (por si la shell no responde).
hl.bind(mainMod .. " + CTRL + SHIFT + M", hl.dsp.exit(), { desc = "Sistema · Salida de emergencia" })

-- Dashboard (Quickshell, Fase 4 B7): Inicio, Hoy, Sistema y Escritorios, en el
-- monitor enfocado y con el foco en el reproductor si algo esta sonando.
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("qs -c dotshell ipc call dashboard toggle"), { desc = "Shell · Dashboard" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs -c dotshell ipc call controlcenter toggle"), { desc = "Shell · Centro de control" }) -- mostrar/ocultar
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("qs -c dotshell ipc call controlcenter clearAll"), { desc = "Shell · Limpiar notificaciones" }) -- limpiar notificaciones
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("qs -c dotshell ipc call bar toggle"), { desc = "Shell · Mostrar u ocultar la barra" }) -- mostrar/ocultar
hl.bind(mainMod .. " + SHIFT + CTRL + B", hl.dsp.exec_cmd("qs -c dotshell ipc call shell reload"), { desc = "Shell · Recargar la shell" }) -- reload duro (recrea ventanas)

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { desc = "Programas · Selector de color" })
-- Historial del portapapeles (Quickshell, Fase 4 B2)
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("qs -c dotshell ipc call clipboard toggle"), { desc = "Shell · Portapapeles" })
-- Galeria de wallpapers (Quickshell, Fase 3). Sin Quickshell corriendo:
-- theme-apply.sh <archivo> desde una terminal.
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("qs -c dotshell ipc call gallery toggle"), { desc = "Tema · Galería de fondos" })
-- Deshacer el ultimo cambio de tema (Fase 3 B5): vuelve al anterior del
-- historial con su esquema y contraste; notifica a que tema volvio.
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd(scripts .. "/theme-apply.sh --undo"), { desc = "Tema · Deshacer el último tema" })
-- Selector de emoji (Quickshell, Fase 4 B3): Enter escribe, Ctrl+Enter copia
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("qs -c dotshell ipc call emoji toggle"), { desc = "Shell · Emoji" })
-- Guia de atajos (Quickshell, Fase 4 B10): lee las descripciones de arriba.
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("qs -c dotshell ipc call keybinds toggle"), { desc = "Shell · Guía de atajos" })

-- Capturas y grabacion (Fase 4 B8, ver scripts/screenshot y scripts/record):
-- la vista previa y la pill de grabacion son de Quickshell (CaptureState).
-- Print: monitor enfocado; region con la pantalla congelada; grabar: zona
-- elegida o monitor enfocado, la misma tecla (o la pill) para parar.
hl.bind("Print", hl.dsp.exec_cmd(scripts .. "/screenshot full"), { desc = "Capturas · Capturar el monitor" })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(scripts .. "/screenshot region"), { desc = "Capturas · Capturar una región" })
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(scripts .. "/screenshot window"), { desc = "Capturas · Capturar la ventana" })
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd(scripts .. "/record toggle region"), { desc = "Capturas · Grabar una zona" })
hl.bind(mainMod .. " + ALT + SHIFT + R", hl.dsp.exec_cmd(scripts .. "/record toggle full"), { desc = "Capturas · Grabar el monitor" })
hl.bind(mainMod .. " + ALT + G", hl.dsp.exec_cmd(scripts .. "/game-mode.sh toggle"), { desc = "Sistema · Modo juego" })

-- ---------------------------------------------------------------------------
-- Gestion de ventanas
-- ---------------------------------------------------------------------------
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { desc = "Ventanas · Cerrar la ventana" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill(), { desc = "Ventanas · Forzar el cierre" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { desc = "Ventanas · Flotante" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(), { desc = "Ventanas · Pantalla completa" })
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pin(), { desc = "Ventanas · Fijar en todas partes" }) -- fijar ventana sobre todos los workspaces
hl.bind(mainMod .. " + C", hl.dsp.window.center(), { desc = "Ventanas · Centrar" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { desc = "Ventanas · Pseudomosaico" }) -- dwindle
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { desc = "Ventanas · Alternar la división" }) -- dwindle
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { desc = "Ventanas · Agrupar" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.lock_active(), { desc = "Ventanas · Bloquear el grupo" })

-- Foco con flechas
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { desc = "Ventanas · Mover el foco" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { desc = "Ventanas · Mover el foco" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { desc = "Ventanas · Mover el foco" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { desc = "Ventanas · Mover el foco" })

-- Mover ventana con flechas
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }), { desc = "Ventanas · Mover la ventana" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), { desc = "Ventanas · Mover la ventana" })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }), { desc = "Ventanas · Mover la ventana" })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }), { desc = "Ventanas · Mover la ventana" })

-- Redimensionar con flechas (repetible mientras se mantiene apretado)
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true, desc = "Ventanas · Cambiar el tamaño" })
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true, desc = "Ventanas · Cambiar el tamaño" })
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true, desc = "Ventanas · Cambiar el tamaño" })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true, desc = "Ventanas · Cambiar el tamaño" })

-- Mover/redimensionar con el mouse (o touchpad sin boton fisico via CTRL/ALT)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, desc = "Ventanas · Mover con el ratón" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, desc = "Ventanas · Redimensionar con el ratón" })
hl.bind(mainMod .. " + Control_L", hl.dsp.window.drag(), { mouse = true, desc = "Ventanas · Mover con el ratón" })
hl.bind(mainMod .. " + Alt_L", hl.dsp.window.resize(), { mouse = true, desc = "Ventanas · Redimensionar con el ratón" })

-- ---------------------------------------------------------------------------
-- Workspaces
-- ---------------------------------------------------------------------------
for i = 1, 10 do
	local key = i % 10 -- 10 mapea a la tecla 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { desc = "Escritorios · Ir al escritorio" })
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { desc = "Escritorios · Mover al escritorio" })
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { desc = "Escritorios · Recorrer escritorios" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { desc = "Escritorios · Recorrer escritorios" })

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { desc = "Escritorios · Escritorio especial" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { desc = "Escritorios · Mover al especial" })

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
end, { desc = "Escritorios · Cambiar la distribución" })

-- ---------------------------------------------------------------------------
-- Submap de resize (SUPER+R para entrar, ESC/Enter para salir)
-- ---------------------------------------------------------------------------
hl.bind(mainMod .. " + R", hl.dsp.submap("resize"), { desc = "Ventanas · Modo cambiar tamaño" })
hl.define_submap("resize", function()
	hl.bind("right", hl.dsp.window.resize({ x = 15, y = 0, relative = true }), { repeating = true, desc = "Modo cambiar tamaño · Cambiar el tamaño" })
	hl.bind("left", hl.dsp.window.resize({ x = -15, y = 0, relative = true }), { repeating = true, desc = "Modo cambiar tamaño · Cambiar el tamaño" })
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = -15, relative = true }), { repeating = true, desc = "Modo cambiar tamaño · Cambiar el tamaño" })
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = 15, relative = true }), { repeating = true, desc = "Modo cambiar tamaño · Cambiar el tamaño" })
	hl.bind("escape", hl.dsp.submap("reset"), { desc = "Modo cambiar tamaño · Salir del modo" })
	hl.bind("return", hl.dsp.submap("reset"), { desc = "Modo cambiar tamaño · Salir del modo" })
end)

-- ---------------------------------------------------------------------------
-- Multimedia y brillo (funcionan incluso con la sesion bloqueada -> locked=true)
-- ---------------------------------------------------------------------------
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true, desc = "Multimedia · Volumen" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true, desc = "Multimedia · Volumen" }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, desc = "Multimedia · Silenciar" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, desc = "Multimedia · Silenciar el micrófono" })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true, desc = "Multimedia · Brillo" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true, desc = "Multimedia · Brillo" })

-- Teclas multimedia -> reproductor de Quickshell (Fase 4 B5): el mismo
-- reproductor que muestran la pill de la barra y el dashboard.
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("qs -c dotshell ipc call media next"), { locked = true, desc = "Multimedia · Pista siguiente o anterior" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("qs -c dotshell ipc call media playPause"), { locked = true, desc = "Multimedia · Reproducir o pausar" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("qs -c dotshell ipc call media playPause"), { locked = true, desc = "Multimedia · Reproducir o pausar" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("qs -c dotshell ipc call media previous"), { locked = true, desc = "Multimedia · Pista siguiente o anterior" })

-- ---------------------------------------------------------------------------
-- Tapa del laptop (HP Victus): bloquear al cerrar. Correr `hyprctl devices`
-- para confirmar el nombre exacto del switch en este equipo y ajustar abajo.
-- ---------------------------------------------------------------------------
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(scripts .. "/lock"), { locked = true })

-- ---------------------------------------------------------------------------
-- Global shortcuts para apps sandboxeadas (requiere XDPH, ya instalado)
-- ---------------------------------------------------------------------------
-- hl.bind(mainMod .. " + F10", hl.dsp.pass({ window = [[class:com\.obsproject\.Studio]] }))
