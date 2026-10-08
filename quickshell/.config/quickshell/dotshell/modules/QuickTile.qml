// Un ajuste rapido del centro de control (Fase 4; tamanos desde la Fase 11
// B6). Pequeno: el cuadrado de siempre, solo el icono. Ancho: icono, nombre y
// su estado ("Wi-Fi · Casa"). Encendido en primary_container, apagado en el
// contenedor mas alto (decision C3); icono relleno = encendido (I4). El
// estado y la accion son de QuickTiles; aca solo se dibuja.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root
    property string icon: ""
    property bool active: false
    property bool wide: false
    property string label: ""
    property string status: ""
    signal clicked()

    readonly property color contentColor: root.active ? Colors.textOnAccentContainer : Colors.text

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
        visible: !root.wide
        anchors.centerIn: parent
        name: root.icon
        filled: root.active
        color: root.contentColor
    }
    RowLayout {
        visible: root.wide
        anchors.fill: parent
        anchors.leftMargin: Tokens.space.md
        anchors.rightMargin: Tokens.space.sm
        spacing: Tokens.space.sm
        Icon {
            name: root.icon
            filled: root.active
            color: root.contentColor
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.label
                color: root.contentColor
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.weight: Tokens.weight.semibold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.status
                color: root.active ? Colors.textOnAccentContainer : Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
