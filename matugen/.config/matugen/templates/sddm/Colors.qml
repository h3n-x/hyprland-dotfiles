// Generado por matugen -- no editar a mano, editar templates/sddm/Colors.qml
// Paleta del greeter de SDDM (Fase 9 B3): la misma SemanticPalette que la
// shell y el bloqueo (Colors.qml de dotshell), con los roles fijados por
// matugen; el greeter no corre Quickshell ni lee el home. La imagen es el
// wallpaper que copia sddm-theme-stage junto al tema.
pragma Singleton
import QtQuick

SemanticPalette {
    readonly property string image: Qt.resolvedUrl("backgrounds/wall.png").toString().replace("file://", "")
    mode: "{{theme.mode}}"
    m3surface: "{{colors.surface.default.hex}}"
    m3surfaceContainerLowest: "{{colors.surface_container_lowest.default.hex}}"
    m3surfaceContainerLow: "{{colors.surface_container_low.default.hex}}"
    m3surfaceContainer: "{{colors.surface_container.default.hex}}"
    m3surfaceContainerHigh: "{{colors.surface_container_high.default.hex}}"
    m3surfaceContainerHighest: "{{colors.surface_container_highest.default.hex}}"
    m3onSurface: "{{colors.on_surface.default.hex}}"
    m3onSurfaceVariant: "{{colors.on_surface_variant.default.hex}}"
    m3outline: "{{colors.outline.default.hex}}"
    m3outlineVariant: "{{colors.outline_variant.default.hex}}"
    m3primary: "{{colors.primary.default.hex}}"
    m3onPrimary: "{{colors.on_primary.default.hex}}"
    m3primaryContainer: "{{colors.primary_container.default.hex}}"
    m3onPrimaryContainer: "{{colors.on_primary_container.default.hex}}"
    m3secondary: "{{colors.secondary.default.hex}}"
    m3onSecondary: "{{colors.on_secondary.default.hex}}"
    m3secondaryContainer: "{{colors.secondary_container.default.hex}}"
    m3onSecondaryContainer: "{{colors.on_secondary_container.default.hex}}"
    m3tertiary: "{{colors.tertiary.default.hex}}"
    m3onTertiary: "{{colors.on_tertiary.default.hex}}"
    m3tertiaryContainer: "{{colors.tertiary_container.default.hex}}"
    m3onTertiaryContainer: "{{colors.on_tertiary_container.default.hex}}"
    m3shadow: "{{colors.shadow.default.hex}}"
    m3scrim: "{{colors.scrim.default.hex}}"
    statusError: "{{status.error.default.hex}}"
    statusOnError: "{{status.on_error.default.hex}}"
    statusErrorContainer: "{{status.error_container.default.hex}}"
    statusOnErrorContainer: "{{status.on_error_container.default.hex}}"
    statusWarning: "{{status.warning.default.hex}}"
    statusOnWarning: "{{status.on_warning.default.hex}}"
    statusWarningContainer: "{{status.warning_container.default.hex}}"
    statusOnWarningContainer: "{{status.on_warning_container.default.hex}}"
    statusSuccess: "{{status.success.default.hex}}"
    statusOnSuccess: "{{status.on_success.default.hex}}"
    statusSuccessContainer: "{{status.success_container.default.hex}}"
    statusOnSuccessContainer: "{{status.on_success_container.default.hex}}"
}
