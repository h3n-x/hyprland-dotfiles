// Boton cuadrado para el grid de accesos rapidos del Control Center
// (wifi/bluetooth/hyprsunset/lock) -- mismo rol que "buttons-grid" en
// swaync/config.json. icon = nombre de ligadura de Material Symbols.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root
    property string icon: ""
    property bool active: false
    signal clicked()

    // Toggle activo en primary_container, inactivo en el contenedor mas alto
    // (decision C3); icono relleno = activo (I4).
    readonly property color contentColor: root.active ? Colors.textOnAccentContainer : Colors.text

    Layout.fillWidth: true
    implicitHeight: Tokens.row.heightLarge
    radius: Tokens.radius.md
    color: root.active ? Colors.accentContainer : Colors.surfaceHighest
    // Cambio de estado animado (guia 3.6.1).
    Behavior on color { ColorAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }

    StateLayer {
        hovered: mouse.containsMouse
        pressed: mouse.pressed
        contentColor: root.contentColor
    }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        filled: root.active
        color: root.contentColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
