// Boton del lanzador en la barra (Fase 11 B2): clic = el lanzador (lo mismo
// que SUPER+D). Un acceso directo, no un hub.
import QtQuick
import ".." // Colors.qml, Tokens.qml, LauncherState.qml

Item {
    id: root
    readonly property bool shown: true
    visible: shown

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Icon { id: icon; name: "apps"; filled: true }

    HoverHalo { hovered: hoverArea.containsMouse; pressed: hoverArea.pressed }
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: LauncherState.toggle()
    }
}
