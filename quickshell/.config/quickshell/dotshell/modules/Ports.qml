// Modulo de puertos abiertos para la barra de Quickshell.
// Muestra icono y cantidad de puertos en escucha; al hacer clic despliega
// PortsDropdown para visualizarlos y cerrarlos individualmente.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml

Item {
    id: root
    required property var panelWindow

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    property int portCount: 0
    property var portsList: []
    property string filterMode: "dev"

    readonly property string managerScript: Quickshell.env("HOME") + "/.config/hypr/scripts/ports-manager.sh"

    // Proceso para consultar puertos en escucha via JSON
    Process {
        id: proc
        command: [root.managerScript, "data", root.filterMode]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    root.portsList = data;
                    root.portCount = data.length;
                } catch (e) {
                    root.portsList = [];
                    root.portCount = 0;
                }
            }
        }
    }

    function refresh() {
        proc.running = true;
    }

    // Actualizacion periodica cada 5 segundos
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Timer corto tras cerrar un puerto para actualizar la lista rapidamente
    Timer {
        id: afterCloseTimer
        interval: 400
        onTriggered: root.refresh()
    }

    RowLayout {
        id: layout
        spacing: Tokens.space.xs
        anchors.centerIn: parent

        Icon {
            name: "cable"
            filled: root.portCount > 0
            color: root.portCount > 0 ? Colors.m3primary : Colors.m3onSurface
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.portCount > 0
            text: root.portCount.toString()
            color: Colors.m3onSurface
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
            font.weight: Tokens.weight.semibold
            font.features: Tokens.tabularNumbers
            Layout.alignment: Qt.AlignVCenter
        }
    }

    PortsDropdown {
        id: dropdown
        anchorItem: root
        panelWindow: root.panelWindow
        ports: root.portsList
        filterMode: root.filterMode
        onFilterModeToggled: {
            root.filterMode = (root.filterMode === "dev" ? "all" : "dev");
            root.refresh();
        }
        onRefreshRequested: root.refresh()
        onClosePortRequested: (proto, port, pid, processName) => {
            const pidStr = pid ? pid.toString() : "-";
            const procStr = processName ? processName : "-";
            Quickshell.execDetached([root.managerScript, "close", proto, port.toString(), pidStr, procStr]);
            afterCloseTimer.restart();
        }
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
                root.refresh();
            } else {
                dropdown.toggle();
            }
        }
    }
}
