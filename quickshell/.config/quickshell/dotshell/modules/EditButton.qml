// Boton redondo de los modos edicion (Fase 11 B4, compartido desde B6): el
// lapiz, el tamano y la cruz de las zonas de Inicio (HomeZones) y de los
// ajustes rapidos del centro de control (TileGrid).
import QtQuick
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: eb
    property string icon
    signal clicked()
    implicitWidth: Tokens.control.sm
    implicitHeight: Tokens.control.sm
    radius: width / 2
    color: Colors.surfaceHigh
    StateLayer { hovered: ebMouse.containsMouse; pressed: ebMouse.pressed }
    Icon { anchors.centerIn: parent; name: eb.icon; size: Tokens.icon.sm; color: Colors.text }
    MouseArea {
        id: ebMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: eb.clicked()
    }
}
