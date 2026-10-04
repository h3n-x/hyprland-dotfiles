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
    // Oculto desde el centro de configuracion (bar.show.idle, Fase 10 B4).
    // Si se muestra, segun su propio estado y la opcion bar.show.* (Fase 10 B4).
    // La barra lee shown, no visible: visible depende del padre y una pill
    // oculta nunca volveria a mostrarse.
    readonly property bool shown: SettingsState.value("bar.show.idle") !== false
    visible: shown
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
        color: root.active ? Colors.accent : Colors.text
    }

    // Hover por control (P2.4, Q2 = A).
    HoverHalo { hovered: hoverArea.containsMouse; pressed: hoverArea.pressed }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.active = !root.active
    }
}
