-- ============================================================================
-- Monitores
-- https://wiki.hypr.land/configuring/core/monitors/
-- ============================================================================

-- Panel interno del HP Victus 15 fb2xxx (Chimei Innolux 0x1560, 1920x1080@144)
-- Identificado por descripcion (mas estable que el nombre de puerto eDP-1
-- ante cambios de kernel/driver). Confirmar con: hyprctl monitors all
hl.monitor({
    output   = "desc:Chimei Innolux Corporation 0x1560",
    mode     = "1920x1080@144",
    position = "0x0",
    scale    = 1.5,
    vrr      = 0,
})

-- Fallback para cualquier otro monitor (ej. HDMI/USB-C externo) que no tenga
-- regla explicita: se ubica automaticamente a la derecha de los existentes.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- ---- Ejemplo listo para descomentar si conectas un monitor externo fijo ----
-- hl.monitor({
--     output   = "desc:REEMPLAZAR-CON-hyprctl-monitors-all",
--     mode     = "preferred",
--     position = "1920x0",
--     scale    = 1,
-- })
--
-- Y en modules/rules.lua podrias fijar workspaces a ese monitor con:
-- hl.workspace_rule({ workspace = "1", monitor = "desc:..." })
