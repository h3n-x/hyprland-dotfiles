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
-- La barra (namespace "quickshell") no lleva blur: cada Pill ya tiene su
-- propio fondo solido (ver Pill.qml), asi que el unico efecto visible del
-- blur era detras de los huecos transparentes entre pills -- a pedido del
-- usuario, sin blur ahi.
hl.layer_rule({ match = { namespace = "rofi" },            blur = true, ignore_alpha = 0.3 })
-- El Control Center y los toasts de notificaciones (quickshell/
-- ControlCenter.qml, NotificationToast.qml) reemplazan a swaync -- mismo
-- namespace "quickshell" que la barra, sin blur (ver nota arriba).
hl.layer_rule({ match = { namespace = "hyprpicker" },        no_anim = true })

-- Widgets/relojes que deben verse incluso arriba de hyprlock (ninguno por ahora)
-- hl.layer_rule({ match = { namespace = "some-widget" }, above_lock = 1 })

-- ---- Workspace rules ----
hl.workspace_rule({
    workspace = "1",
    monitor    = "desc:Chimei Innolux Corporation 0x1560",
    default     = true,
})
