// Avisos en la barra (Fase 11 B2): campana (o en pausa con No molestar) y
// cuantos hay en el historial, como punto o numero
// (bar.notifications.count). Clic: el centro de control (donde estan).
import QtQuick
import ".." // Colors.qml, Tokens.qml, NotificationState.qml, ControlCenterState.qml

Item {
    id: root
    readonly property int count: NotificationState.count
    readonly property bool asNumber: SettingsState.value("bar.notifications.count") === "number"
    readonly property bool shown: true
    // Texto de la informacion al pasar el raton (bar.tooltips, Fase 11 B2b).
    readonly property string tooltip: NotificationState.doNotDisturb ? "No molestar" : root.count === 0 ? "Sin avisos" : root.count === 1 ? "1 aviso" : root.count + " avisos"
    visible: shown

    implicitWidth: bell.implicitWidth + (badge.visible && root.asNumber ? badge.width - Tokens.space.xs : 0)
    implicitHeight: bell.implicitHeight

    Icon {
        id: bell
        name: NotificationState.doNotDisturb ? "notifications_paused" : "notifications"
        filled: root.count > 0 && !NotificationState.doNotDisturb
    }
    Rectangle {
        id: badge
        visible: root.count > 0 && !NotificationState.doNotDisturb
        x: bell.width - width / 2 - (root.asNumber ? 0 : 2)
        y: root.asNumber ? -2 : 1
        width: root.asNumber ? Math.max(height, num.implicitWidth + 6) : 7
        height: root.asNumber ? Tokens.px(14) : Tokens.px(7)
        radius: height / 2
        // Neutro: "hay avisos" es un estado, no identidad (principio 23).
        color: Colors.text
        Text {
            id: num
            visible: root.asNumber
            anchors.centerIn: parent
            text: root.count > 99 ? "99+" : String(root.count)
            color: Colors.surfaceLowest
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
            font.weight: Tokens.weight.semibold
        }
    }

    HoverHalo { hovered: hoverArea.containsMouse; pressed: hoverArea.pressed }
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ControlCenterState.visible = !ControlCenterState.visible
    }
}
