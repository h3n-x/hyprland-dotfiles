// Reusa hypr/scripts/update.sh (movido ahi al sacar Waybar, ver Fase 4 del
// plan -- ya sin el trap "pkill -RTMIN+1 waybar" que tenia el original,
// no hacia falta): "data" para el chequeo periodico (JSON {text,tooltip}),
// sin argumentos para el update interactivo real en una terminal. El
// click-derecho fuerza un re-chequeo ya, sin depender de ninguna señal.
import QtQuick
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml

Item {
    id: root
    // Nombre de icono de Material Symbols que emite update.sh ("data"):
    // download / check / sync_problem. "schedule" hasta el primer chequeo.
    property string icon: "schedule"

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
                    root.icon = data.icon || "sync_problem";
                } catch (e) {
                    root.icon = "sync_problem";
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

    Icon {
        id: label
        name: root.icon
        filled: root.icon === "download"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                proc.running = true;
            } else {
                Quickshell.execDetached(["kitty", "-e", root.scriptPath]);
            }
        }
    }
}
