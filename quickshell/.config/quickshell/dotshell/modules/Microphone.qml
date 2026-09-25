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
        OsdState.show(root.muted ? "mic_off" : "mic", root.muted ? 0 : 1, root.muted ? "Mic muted" : "Mic on");
    }

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Icon {
        id: label
        name: root.muted ? "mic_off" : "mic"
        filled: !root.muted
    }

    required property var panelWindow

    AudioDropdown {
        id: audioDropdown
        anchorItem: root
        panelWindow: root.panelWindow
    }

    // Hover por control (P2.4, Q2 = A).
    HoverHalo { hovered: hoverArea.containsMouse; pressed: hoverArea.pressed }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                audioDropdown.toggle();
            } else {
                if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted;
            }
        }
    }
}
