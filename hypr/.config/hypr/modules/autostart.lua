-- ============================================================================
-- Autostart
-- https://wiki.hypr.land/configuring/core/ (ver seccion Autostart en core/_index)
-- ============================================================================

hl.on("hyprland.start", function()
    -- Agente de autenticacion (polkit) -- reemplaza a polkit-kde-agent
    hl.exec_cmd("sh -c 'systemctl --user start hyprpolkitagent.service 2>/dev/null || /usr/lib/hyprpolkitagent'")

    -- Barra + notificaciones + control center, wallpaper, idle/lock,
    -- filtro de luz azul. Todo Quickshell (QML), ver quickshell/.config/
    -- quickshell/dotshell/ y README seccion Quickshell -- reemplazo de
    -- Waybar Y de swaync (NotificationServer propio, ver
    -- NotificationState.qml -- no pueden convivir dos dueños del mismo
    -- servicio DBus org.freedesktop.Notifications).
    hl.exec_cmd("qs -c dotshell")
    -- El wallpaper lo dibuja Quickshell (Fase 3 B6); hyprpaper solo si se
    -- eligio como vuelta atras con `theme-apply.sh --backend hyprpaper`.
    hl.exec_cmd("sh -c '[ \"$(~/.config/hypr/scripts/theme-apply.sh --backend status)\" = hyprpaper ] && exec hyprpaper'")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprsunset")

    -- Temas de arranque/login que quedaron pendientes si la sesion anterior
    -- termino antes de que theme-apply.sh los regenerara (Fase 3 B2). Sin
    -- nada pendiente no hace nada.
    hl.exec_cmd("sh -c '~/.config/hypr/scripts/theme-apply.sh --flush-system'")

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
