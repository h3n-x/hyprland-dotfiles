// Reusa hypr/scripts/update.sh (movido ahi al sacar Waybar, ver Fase 4 del
// plan -- ya sin el trap "pkill -RTMIN+1 waybar" que tenia el original,
// no hacia falta): "data" para el chequeo periodico (JSON {text,tooltip}),
// sin argumentos para el update interactivo real en una terminal. El
// click-derecho fuerza un re-chequeo ya, sin depender de ninguna señal.
import QtQuick
import Quickshell
import Quickshell.Io
import ".." // Colors.qml

Item {
    id: root
    property string text: "󰒲"

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/hypr/scripts/update.sh"

    Process {
        id: proc
        command: [root.scriptPath, "data"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    root.text = data.text || "󰒑";
                } catch (e) {
                    root.text = "󰒑";
                }
            }
        }
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Text {
        id: label
        color: Colors.fg
        font.pixelSize: 14
        text: root.text
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                proc.running = true;
            } else {
                Quickshell.execDetached(["kitty", "-e", root.scriptPath]);
            }
        }
    }
}
