// Circulo accent independiente (no dentro de un Pill): se destaca solo,
// separado del resto de los modulos.
//
// Abre el menu de energia y sesion de la shell (PowerMenu.qml, Fase 4 B1),
// el mismo de SUPER+M.
import QtQuick
import Quickshell
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root
    // Mismo alto que los Pill (D14), circular.
    implicitWidth: Tokens.pill.height
    implicitHeight: Tokens.pill.height
    radius: Tokens.radius.pill(height)
    // Como las pildoras: fondo propio solo en el estilo flotante (bar.style, Fase 11 B3b).
    color: Tokens.bar.style === "floating" ? Colors.surfaceLow : "transparent"

    StateLayer {
        hovered: mouseArea.containsMouse
        pressed: mouseArea.pressed
        contentColor: Colors.accent
    }

    Icon {
        id: label
        anchors.centerIn: parent
        name: "power_settings_new"
        color: Colors.accent
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: PowerState.open()
    }
}
