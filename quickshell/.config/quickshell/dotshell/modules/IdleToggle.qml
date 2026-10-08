// Reemplaza a waybar/modules/idle_inhibitor.jsonc: "mantener despierto" en
// la barra. El estado es uno solo (IdleState, Fase 11 B6), el mismo que el
// ajuste rapido del centro de control y el de las otras pantallas.
import QtQuick
import ".." // Colors.qml, IdleState.qml

Item {
    id: root
    // Si se muestra, segun su propio estado (que este en la barra lo decide bar.layout, Fase 11 B1).
    // La barra lee shown, no visible: visible depende del padre y una pill
    // oculta nunca volveria a mostrarse.
    readonly property bool shown: true
    visible: shown
    required property var panelWindow
    readonly property bool active: IdleState.active

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

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
        onClicked: IdleState.toggle()
    }
}
