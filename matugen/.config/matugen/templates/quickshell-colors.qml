// Generado por matugen -- no editar a mano, editar templates/quickshell-colors.qml.
// Variables semanticas que usan los modulos (accent/fg/bg0..3/br/warning/
// critical/charging/hoverBg/hoverFg), mapeadas a roles Material 3 de matugen.
// La migracion a roles M3 con nombre propio es parte de P1.9/P1.10 (ver
// el sistema de diseno).
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
    // tertiary y no tertiary_container: el container es un tono oscuro pensado
    // como fondo, y como texto sobre bg1 daba 1.8:1 (KI-C12). tertiary da ~10:1.
    readonly property color warning: "{{colors.tertiary.default.hex}}"
    readonly property color critical: "{{colors.error.default.hex}}"
    readonly property color charging: "{{colors.tertiary.default.hex}}"
    // Capa de estado M3 de hover horneada: fg al 8% sobre bg1 (Tokens.stateLayer.
    // hover). Antes era bg1 a secas -- el hover no se veia sobre filas/pills bg1.
    readonly property color hoverBg: Qt.tint(bg1, Qt.rgba(fg.r, fg.g, fg.b, 0.08))
    // alpha(@fg, 0.75) -- mismo fg con menos opacidad, calculado
    // aca en vez de pedirle a matugen un color mas (Qt.rgba toma 0..1, no 0..255).
    readonly property color hoverFg: Qt.rgba(fg.r, fg.g, fg.b, 0.75)

}
