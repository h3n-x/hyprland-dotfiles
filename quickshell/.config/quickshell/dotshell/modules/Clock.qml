// Reemplaza a clock#date + clock#time de waybar, pero como un solo modulo
// que alterna entre hora y fecha al click (en vez de mostrar las dos juntas
// todo el tiempo). SystemClock evita el Process+Timer de "date" cada 1s.
import QtQuick
import Quickshell
import ".." // Colors.qml, Tokens.qml

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
        color: Colors.m3onSurface
        font.family: Tokens.font.ui
        // type.title (D2): el reloj recupera el enfasis con tamano, no con un
        // Bold accidental (antes Noto Sans no tenia SemiBold y caia a Bold).
        font.pixelSize: Tokens.type.title
        font.weight: root.showDate ? Tokens.weight.regular : Tokens.weight.semibold
        font.features: Tokens.tabularNumbers
        text: root.showDate
            ? Qt.formatDate(clock.date, "ddd d MMM")
            : Qt.formatTime(clock.date, "hh:mm")
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.showDate = !root.showDate
    }
}
