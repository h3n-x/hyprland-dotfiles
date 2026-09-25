// Reemplaza a waybar/modules/idle_inhibitor.jsonc. Nombrado "IdleToggle" y no
// "IdleInhibitor" a proposito -- Quickshell.Wayland ya expone un tipo
// IdleInhibitor, y un archivo con el mismo nombre en este directorio
// colisionaria con ese import (quedaria referenciandose a si mismo en vez
// del tipo real).
import QtQuick
import Quickshell.Wayland
import ".." // Colors.qml

Item {
    id: root
    required property var panelWindow
    property bool active: false

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    IdleInhibitor {
        window: root.active ? root.panelWindow : null
        enabled: root.active
    }

    Icon {
        id: label
        name: root.active ? "visibility" : "visibility_off"
        filled: root.active
        color: root.active ? Colors.m3primary : Colors.m3onSurface
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.active = !root.active
    }
}
