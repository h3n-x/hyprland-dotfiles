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

    Text {
        id: label
        color: root.active ? Colors.accent : Colors.fg
        font.pixelSize: 13
        text: root.active ? "󰈈" : "󰈉"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.active = !root.active
    }
}
