// Generado por matugen -- no editar a mano, editar templates/quickshell-colors.qml.
// Roles Material 3 con prefijo m3 (m3surface, m3onSurface...) que usan los
// modulos de la shell. Los alias anteriores (accent/fg/bg0..3/br/warning/
// critical/charging/hoverBg/hoverFg) se quitaron al terminar la migracion
// (P1.10, decision P4). Mapa de roles en DESIGN_TOKENS.md.
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
    // ---- Roles Material 3 (decision C1, P1.9) -----------------------------
    // Nombre oficial de M3 en camelCase con prefijo "m3": QML no admite una
    // propiedad onX junto a una propiedad X en el mismo objeto (toma onX como
    // el handler de X -- "Cannot assign a value to a signal"), y M3 siempre
    // tiene los dos (surface/onSurface, primary/onPrimary...).
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
