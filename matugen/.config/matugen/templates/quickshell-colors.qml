// Generado por matugen -- no editar a mano, editar templates/quickshell-colors.qml.
// Variables semanticas que usan los modulos (accent/fg/bg0..3/br/warning/
// critical/charging/hoverBg/hoverFg), mapeadas a roles Material 3 de matugen.
// Abajo, los roles Material 3 con prefijo m3 (m3surface, m3onSurface...), que
// usan los modulos migrados a tokens (P1.10). Mapa en DESIGN_TOKENS.md.
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


    // ---- Roles Material 3 (decision C1, P1.9) -----------------------------
    // Nombre oficial de M3 en camelCase con prefijo "m3": QML no admite una
    // propiedad onX junto a una propiedad X en el mismo objeto (toma onX como
    // el handler de X -- "Cannot assign a value to a signal"), y M3 siempre
    // tiene los dos (surface/onSurface, primary/onPrimary...). Los modulos
    // migran a estos nombres en P1.10.
    readonly property color m3surface: "{{colors.surface.default.hex}}"
    readonly property color m3surfaceContainerLowest: "{{colors.surface_container_lowest.default.hex}}"
    readonly property color m3surfaceContainerLow: "{{colors.surface_container_low.default.hex}}"
    readonly property color m3surfaceContainer: "{{colors.surface_container.default.hex}}"
    readonly property color m3surfaceContainerHigh: "{{colors.surface_container_high.default.hex}}"
    readonly property color m3surfaceContainerHighest: "{{colors.surface_container_highest.default.hex}}"
    readonly property color m3onSurface: "{{colors.on_surface.default.hex}}"
    readonly property color m3onSurfaceVariant: "{{colors.on_surface_variant.default.hex}}"
    readonly property color m3outline: "{{colors.outline.default.hex}}"
    readonly property color m3outlineVariant: "{{colors.outline_variant.default.hex}}"
    readonly property color m3primary: "{{colors.primary.default.hex}}"
    readonly property color m3onPrimary: "{{colors.on_primary.default.hex}}"
    readonly property color m3primaryContainer: "{{colors.primary_container.default.hex}}"
    readonly property color m3onPrimaryContainer: "{{colors.on_primary_container.default.hex}}"
    readonly property color m3secondary: "{{colors.secondary.default.hex}}"
    readonly property color m3onSecondary: "{{colors.on_secondary.default.hex}}"
    readonly property color m3secondaryContainer: "{{colors.secondary_container.default.hex}}"
    readonly property color m3onSecondaryContainer: "{{colors.on_secondary_container.default.hex}}"
    readonly property color m3tertiary: "{{colors.tertiary.default.hex}}"
    readonly property color m3onTertiary: "{{colors.on_tertiary.default.hex}}"
    readonly property color m3tertiaryContainer: "{{colors.tertiary_container.default.hex}}"
    readonly property color m3onTertiaryContainer: "{{colors.on_tertiary_container.default.hex}}"
    readonly property color m3error: "{{colors.error.default.hex}}"
    readonly property color m3onError: "{{colors.on_error.default.hex}}"
    readonly property color m3errorContainer: "{{colors.error_container.default.hex}}"
    readonly property color m3onErrorContainer: "{{colors.on_error_container.default.hex}}"
    readonly property color m3inverseSurface: "{{colors.inverse_surface.default.hex}}"
    readonly property color m3inverseOnSurface: "{{colors.inverse_on_surface.default.hex}}"
    readonly property color m3shadow: "{{colors.shadow.default.hex}}"
    readonly property color m3scrim: "{{colors.scrim.default.hex}}"
}
