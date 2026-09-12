// Entrada de audio (antes parte de Audio.qml, separado para poder ordenarlo
// independiente de la salida en Bar.qml). Solo icono de mute/activo, igual
// alcance que "on-click": volume input mute de waybar. Dispara el OSD
// (Osd.qml/OsdState.qml) al mutear/desmutear, igual criterio que Volume.qml.
import QtQuick
import Quickshell.Services.Pipewire
import ".." // Colors.qml, OsdState.qml

Item {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
    }

    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool muted: !!(root.source && root.source.audio && root.source.audio.muted)
    visible: !!root.source

    property bool armed: false
    Component.onCompleted: Qt.callLater(() => root.armed = true)

    onMutedChanged: {
        if (!root.armed) return;
        OsdState.show(root.muted ? "󰍭" : "󰍬", root.muted ? 0 : 1, root.muted ? "Mic muted" : "Mic on");
    }

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        color: Colors.fg
        font.pixelSize: 13
        text: root.muted ? "󰍭" : "󰍬"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted;
        }
    }
}
