// Lista de opciones de un Select (Fase 10 B1; ver Select.qml): una fila por
// opcion, la elegida con fondo y check. Emite chosen(value) solo si cambia y
// closed() siempre, para que el consumidor cierre el Select.
import QtQuick
import ".." // Colors.qml, Tokens.qml

Column {
    id: root

    property var options: []
    property var current
    signal chosen(var value)
    signal closed

    Repeater {
        model: root.options
        Rectangle {
            id: opt
            required property var modelData
            readonly property bool sel: opt.modelData[0] === root.current
            width: parent.width
            height: Tokens.row.height - Tokens.space.xs
            radius: Tokens.radius.sm
            color: opt.sel ? Colors.accentAltContainer : "transparent"
            StateLayer { hovered: optMouse.containsMouse; pressed: optMouse.pressed }
            Row {
                anchors.left: parent.left
                anchors.leftMargin: Tokens.space.sm
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.space.xs
                Icon {
                    name: "check"
                    size: Tokens.icon.sm
                    opacity: opt.sel ? 1 : 0
                    color: Colors.textOnAccentAltContainer
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: opt.modelData[1]
                    color: opt.sel ? Colors.textOnAccentAltContainer : Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
            }
            MouseArea {
                id: optMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!opt.sel) root.chosen(opt.modelData[0]);
                    root.closed();
                }
            }
        }
    }
}
