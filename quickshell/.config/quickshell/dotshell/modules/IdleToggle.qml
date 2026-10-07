// Reemplaza a waybar/modules/idle_inhibitor.jsonc. Se llama "IdleToggle" y no
// "IdleInhibitor" para no tener el mismo nombre que el tipo de
// Quickshell.Wayland que usa adentro (mas claro al leer; KI-S4).
import QtQuick
import Quickshell.Wayland
import ".." // Colors.qml

Item {
    id: root
    // Si se muestra, segun su propio estado (que este en la barra lo decide bar.layout, Fase 11 B1).
    // La barra lee shown, no visible: visible depende del padre y una pill
    // oculta nunca volveria a mostrarse.
    readonly property bool shown: true
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
