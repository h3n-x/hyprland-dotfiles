// Colores de la shell (ColorStore, Fase 3 B1). Archivo fuente, no generado.
//
// matugen escribe la paleta del wallpaper en ~/.cache/matugen/quickshell-colors.json
// (plantilla templates/quickshell-colors.json); aca se lee con un FileView que la
// relee sola cuando cambia, y cada color anima hacia el nuevo valor (dur.theme).
// No hay recarga de la shell al cambiar de wallpaper: los paneles abiertos siguen
// abiertos (KI-L8). Fuera del directorio de Quickshell a proposito, asi su propio
// vigilante de archivos no dispara recargas.
//
// Sin JSON, o con un JSON invalido, la shell usa la paleta de respaldo de abajo
// (valores por defecto del JsonAdapter) o el ultimo valor bueno (KI-C3). La primera
// carga no anima.
//
// Roles Material 3 con prefijo m3: QML no admite una propiedad onX junto a una
// propiedad X en el mismo objeto (toma onX como el handler de X), y M3 siempre
// tiene los dos (surface/onSurface, primary/onPrimary...). Mapa en DESIGN_TOKENS.md.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Relee el JSON a mano (IPC `colors reload` de shell.qml).
    function reload(): void {
        file.reload();
    }

    // true tras la primera lectura: recien ahi se habilitan las animaciones.
    property bool ready: false

    FileView {
        id: file
        // QS_COLORS_JSON: otra paleta para pruebas (segunda instancia de la shell).
        path: Quickshell.env("QS_COLORS_JSON") || (Quickshell.env("HOME") + "/.cache/matugen/quickshell-colors.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: Qt.callLater(() => root.ready = true)
        // Sin JSON todavia (matugen nunca corrio con esta plantilla).
        printErrors: false

        // Paleta de respaldo: la del wallpaper activo al escribir este archivo.
        JsonAdapter {
            id: json
            property string surface: "#0f1513"
            property string surface_container_lowest: "#090f0d"
            property string surface_container_low: "#171d1b"
            property string surface_container: "#1b211f"
            property string surface_container_high: "#252b29"
            property string surface_container_highest: "#303634"
            property string on_surface: "#dee4e0"
            property string on_surface_variant: "#bfc9c4"
            property string outline: "#89938e"
            property string outline_variant: "#3f4945"
            property string primary: "#86d6bf"
            property string on_primary: "#00382d"
            property string primary_container: "#005142"
            property string on_primary_container: "#a2f2da"
            property string secondary: "#b2ccc2"
            property string on_secondary: "#1d352e"
            property string secondary_container: "#344c44"
            property string on_secondary_container: "#cde9de"
            property string tertiary: "#a9cbe3"
            property string on_tertiary: "#0f3447"
            property string tertiary_container: "#294a5e"
            property string on_tertiary_container: "#c6e7ff"
            property string error: "#ffb4ab"
            property string on_error: "#690005"
            property string error_container: "#93000a"
            property string on_error_container: "#ffdad6"
            property string inverse_surface: "#dee4e0"
            property string inverse_on_surface: "#2b322f"
            property string shadow: "#000000"
            property string scrim: "#000000"
        }
    }

    // Cambio de paleta animado (guia de transiciones 3.6.1: dur.theme, ease.standard);
    // instantaneo con movimiento reducido y en la primera carga.
    component ColorFade: ColorAnimation {
        duration: Tokens.motion.theme
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.motion.easeStandard
    }

    property color m3surface: json.surface
    Behavior on m3surface { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3surfaceContainerLowest: json.surface_container_lowest
    Behavior on m3surfaceContainerLowest { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3surfaceContainerLow: json.surface_container_low
    Behavior on m3surfaceContainerLow { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3surfaceContainer: json.surface_container
    Behavior on m3surfaceContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3surfaceContainerHigh: json.surface_container_high
    Behavior on m3surfaceContainerHigh { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3surfaceContainerHighest: json.surface_container_highest
    Behavior on m3surfaceContainerHighest { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3onSurface: json.on_surface
    Behavior on m3onSurface { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3onSurfaceVariant: json.on_surface_variant
    Behavior on m3onSurfaceVariant { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3outline: json.outline
    Behavior on m3outline { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3outlineVariant: json.outline_variant
    Behavior on m3outlineVariant { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3primary: json.primary
    Behavior on m3primary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3onPrimary: json.on_primary
    Behavior on m3onPrimary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3primaryContainer: json.primary_container
    Behavior on m3primaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3onPrimaryContainer: json.on_primary_container
    Behavior on m3onPrimaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3secondary: json.secondary
    Behavior on m3secondary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3onSecondary: json.on_secondary
    Behavior on m3onSecondary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3secondaryContainer: json.secondary_container
    Behavior on m3secondaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3onSecondaryContainer: json.on_secondary_container
    Behavior on m3onSecondaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3tertiary: json.tertiary
    Behavior on m3tertiary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3onTertiary: json.on_tertiary
    Behavior on m3onTertiary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3tertiaryContainer: json.tertiary_container
    Behavior on m3tertiaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3onTertiaryContainer: json.on_tertiary_container
    Behavior on m3onTertiaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3error: json.error
    Behavior on m3error { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3onError: json.on_error
    Behavior on m3onError { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3errorContainer: json.error_container
    Behavior on m3errorContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3onErrorContainer: json.on_error_container
    Behavior on m3onErrorContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3inverseSurface: json.inverse_surface
    Behavior on m3inverseSurface { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3inverseOnSurface: json.inverse_on_surface
    Behavior on m3inverseOnSurface { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3shadow: json.shadow
    Behavior on m3shadow { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    property color m3scrim: json.scrim
    Behavior on m3scrim { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
}
