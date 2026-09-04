-- ============================================================================
-- Aspecto: general, decoration, blur, sombras, animaciones, cursor, render
-- https://wiki.hypr.land/configuring/core/config-options/
-- ============================================================================

-- Paleta generada por matugen (../../matugen/.config/matugen/templates/hyprland-colors.lua),
-- regenerada en cada cambio de wallpaper por scripts/wallpaper-selector.sh.
-- Fallback si todavia no se corrio matugen una vez (modules/colors.lua no existe).
local ok, colors = pcall(require, "modules.colors")
if not ok then
    colors = {
        primary = "cba6f7",
        secondary = "89b4fa",
        surface = "1e1e2e",
        surface_variant = "45475a",
        shadow = "1a1a1a",
    }
end

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 12,

        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(" .. colors.primary .. "ee)", "rgba(" .. colors.secondary .. "ee)" }, angle = 45 },
            inactive_border = "rgba(" .. colors.surface_variant .. "aa)",
        },

        resize_on_border    = true,
        hover_icon_on_border = true,
        allow_tearing        = false,

        layout = "dwindle",

        snap = {
            enabled       = true,
            window_gap    = 10,
            monitor_gap   = 10,
            border_overlap = false,
        },
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- active_opacity en 1.0 hacia que solo kitty se viera blureado (tiene
        -- su propia transparencia interna, background_opacity en kitty.conf,
        -- independiente de esto) -- el resto de las apps quedaban 100%
        -- opacas mientras estaban enfocadas, sin nada que blurear detras. En
        -- 0.92 (mismo valor que kitty) el blur ya activado en decoration.blur
        -- se aplica parejo a todas las apps, enfocadas o no.
        active_opacity     = 0.92,
        inactive_opacity   = 0.85,
        fullscreen_opacity = 1.0, -- juegos/video no deben ser translucidos

        dim_inactive = false,
        dim_strength = 0.5,

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = "rgba(" .. colors.shadow .. "ee)",
        },

        blur = {
            enabled  = true,
            size     = 6,
            passes   = 2,
            new_optimizations = true,
            ignore_opacity    = true,
            vibrancy          = 0.1696,
            popups            = true,
        },
    },

    animations = {
        enabled              = true,
        workspace_wraparound = true,
    },

    -- Cursor: use_cpu_buffer queda en "auto" (2) porque la iGPU AMD renderiza
    -- por defecto y solo pasa a NVIDIA on-demand para procesos puntuales.
    cursor = {
        enable_hyprcursor  = true,
        no_hardware_cursors = 2, -- auto
        use_cpu_buffer      = 2, -- auto (necesario si algun dia NVIDIA es la GPU activa)
        hide_on_touch        = true,
        inactive_timeout      = 0,
    },

    -- Reduce flicker en NVIDIA; no tiene efecto en AMD (que es la GPU activa
    -- normalmente), asi que se puede dejar siempre encendido sin costo.
    opengl = {
        nvidia_anti_flicker = true,
    },

    -- Con scale = 1.5 en monitors.lua, las apps XWayland (Steam, etc.) sin
    -- este flag renderizan a 1x y Hyprland las estira con blit -> fuentes
    -- pixeladas. force_zero_scaling deja que XWayland renderice nativo y
    -- Hyprland escale a nivel de compositor (mas nitido).
    xwayland = {
        force_zero_scaling = true,
    },

    misc = {
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        vrr                       = 1, -- pantalla interna no es VRR; se puede subir a 2 si conectas un monitor VRR externo
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,
        animate_manual_resizes    = true,
        animate_mouse_windowdragging = true,
        background_color          = "0x" .. colors.surface,
    },
})

-- ---- Curvas de animacion ----
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeOutCubic",   { type = "bezier", points = { {0.33, 1},    {0.68, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

-- ---- Arbol de animaciones ----
hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5,    bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.5,  spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4,    spring = "easy",   style = "popin 85%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 3,    bezier = "linear", style = "popin 85%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 2,    bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 2,    bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3,    bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 4,    bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2,    bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2,    bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.5,  bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 3,    bezier = "easeOutCubic", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 2,    bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2,    bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })
