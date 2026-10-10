// Capa semantica de color (Fase 8 B2, P8.7): la UNICA traduccion de roles de
// paleta a significado. La usan la shell (Colors.qml la instancia) y, desde la
// Fase 9, la superficie de login compartida (bloqueo y SDDM): por eso es
// QtQuick plano, sin imports de Quickshell ni de Tokens.
//
// Principio 23: los colores adaptativos (identidad) aportan identidad visual;
// los semanticos (significado) comunican estado. Ningun color es ambas cosas:
//   identidad   accent*, accentAlt*, decor*   (siguen al wallpaper)
//   significado danger*, warning*, success*   (fijos: solo cambian con el modo
//               y el nivel de contraste; nunca con wallpaper, esquema ni acentos)
//   estructura  text*, border, divider, background, surface*, scrim, shadow
//               (neutros, no significan nada por su color)
//
// Entrada: los roles de la paleta (m3* de matugen, que siguen al wallpaper, y
// status* de `palette status`, fijos). Salida: los alias. Los modulos usan solo los alias; los
// m3* quedan para este archivo y Colors.qml (palette check, PC-Q2). El
// contenido sobre un relleno se llama textOnX (no onX: QML tomaria onX como
// el handler de X). `palette check` lee las lineas "alias: root.rol" de este
// archivo: mantener una declaracion por linea.
import QtQuick

QtObject {
    id: root

    // ---- Entrada: paleta (L1) ----------------------------------------------------------------
    // Modo de la paleta ("dark" | "light", P5.5): solo para los pocos alias que
    // dependen de el (veil). Lo fija quien instancia (Colors.qml, el greeter).
    property string mode: "dark"
    readonly property bool light: root.mode === "light"
    property color m3surface
    property color m3surfaceContainerLowest
    property color m3surfaceContainerLow
    property color m3surfaceContainer
    property color m3surfaceContainerHigh
    property color m3surfaceContainerHighest
    property color m3onSurface
    property color m3onSurfaceVariant
    property color m3outline
    property color m3outlineVariant
    property color m3primary
    property color m3onPrimary
    property color m3primaryContainer
    property color m3onPrimaryContainer
    property color m3secondary
    property color m3onSecondary
    property color m3secondaryContainer
    property color m3onSecondaryContainer
    property color m3tertiary
    property color m3onTertiary
    property color m3tertiaryContainer
    property color m3onTertiaryContainer
    property color m3shadow
    property color m3scrim
    // Colores de estado (P8.7 D1b/D3): `palette status`, semillas por
    // scheme-fidelity a contraste fijo. Solo cambian con el modo.
    property color statusError
    property color statusOnError
    property color statusErrorContainer
    property color statusOnErrorContainer
    property color statusWarning
    property color statusOnWarning
    property color statusWarningContainer
    property color statusOnWarningContainer
    property color statusSuccess
    property color statusOnSuccess
    property color statusSuccessContainer
    property color statusOnSuccessContainer

    // Accesibilidad (accessibility.highContrast): textos secundarios y lineas
    // con el contraste de los principales.
    property bool highContrast: false
    // Contenido deshabilitado (M3); el unico texto que se atenua con alfa.
    readonly property real disabledOpacity: 0.38

    // ---- Identidad (siguen al wallpaper; nunca significan un estado) -------------------------
    readonly property color accent: root.m3primary
    readonly property color textOnAccent: root.m3onPrimary
    readonly property color accentContainer: root.m3primaryContainer
    readonly property color textOnAccentContainer: root.m3onPrimaryContainer
    readonly property color accentAlt: root.m3secondary
    readonly property color textOnAccentAlt: root.m3onSecondary
    readonly property color accentAltContainer: root.m3secondaryContainer
    readonly property color textOnAccentAltContainer: root.m3onSecondaryContainer
    readonly property color decor: root.m3tertiary
    readonly property color textOnDecor: root.m3onTertiary
    readonly property color decorContainer: root.m3tertiaryContainer
    readonly property color textOnDecorContainer: root.m3onTertiaryContainer

    // ---- Significado (fijos; N1-N7 del plan P8-B2) -------------------------------------------
    readonly property color danger: root.statusError
    readonly property color textOnDanger: root.statusOnError
    readonly property color dangerContainer: root.statusErrorContainer
    readonly property color textOnDangerContainer: root.statusOnErrorContainer
    readonly property color warning: root.statusWarning
    readonly property color textOnWarning: root.statusOnWarning
    readonly property color warningContainer: root.statusWarningContainer
    readonly property color textOnWarningContainer: root.statusOnWarningContainer
    readonly property color success: root.statusSuccess
    readonly property color textOnSuccess: root.statusOnSuccess
    readonly property color successContainer: root.statusSuccessContainer
    readonly property color textOnSuccessContainer: root.statusOnSuccessContainer

    // ---- Estructura (neutros) ----------------------------------------------------------------
    readonly property color text: root.m3onSurface
    readonly property color textMuted: root.highContrast ? root.m3onSurface : root.m3onSurfaceVariant
    readonly property color textDisabled: Qt.alpha(root.m3onSurface, root.disabledOpacity)
    readonly property color border: root.m3outline
    readonly property color divider: root.highContrast ? root.m3outline : root.m3outlineVariant
    readonly property color background: root.m3surface
    readonly property color surfaceLowest: root.m3surfaceContainerLowest
    readonly property color surfaceLow: root.m3surfaceContainerLow
    readonly property color surface: root.m3surfaceContainer
    readonly property color surfaceHigh: root.m3surfaceContainerHigh
    readonly property color surfaceHighest: root.m3surfaceContainerHighest
    readonly property color scrim: root.m3scrim
    readonly property color shadow: root.m3shadow
    // Velo bajo texto dibujado sobre el wallpaper (bloqueo y greeter, P5.5): el
    // scrim oscurece para el texto claro del modo oscuro; en claro el texto es
    // oscuro y el velo aclara con la superficie.
    readonly property color veil: root.light ? root.m3surface : root.m3scrim

    // Transparencia de un alias con un valor de Tokens (tint, stateLayer,
    // opacity): la unica forma de aplicar alfa a un color fuera de este archivo.
    function tint(c: color, a: real): color {
        return Qt.alpha(c, a);
    }
}
