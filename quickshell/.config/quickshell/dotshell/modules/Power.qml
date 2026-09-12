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
import ".." // Colors.qml

Rectangle {
    id: root
    implicitWidth: label.implicitWidth + 20
    implicitHeight: label.implicitHeight + 10
    radius: height / 2
    color: mouseArea.containsMouse ? Colors.hoverBg : Colors.bg1

    Text {
        id: label
        anchors.centerIn: parent
        text: "󰤄"
        color: Colors.accent
        font.pixelSize: 16
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/power-menu.sh"])
    }
}
