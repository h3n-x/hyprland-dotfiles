// Generado por matugen -- no editar a mano, editar templates/quickshell-colors.qml.
// Mismo mapeo de roles Material You que la barra Waybar anterior:
// define las mismas variables semanticas (accent/fg/bg0..3/br/warning/critical/
// charging/hoverBg/hoverFg) para que los modulos de quickshell/modules/ se
// theming igual que el resto del rice.
//
// pragma Singleton no dispara el watchFiles automatico de Quickshell cuando
// este archivo lo reescribe un proceso externo (matugen) -- confirmado en
// vivo durante el spike de la migracion. El post_hook de este template (ver
// matugen/config.toml) llama a `qs ipc call colors reload` (IpcHandler
// definido en quickshell/.config/quickshell/dotshell/shell.qml) para
// recargar al instante, mismo rol que "hyprctl reload" en el template de
// Hyprland.
pragma Singleton
import QtQuick

QtObject {
    readonly property color accent: "{{colors.primary.default.hex}}"
    readonly property color fg: "{{colors.on_surface.default.hex}}"
    readonly property color bg0: "{{colors.surface_container_lowest.default.hex}}"
    readonly property color bg1: "{{colors.surface_container_low.default.hex}}"
    readonly property color bg2: "{{colors.surface_container.default.hex}}"
    readonly property color bg3: "{{colors.surface_container_high.default.hex}}"
    readonly property color br: "{{colors.outline.default.hex}}"
    readonly property color warning: "{{colors.tertiary_container.default.hex}}"
    readonly property color critical: "{{colors.error.default.hex}}"
    readonly property color charging: "{{colors.tertiary.default.hex}}"
    readonly property color hoverBg: bg1
    // alpha(@fg, 0.75) -- mismo fg con menos opacidad, calculado
    // aca en vez de pedirle a matugen un color mas (Qt.rgba toma 0..1, no 0..255).
    readonly property color hoverFg: Qt.rgba(fg.r, fg.g, fg.b, 0.75)
}
