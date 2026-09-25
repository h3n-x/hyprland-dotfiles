// Circulo accent independiente (no dentro de un Pill): se destaca solo,
// separado del resto de los modulos.
//
// Reusa hypr/scripts/power-menu.sh (rofi, ya bindeado a SUPER+M en
// binds.lua, con confirmacion antes de reiniciar/apagar) en vez del script
// propio de waybar (fzf, sin confirmacion) -- se saco al cortar con
// Waybar del todo, ver Fase 4 del plan. rofi dibuja su propia ventana, no
// hace falta abrir una terminal como con el script viejo.
import QtQuick
import Quickshell
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root
    // Mismo alto que los Pill (D14), circular.
    implicitWidth: Tokens.pill.height
    implicitHeight: Tokens.pill.height
    radius: Tokens.radius.pill(height)
    color: Colors.m3surfaceContainerLow

    StateLayer {
        hovered: mouseArea.containsMouse
        pressed: mouseArea.pressed
        contentColor: Colors.m3primary
    }

    Icon {
        id: label
        anchors.centerIn: parent
        name: "power_settings_new"
        color: Colors.m3primary
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/power-menu.sh"])
    }
}
