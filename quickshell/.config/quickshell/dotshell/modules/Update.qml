// Pill de actualizaciones: icono del ultimo chequeo (UpdateState, compartido
// con el aviso del dashboard). Clic: update interactivo en una terminal;
// clic derecho: chequear ya.
import QtQuick
import Quickshell
import ".." // Colors.qml, Tokens.qml, UpdateState.qml

Item {
    id: root

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Icon {
        id: label
        name: UpdateState.icon
        filled: UpdateState.icon === "download"
    }

    // Hover por control (P2.4, Q2 = A).
    HoverHalo { hovered: hoverArea.containsMouse; pressed: hoverArea.pressed }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) UpdateState.check();
            else UpdateState.run();
        }
    }
}
