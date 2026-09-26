// Vista previa de una ventana (Fase 4 B4; compartida en B7): una captura al
// crearse (ScreencopyView, sin quedar en vivo) y, sin captura, el icono de la
// aplicacion. La usan el selector de ventanas y las miniaturas de la vista
// Escritorios; se liberan al cerrarse lo que las contiene.
//
// Solo se capturan ventanas de al menos 24x24 (capturable, DesktopState): una
// captura de 0x0 tira la conexion Wayland de la shell entera (KI-L18).
import QtQuick
import Quickshell.Wayland
import Quickshell.Widgets
import ".." // DesktopState.qml, AppInfo.qml

Item {
    id: preview
    required property string address
    property string cls: ""
    property bool capturable: true
    // false: sin captura (solo el icono), p. ej. mientras no se muestra.
    property bool capture: true
    // Tamano maximo de la captura (pixeles logicos).
    property size constraintSize: Qt.size(preview.width, preview.height)
    property int iconSize: 32
    readonly property bool hasContent: shot.hasContent

    readonly property var toplevel: DesktopState.toplevelOf(preview.address)

    ScreencopyView {
        id: shot
        anchors.fill: parent
        // Solo con tamano real (nunca una captura de 0x0).
        captureSource: preview.capture && preview.capturable && preview.width > 0 && preview.height > 0 && preview.toplevel ? preview.toplevel.wayland : null
        live: false
        constraintSize: preview.constraintSize
    }
    IconImage {
        visible: !shot.hasContent
        anchors.centerIn: parent
        implicitSize: preview.iconSize
        source: AppInfo.icon(preview.cls)
    }
}
