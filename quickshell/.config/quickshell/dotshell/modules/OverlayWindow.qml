// Ventana de los paneles de pantalla completa (Fase 4 B0, decision E1):
// launcher y, despues, energia, portapapeles, emoji y selector de ventanas.
// Sacada de Launcher.qml sin cambios de comportamiento.
//
// PanelWindow (no FloatingWindow) a proposito: FloatingWindow es una ventana
// de verdad manejada por Hyprland (necesitaria una window_rule para
// centrarla), PanelWindow es layer-shell y cubre la pantalla sin tocar
// rules.lua. Namespace quickshell-panel: blur del compositor detras de la
// tarjeta (el resto es transparente, ignore_alpha lo excluye).
//
// Una instancia por pantalla (Variants); solo se muestra la de targetScreen,
// el monitor enfocado al abrir (decision E12, KI-S5). Presence mantiene la
// ventana mapeada mientras el contenido anima la salida. Un clic en el fondo
// (afuera del contenido) o perder el foco emiten dismissed().
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".." // Tokens.qml

PanelWindow {
    id: window

    // Abierto (estado global del panel) y monitor donde se abre ("" = todos).
    property bool open: false
    property string targetScreen: ""
    property int enterDuration: Tokens.motion.long
    property bool slide: false
    // Para que el contenido anime (opacity: presence.progress, scale...).
    property alias presence: presence

    signal dismissed()

    readonly property bool onThisScreen: window.targetScreen === "" || (!!window.screen && window.screen.name === window.targetScreen)
    readonly property bool shouldShow: window.open && window.onThisScreen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-panel"
    // Superficie invocada (Fase 8 B6): capa Overlay, por encima de una ventana en
    // pantalla completa (ver FullscreenState).
    WlrLayershell.layer: WlrLayer.Overlay

    Presence { id: presence; open: window.shouldShow; enterDuration: window.enterDuration; slide: window.slide }
    visible: presence.shown

    HyprlandFocusGrab {
        windows: [window]
        active: window.visible
        onCleared: window.dismissed()
    }

    // Clic en el fondo transparente (afuera del contenido): z:-1 para no tapar
    // los clics del contenido, que se dibuja despues.
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: window.dismissed()
    }
}
