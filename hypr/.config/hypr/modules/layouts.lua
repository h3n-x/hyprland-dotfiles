-- ============================================================================
-- Layouts: dwindle (activo), master y scrolling configurados pero inactivos
-- Cambiar general.layout en lookandfeel.lua para activar otro.
-- https://wiki.hypr.land/configuring/layouts/
-- ============================================================================

hl.config({
    dwindle = {
        preserve_split  = true,
        smart_split      = false,
        smart_resizing   = true,
        force_split      = 0,
        default_split_ratio = 1.0,
    },

    master = {
        mfact             = 0.55,
        new_status        = "master",
        new_on_top        = false,
        orientation       = "left",
        smart_resizing     = true,
    },

    -- Alternativa estilo niri/PaperWM: util en el panel de 1080p de esta
    -- laptop si en algun momento preferis navegar por columnas en vez de
    -- splits. Activar con general.layout = "scrolling".
    scrolling = {
        fullscreen_on_one_column = true,
        column_width              = 0.5,
        follow_focus               = true,
    },
})
