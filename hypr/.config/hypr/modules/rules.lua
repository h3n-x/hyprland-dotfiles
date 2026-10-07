-- ============================================================================
-- Window / Layer / Workspace rules
-- https://wiki.hypr.land/configuring/core/rules/
-- ============================================================================

-- ---- Window rules ----

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- arregla problemas de drag en apps XWayland (ventanas invisibles de ayuda)
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Dialogos y utilidades que siempre queremos flotando y centrados
hl.window_rule({
    name  = "float-utility-dialogs",
    match = { class = [[(pavucontrol|blueman-manager|nm-connection-editor|org\.pulseaudio\.pavucontrol|xdg-desktop-portal-gtk|file-roller|qt5ct|qt6ct|nwg-look)]] },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "float-thunar-dialogs",
    match = { class = "thunar", title = [[(File Operation Progress|Confirm to replace files|Rename.*)]] },
    float  = true,
    center = true,
})

-- Centro de configuracion (Fase 10 B1, dotshell/settings.qml): flotando, al
-- centro, a su tamano. Clase y titulo verificados en la ventana real.
hl.window_rule({
    name  = "settings-center",
    match = { class = [[^org\.quickshell$]], title = "^Configuración$" },
    float  = true,
    center = true,
    size   = { 1100, 720 },
})

-- Picture-in-picture (mpv --title=piptitle, YouTube PiP de Firefox/Chromium)
hl.window_rule({
    name  = "picture-in-picture",
    match = { title = [[(Picture[- ]in[- ][Pp]icture|piptitle)]] },
    float     = true,
    pin       = true,
    move      = { "monitor_w-window_w-20", "monitor_h-window_h-20" },
    size      = { 480, 270 },
    no_shadow = true,
})


-- Ejemplos de asignacion de apps a workspaces (ajustar segun tus apps reales)
-- hl.window_rule({ name = "ws-browser", match = { class = "firefox" },        workspace = "2" })
-- hl.window_rule({ name = "ws-chat",    match = { class = "[Vv]esktop" },     workspace = "5" })
-- hl.window_rule({ name = "ws-steam",   match = { class = "steam" },          workspace = "9" })

-- ---- Layer rules (blur para launcher, notificaciones) ----
-- Shell (Quickshell, decisiones E1-E4 del design system). Profundidad
-- discreta: superficies al 0.92 con blur solo donde hay tarjeta. ignore_alpha
-- 0.85: el blur se enciende recien con la tarjeta casi opaca. Con 0.3, al
-- animar la entrada/salida en QML (no_anim) el blur aparecia entero antes que
-- el contenido y quedaba un rectangulo esmerilado un instante; asi la
-- entrada/salida es un fundido limpio. Tambien deja afuera el margen
-- transparente y la sombra.
-- Paneles flotantes (centro de control, toasts, OSD, launcher):
-- no_anim (D8): los paneles animan su contenido en QML (Presence), asi no hay
-- doble animacion con el fade de capas de Hyprland.
hl.layer_rule({ match = { namespace = "quickshell-panel" }, blur = true, ignore_alpha = 0.85, no_anim = true })
-- La barra ("quickshell") no lleva blur: cada Pill ya tiene su propio fondo
-- solido (ver Pill.qml), asi que el unico efecto visible del blur era detras
-- de los huecos transparentes entre pills -- a pedido del usuario, sin blur
-- ahi (E3). Sus desplegables son popups de esta capa: blur_popups los
-- difumina a ellos sin tocar la barra.
hl.layer_rule({ match = { namespace = "quickshell" },       blur_popups = true, ignore_alpha = 0.85 })
hl.layer_rule({ match = { namespace = "hyprpicker" },        no_anim = true })
-- Wallpaper dibujado por Quickshell (Fase 3 B6): sin el fade de capas de
-- Hyprland, que al recrear la ventana (recarga dura de la shell) dejaba ver
-- el color de fondo ~0.3 s. El cambio de wallpaper ya es un fundido en QML.
hl.layer_rule({ match = { namespace = "quickshell-wallpaper" }, no_anim = true })

-- Widgets/relojes que deben verse incluso arriba del bloqueo (ninguno por ahora)
-- hl.layer_rule({ match = { namespace = "some-widget" }, above_lock = 1 })

-- ---- Workspace rules ----
-- Sin reglas fijas a una pantalla (Fase 10 B5: la config versionada es
-- generica): Hyprland abre el escritorio 1 en la primera pantalla. Asignar
-- escritorios a pantallas llega con la Fase 11.
