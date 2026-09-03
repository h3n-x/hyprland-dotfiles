-- ============================================================================
-- Input: teclado, touchpad, raton, gestos
-- https://wiki.hypr.land/configuring/core/config-options/#input
-- https://wiki.hypr.land/configuring/core/devices/
-- ============================================================================

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "", -- ej: "caps:escape" para Caps Lock -> Escape
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0.0,
        accel_profile = "adaptive",

        numlock_by_default = true,
        repeat_rate  = 40,
        repeat_delay = 300,

        touchpad = {
            natural_scroll         = false, -- true = estilo "trackpad de Mac"
            tap_to_click             = true,
            tap_and_drag              = true,
            drag_lock                 = 1,
            clickfinger_behavior       = true, -- click con 2 dedos = click derecho
            disable_while_typing        = true,
            scroll_factor                = 1.0,
        },
    },
})

-- ---- Gestos tactiles del touchpad ----
-- 3 dedos horizontal: cambiar de workspace
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- 3 dedos hacia arriba: vista de ventana flotante/fullscreen rapido (toggle)
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })
-- 4 dedos pellizco: zoom del cursor (accesibilidad / detalle)
hl.gesture({ fingers = 4, direction = "pinch", action = "cursor_zoom", zoom_level = 2 })

-- ---- Configuracion por dispositivo ----
-- Ejemplo: ver nombres reales con `hyprctl devices` y descomentar/ajustar.
-- hl.device({
--     name        = "logitech-mx-master-3",
--     sensitivity = -0.3,
--     accel_profile = "flat",
-- })
