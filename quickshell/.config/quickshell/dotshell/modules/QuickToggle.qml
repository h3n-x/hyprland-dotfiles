// Boton cuadrado para el grid de accesos rapidos del Control Center
// (wifi/bluetooth/hyprsunset/lock) -- mismo rol que "buttons-grid" en
// swaync/config.json.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml

Rectangle {
    id: root
    property string icon: ""
    property bool active: false
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 44
    radius: 12
    color: root.active ? Colors.accent : Colors.bg2

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? Colors.bg0 : Colors.fg
        font.pixelSize: 18
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
