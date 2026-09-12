// Reemplaza a clock#date + clock#time de waybar, pero como un solo modulo
// que alterna entre hora y fecha al click (en vez de mostrar las dos juntas
// todo el tiempo). SystemClock evita el Process+Timer de "date" cada 1s.
import QtQuick
import Quickshell
import ".." // Colors.qml

Item {
    id: root
    property bool showDate: false

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: label
        color: Colors.fg
        font.pixelSize: 13
        font.weight: root.showDate ? Font.Normal : Font.DemiBold
        text: root.showDate
            ? Qt.formatDate(clock.date, "ddd d MMM")
            : Qt.formatTime(clock.date, "hh:mm")
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.showDate = !root.showDate
    }
}
