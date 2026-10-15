// Watcher de audio de salida -- sin UI propia (se saco el icono de la
// barra a pedido del usuario, ya esta el OSD). Instanciado sin pantalla
// directo en shell.qml: su unico trabajo es mirar Pipewire y disparar
// OsdState.show() en cada cambio de volumen/mute, sea cual sea el origen
// (scroll del futuro dropdown de la Fase B, teclas de volumen, pavucontrol,
// otro pw-cli).
import QtQuick
import Quickshell.Services.Pipewire
import ".." // OsdState.qml

Item {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: !!(root.sink && root.sink.audio && root.sink.audio.muted)
    readonly property real volume: (root.sink && root.sink.audio) ? root.sink.audio.volume : 0
    // Nombre de ligadura de Material Symbols (lo dibuja Osd.qml).
    readonly property string icon: {
        if (root.muted) return "volume_off";
        return root.volume > 0.66 ? "volume_up" : root.volume > 0.33 ? "volume_down" : "volume_mute";
    }

    // Evita el OSD fantasma al arrancar Quickshell (la primera evaluacion
    // de volume/muted no es un cambio real de nadie).
    property bool armed: false
    Component.onCompleted: Qt.callLater(() => root.armed = true)

    function showOsd() {
        if (!root.armed) return;
        OsdState.show(root.icon, root.volume, root.muted ? I18n.tr("Muted") : I18n.tr("%1%", Math.round(root.volume * 100)));
    }

    onMutedChanged: root.showOsd()
    onVolumeChanged: root.showOsd()
}
