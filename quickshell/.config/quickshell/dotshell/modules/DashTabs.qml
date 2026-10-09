// Barra de pestanas del dashboard (Fase 12 B2, D-B2-2): icono + nombre por
// pestana y una linea de acento bajo la actual que se desliza al cambiar
// (motion.medium; nada se mueve si no cambia). Angosta: solo iconos, con el
// nombre de la actual. A la derecha, de que es la pestana (detail).
// Rueda sobre la barra: la anterior / la siguiente.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, DashboardState.qml

Item {
    id: root
    property var tabs: []
    property string current: ""
    property bool compact: false
    property string detail: ""
    // El panel se ve: sin esto la linea no anima al abrir.
    property bool live: false
    signal picked(string id)
    signal stepped(int delta)

    implicitHeight: Tokens.control.md + 2 + Tokens.space.xs

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Tokens.control.md
        spacing: Tokens.space.xs

        Repeater {
            id: rep
            model: root.tabs
            Rectangle {
                id: tabItem
                required property string modelData
                required property int index
                readonly property bool on: tabItem.modelData === root.current
                readonly property var meta: DashboardState.meta[tabItem.modelData] || ({ label: tabItem.modelData, icon: "tab" })
                readonly property bool showLabel: !root.compact || tabItem.on
                objectName: "tab-" + tabItem.modelData
                implicitWidth: tabRow.implicitWidth + 2 * Tokens.space.md
                implicitHeight: Tokens.control.md
                radius: Tokens.radius.md
                color: "transparent"
                StateLayer {
                    hovered: tabMouse.containsMouse
                    pressed: tabMouse.pressed
                    contentColor: tabItem.on ? Colors.accent : Colors.text
                }
                Row {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: Tokens.space.xs
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: tabItem.meta.icon
                        filled: tabItem.on
                        size: Tokens.icon.md
                        color: tabItem.on ? Colors.accent : Colors.textMuted
                    }
                    Text {
                        visible: tabItem.showLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: tabItem.meta.label
                        color: tabItem.on ? Colors.accent : Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        font.weight: tabItem.on ? Tokens.weight.semibold : Tokens.weight.medium
                    }
                }
                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(tabItem.modelData)
                }
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.space.sm
            horizontalAlignment: Text.AlignRight
            text: root.detail
            color: Colors.border
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
            elide: Text.ElideRight
        }
    }

    // La linea bajo la pestana actual.
    readonly property Item currentItem: {
        const i = root.tabs.indexOf(root.current);
        return i >= 0 && rep.count > i ? rep.itemAt(i) : null;
    }
    Rectangle {
        id: indicator
        objectName: "tabIndicator"
        visible: !!root.currentItem
        y: row.height + Tokens.space.xs
        x: root.currentItem ? root.currentItem.x + Tokens.space.md : 0
        width: root.currentItem ? root.currentItem.width - 2 * Tokens.space.md : 0
        height: 2
        radius: 1
        color: Colors.accent
        Behavior on x { enabled: root.live && Tokens.motion.scale > 0; NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
        Behavior on width { enabled: root.live && Tokens.motion.scale > 0; NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        y: indicator.y + 1
        height: 1
        color: Colors.divider
        z: -1
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        orientation: Qt.Vertical
        property real acc: 0
        onWheel: (event) => {
            acc += event.angleDelta.y;
            if (Math.abs(acc) >= 120) {
                root.stepped(acc < 0 ? 1 : -1);
                acc = 0;
            }
        }
    }
}
