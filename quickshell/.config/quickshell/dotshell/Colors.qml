// Colores de la shell (ColorStore, Fase 3 B1; capa semantica, Fase 8 B2).
// Archivo fuente, no generado.
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
// Este singleton ES una SemanticPalette (P8.7): aca solo se alimentan sus roles
// de entrada (m3* y status*); los modulos usan sus alias (Colors.accent,
// Colors.warning, Colors.textMuted...), nunca los roles crudos (palette check,
// PC-Q2). Los colores de estado salen siempre del JSON aplicado, tambien durante
// la vista previa: no dependen del wallpaper ni del esquema (principio 23).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

SemanticPalette {
    id: root

    // Relee el JSON a mano (IPC `colors reload` de shell.qml).
    function reload(): void {
        file.reload();
    }

    // true tras la primera lectura: recien ahi se habilitan las animaciones.
    property bool ready: false

    property FileView paletteFile: FileView {
        id: file
        // QS_COLORS_JSON: otra paleta para pruebas (segunda instancia de la shell).
        path: Quickshell.env("QS_COLORS_JSON") || (Quickshell.env("HOME") + "/.cache/matugen/quickshell-colors.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: Qt.callLater(() => root.ready = true)
        // Sin JSON todavia (matugen nunca corrio con esta plantilla).
        printErrors: false

        // Paleta de respaldo: roles del wallpaper activo al escribir este archivo
        // y colores de estado fijos (oscuro: `palette status --mode dark`).
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
            property string error: "#ffb8af"
            property string on_error: "#4b0002"
            property string error_container: "#ff5449"
            property string on_error_container: "#000000"
            property string shadow: "#000000"
            property string scrim: "#000000"
            property string warning: "#ffd481"
            property string on_warning: "#3d2a00"
            property string warning_container: "#f0b429"
            property string on_warning_container: "#1f1400"
            property string success: "#7ddda1"
            property string on_success: "#002713"
            property string success_container: "#41a26c"
            property string on_success_container: "#000000"
            // Condiciones con las que se genero (tema oscuro hasta P5.5).
            property string mode: "dark"
            property real contrast: 0
            // Wallpaper de esta paleta (el que matugen acaba de usar). Lo lee
            // Wallpaper.qml (Fase 3 B6): wallpaper y colores cambian juntos.
            property string image: ""
        }
    }

    readonly property string image: json.image
    readonly property string mode: json.mode
    readonly property real contrast: json.contrast

    // Vista previa (Fase 3 B7): mientras hay un candidato, sus colores (de la
    // cache de la galeria) en vez de los del JSON. El JSON se sigue leyendo.
    readonly property var pv: ThemePreview.candidate

    // Alto contraste (accessibility.highContrast): lo aplica SemanticPalette.
    highContrast: SettingsState.value("accessibility.highContrast") === true

    // Opacidad de las superficies translucidas (Tokens.opacity.surface): la
    // transparencia elegida, nunca por debajo de surfaceFloor; opaca con alto
    // contraste. Vive aca porque Tokens es QtQuick puro (lo comparte el greeter).
    property Binding surfaceOpacity: Binding {
        target: Tokens.opacity
        property: "surface"
        value: {
            if (SettingsState.value("accessibility.highContrast") === true) return 1;
            const t = SettingsState.value("appearance.transparency");
            return Math.max(Tokens.opacity.surfaceFloor, t === "off" ? 1 : t === "reduced" ? 0.97 : 0.92);
        }
    }

    // Cambio de paleta animado (guia de transiciones 3.6.1: dur.theme, ease.standard);
    // instantaneo con movimiento reducido y en la primera carga.
    // Durante la vista previa (pasos y vuelta) dur.medium (decision B7c).
    component ColorFade: ColorAnimation {
        duration: ThemePreview.fast ? Tokens.motion.medium : Tokens.motion.theme
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.motion.easeStandard
    }

    m3surface: root.pv ? root.pv.surface : json.surface
    Behavior on m3surface { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3surfaceContainerLowest: root.pv ? root.pv.surface_container_lowest : json.surface_container_lowest
    Behavior on m3surfaceContainerLowest { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3surfaceContainerLow: root.pv ? root.pv.surface_container_low : json.surface_container_low
    Behavior on m3surfaceContainerLow { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3surfaceContainer: root.pv ? root.pv.surface_container : json.surface_container
    Behavior on m3surfaceContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3surfaceContainerHigh: root.pv ? root.pv.surface_container_high : json.surface_container_high
    Behavior on m3surfaceContainerHigh { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3surfaceContainerHighest: root.pv ? root.pv.surface_container_highest : json.surface_container_highest
    Behavior on m3surfaceContainerHighest { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3onSurface: root.pv ? root.pv.on_surface : json.on_surface
    Behavior on m3onSurface { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3onSurfaceVariant: root.pv ? root.pv.on_surface_variant : json.on_surface_variant
    Behavior on m3onSurfaceVariant { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3outline: root.pv ? root.pv.outline : json.outline
    Behavior on m3outline { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3outlineVariant: root.pv ? root.pv.outline_variant : json.outline_variant
    Behavior on m3outlineVariant { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3primary: root.pv ? root.pv.primary : json.primary
    Behavior on m3primary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3onPrimary: root.pv ? root.pv.on_primary : json.on_primary
    Behavior on m3onPrimary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3primaryContainer: root.pv ? root.pv.primary_container : json.primary_container
    Behavior on m3primaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3onPrimaryContainer: root.pv ? root.pv.on_primary_container : json.on_primary_container
    Behavior on m3onPrimaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3secondary: root.pv ? root.pv.secondary : json.secondary
    Behavior on m3secondary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3onSecondary: root.pv ? root.pv.on_secondary : json.on_secondary
    Behavior on m3onSecondary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3secondaryContainer: root.pv ? root.pv.secondary_container : json.secondary_container
    Behavior on m3secondaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3onSecondaryContainer: root.pv ? root.pv.on_secondary_container : json.on_secondary_container
    Behavior on m3onSecondaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3tertiary: root.pv ? root.pv.tertiary : json.tertiary
    Behavior on m3tertiary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3onTertiary: root.pv ? root.pv.on_tertiary : json.on_tertiary
    Behavior on m3onTertiary { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3tertiaryContainer: root.pv ? root.pv.tertiary_container : json.tertiary_container
    Behavior on m3tertiaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3onTertiaryContainer: root.pv ? root.pv.on_tertiary_container : json.on_tertiary_container
    Behavior on m3onTertiaryContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3shadow: root.pv ? root.pv.shadow : json.shadow
    Behavior on m3shadow { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    m3scrim: root.pv ? root.pv.scrim : json.scrim
    Behavior on m3scrim { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusError: json.error
    Behavior on statusError { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusOnError: json.on_error
    Behavior on statusOnError { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusErrorContainer: json.error_container
    Behavior on statusErrorContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusOnErrorContainer: json.on_error_container
    Behavior on statusOnErrorContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusWarning: json.warning
    Behavior on statusWarning { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusOnWarning: json.on_warning
    Behavior on statusOnWarning { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusWarningContainer: json.warning_container
    Behavior on statusWarningContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusOnWarningContainer: json.on_warning_container
    Behavior on statusOnWarningContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusSuccess: json.success
    Behavior on statusSuccess { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusOnSuccess: json.on_success
    Behavior on statusOnSuccess { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusSuccessContainer: json.success_container
    Behavior on statusSuccessContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
    statusOnSuccessContainer: json.on_success_container
    Behavior on statusOnSuccessContainer { enabled: root.ready && Tokens.motion.scale > 0; ColorFade {} }
}
