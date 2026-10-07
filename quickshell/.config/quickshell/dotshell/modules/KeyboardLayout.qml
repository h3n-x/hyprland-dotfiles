// Distribucion del teclado en la barra (Fase 11 B2; prometido en D-B3-6):
// el codigo de la activa (US, LATAM) y clic para pasar a la siguiente. Solo
// con dos o mas distribuciones (Configuracion -> Teclado y raton). Los datos
// son de KeyboardState (evento "activelayout", sin sondeo).
import QtQuick
import Quickshell
import ".." // Colors.qml, Tokens.qml, KeyboardState.qml

Item {
    id: root
    readonly property bool shown: KeyboardState.layouts.length > 1
    // Texto de la informacion al pasar el raton (bar.tooltips, Fase 11 B2b).
    readonly property string tooltip: KeyboardState.keymap + " (clic: la siguiente)"
    visible: shown

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: Tokens.space.xs
        Icon { anchors.verticalCenter: parent.verticalCenter; name: "keyboard"; size: Tokens.icon.sm }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: KeyboardState.code
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
            font.weight: Tokens.weight.medium
        }
    }

    HoverHalo { hovered: hoverArea.containsMouse; pressed: hoverArea.pressed }
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: KeyboardState.next()
    }
}
