// Privacidad en la barra (Fase 11 B2): solo mientras algo esta en uso.
//   pantalla   compartida o capturada (FullscreenState: evento screencastv2 de
//              Hyprland, el mismo de P8.6) o grabando
//   microfono  una app graba audio (nodos AudioInStream de PipeWire)
//   camara     una app usa una camara por PipeWire (enlaces del nodo de video;
//              las que abren /dev/video directo no se ven)
// Un estado: el color fijo de advertencia, nunca el de identidad (principio 23).
// Sin sondeo: todo llega por eventos.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import ".." // Colors.qml, Tokens.qml, FullscreenState.qml

Item {
    id: root
    readonly property bool screenShared: FullscreenState.recording || Object.keys(FullscreenState.capture).length > 0
    readonly property bool micInUse: Pipewire.nodes.values.some(n => n.type === PwNodeType.AudioInStream)
    readonly property var cameras: Pipewire.nodes.values.filter(n => n.type === PwNodeType.VideoSource)
    property int cameraLinks: 0
    readonly property bool cameraInUse: root.cameraLinks > 0
    readonly property bool shown: root.screenShared || root.micInUse || root.cameraInUse
    // Texto de la informacion al pasar el raton (bar.tooltips, Fase 11 B2b).
    readonly property string tooltip: [root.screenShared ? "Pantalla compartida" : "", root.micInUse ? "Micrófono en uso" : "", root.cameraInUse ? "Cámara en uso" : ""].filter(x => x).join(" · ")
    visible: shown

    // Enlaces de cada camara: cuantos la estan usando.
    Repeater {
        model: root.cameras
        Item {
            required property var modelData
            PwNodeLinkTracker {
                id: links
                node: modelData
                onLinkGroupsChanged: root.countCameras()
            }
            readonly property int n: links.linkGroups.length
            Component.onCompleted: root.countCameras()
            Component.onDestruction: Qt.callLater(root.countCameras)
        }
    }
    function countCameras(): void {
        let n = 0;
        for (let i = 0; i < root.children.length; i++)
            if (root.children[i].n !== undefined) n += root.children[i].n;
        root.cameraLinks = n;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: Tokens.space.xs
        Icon { visible: root.screenShared; name: "screen_share"; size: Tokens.icon.md; filled: true; color: Colors.warning }
        Icon { visible: root.micInUse; name: "mic"; size: Tokens.icon.md; filled: true; color: Colors.warning }
        Icon { visible: root.cameraInUse; name: "videocam"; size: Tokens.icon.md; filled: true; color: Colors.warning }
    }
}
