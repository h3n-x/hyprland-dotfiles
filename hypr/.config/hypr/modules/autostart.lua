-- ============================================================================
-- Autostart
-- https://wiki.hypr.land/configuring/core/ (ver seccion Autostart en core/_index)
-- ============================================================================

hl.on("hyprland.start", function()
    -- Agente de autenticacion (polkit) -- reemplaza a polkit-kde-agent
    hl.exec_cmd("sh -c 'systemctl --user start hyprpolkitagent.service 2>/dev/null || /usr/lib/hyprpolkitagent'")

    -- Barra, notificaciones, wallpaper, idle/lock, filtro de luz azul
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprsunset")

    -- Historial de portapapeles (texto e imagenes por separado)
    hl.exec_cmd("sh -c 'wl-paste --type text --watch cliphist store'")
    hl.exec_cmd("sh -c 'wl-paste --type image --watch cliphist store'")
    hl.exec_cmd("wl-clip-persist --clipboard both")

    -- Applet de red y bluetooth (si estan instalados)
    hl.exec_cmd("sh -c 'command -v nm-applet >/dev/null && nm-applet --indicator &'")
    hl.exec_cmd("sh -c 'command -v blueman-applet >/dev/null && blueman-applet &'")

    -- Gestor de energia (power-profiles-daemon ya esta como servicio de systemd,
    -- pero el applet grafico si aplica se puede sumar aca)
end)
