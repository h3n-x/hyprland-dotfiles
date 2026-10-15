// Progreso del reproductor (Fase 12 B2; de MediaHero, P4 B7): barra con
// busqueda y los tiempos; en el medio, hint (por que un control esta
// atenuado) o que no hay busqueda. Sin duracion, una leyenda en lugar de la
// barra. thin = solo la linea, sin tirador ni tiempos (tarjeta de Inicio).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, MediaColors.qml

ColumnLayout {
    id: root
    property MediaSession session
    property bool thin: false
    property string hint: ""
    readonly property var player: root.session ? root.session.player : null
    readonly property bool hasLength: !!root.session && root.session.hasLength
    readonly property bool canSeek: !root.thin && !!root.session && root.session.canSeek
    spacing: 0

    Item {
        id: track
        visible: root.hasLength
        Layout.fillWidth: true
        implicitHeight: root.thin ? 4 : Tokens.px(16)
        readonly property real frac: seekMouse.pressed ? track.dragPos
            : (root.hasLength ? root.session.barPos / root.player.length : 0)
        property real dragPos: 0
        readonly property int lineH: root.thin ? 3 : 4

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: track.lineH
            radius: height / 2
            color: Colors.tint(Colors.textMuted, Tokens.tint.track)
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * Math.max(0, Math.min(1, track.frac))
            height: track.lineH
            radius: height / 2
            // El acento de la portada (B4; sin uno valido, el de siempre).
            color: MediaColors.accent
            Behavior on color { ColorAnimation { duration: Tokens.motion.medium } }
        }
        Rectangle {
            visible: root.canSeek
            x: parent.width * Math.max(0, Math.min(1, track.frac)) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: seekMouse.pressed ? Tokens.px(18) : (seekMouse.containsMouse ? Tokens.px(16) : Tokens.px(14))
            height: width
            radius: width / 2
            color: MediaColors.accent
            Behavior on width { NumberAnimation { duration: Tokens.motion.fast } }
            Behavior on color { ColorAnimation { duration: Tokens.motion.medium } }
        }
        MouseArea {
            id: seekMouse
            objectName: "mediaSeek"
            anchors.fill: parent
            anchors.topMargin: -Tokens.space.xs
            anchors.bottomMargin: -Tokens.space.xs
            enabled: root.canSeek
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressedChanged: root.session.dragging = seekMouse.pressed
            onPressed: (mouse) => track.dragPos = Math.max(0, Math.min(1, mouse.x / width))
            onPositionChanged: (mouse) => {
                if (seekMouse.pressed) track.dragPos = Math.max(0, Math.min(1, mouse.x / width));
            }
            onReleased: root.session.seek(track.dragPos * root.player.length)
        }
    }
    // Tiempos; en el medio, por que un control esta atenuado o que no hay busqueda.
    RowLayout {
        visible: root.hasLength && !root.thin
        Layout.fillWidth: true
        Text {
            text: root.session ? root.session.fmt(track.frac * (root.player ? root.player.length : 0)) : ""
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
            font.features: Tokens.tabularNumbers
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.hint || (root.canSeek ? "" : I18n.tr("no seeking"))
            color: root.hint ? Colors.textMuted : Colors.border
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
            elide: Text.ElideRight
        }
        Text {
            text: root.session ? root.session.fmt(root.player ? root.player.length : 0) : ""
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
            font.features: Tokens.tabularNumbers
        }
    }
    RowLayout {
        visible: !!root.player && !root.hasLength && !root.thin
        Layout.fillWidth: true
        spacing: Tokens.space.xs
        Icon {
            name: "sensors"
            size: Tokens.icon.sm
            color: Colors.textMuted
        }
        Text {
            Layout.fillWidth: true
            text: root.hint || I18n.tr("No duration · the player doesn't report progress")
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
            elide: Text.ElideRight
        }
    }
}
