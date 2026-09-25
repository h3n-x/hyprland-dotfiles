// Panel emergente para seleccionar dispositivos de entrada y salida de audio al vuelo
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." // Colors.qml

PopupWindow {
    id: popup
    required property var anchorItem
    required property var panelWindow

    property var audioData: ({ sinks: [], sources: [] })
    readonly property string managerScript: Quickshell.env("HOME") + "/.config/hypr/scripts/audio-manager.sh"

    function toggle() {
        popup.visible = !popup.visible;
    }

    Process {
        id: proc
        command: [popup.managerScript, "data"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    popup.audioData = JSON.parse(this.text);
                } catch (e) {
                    popup.audioData = { sinks: [], sources: [] };
                }
            }
        }
    }

    function refresh() {
        proc.running = true;
    }

    onVisibleChanged: {
        if (popup.visible) popup.refresh();
    }

    implicitWidth: 320
    implicitHeight: Math.min(460, card.implicitHeight)
    color: "transparent"
    grabFocus: true

    anchor.window: popup.panelWindow
    function absoluteX(item) {
        let x = 0;
        let cur = item;
        while (cur && cur !== popup.panelWindow.contentItem) {
            x += cur.x;
            cur = cur.parent;
        }
        return x;
    }
    anchor.rect.x: {
        if (!popup.anchorItem || !popup.panelWindow || !popup.panelWindow.contentItem) return 0;
        const x = popup.absoluteX(popup.anchorItem);
        return Math.max(0, x - popup.implicitWidth + popup.anchorItem.width);
    }
    anchor.rect.y: popup.panelWindow ? popup.panelWindow.height : 0

    Rectangle {
        id: card
        width: popup.implicitWidth
        implicitHeight: layout.implicitHeight + 24
        radius: 16
        color: Colors.bg1
        border.color: Colors.br
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Encabezado
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰓃"
                    color: Colors.accent
                    font.pixelSize: 16
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true

                    Text {
                        text: "Dispositivos de Audio"
                        color: Colors.fg
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        text: "Salidas y Micrófonos (PipeWire)"
                        color: Colors.br
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: refMouse.containsMouse ? Colors.hoverBg : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: Colors.fg
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: refMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: popup.refresh()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.br
            }

            // Seccion Salidas (Sinks)
            Text {
                text: "SALIDA (ALTAVOCES / AURICULARES)"
                color: Colors.accent
                font.pixelSize: 10
                font.bold: true
                Layout.topMargin: 2
            }

            Repeater {
                model: popup.audioData.sinks

                Rectangle {
                    id: sinkRow
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 8
                    color: sinkMouse.containsMouse ? Colors.hoverBg : (sinkRow.modelData.default ? Colors.bg2 : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Text {
                            text: sinkRow.modelData.name.toLowerCase().includes("headphone") ? "󰋋" : "󰓃"
                            color: sinkRow.modelData.default ? Colors.accent : Colors.fg
                            font.pixelSize: 14
                        }

                        Text {
                            text: sinkRow.modelData.name
                            color: sinkRow.modelData.default ? Colors.accent : Colors.fg
                            font.pixelSize: 12
                            font.bold: sinkRow.modelData.default
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: sinkRow.modelData.default
                            text: "✓"
                            color: Colors.accent
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: sinkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached([popup.managerScript, "set-default", sinkRow.modelData.id.toString(), sinkRow.modelData.name, "sink"]);
                            refTimer.restart();
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.br
                Layout.topMargin: 4
            }

            // Seccion Entradas (Sources)
            Text {
                text: "ENTRADA (MICRÓFONO)"
                color: Colors.charging
                font.pixelSize: 10
                font.bold: true
                Layout.topMargin: 2
            }

            Repeater {
                model: popup.audioData.sources

                Rectangle {
                    id: srcRow
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 8
                    color: srcMouse.containsMouse ? Colors.hoverBg : (srcRow.modelData.default ? Colors.bg2 : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Text {
                            text: "󰍬"
                            color: srcRow.modelData.default ? Colors.charging : Colors.fg
                            font.pixelSize: 14
                        }

                        Text {
                            text: srcRow.modelData.name
                            color: srcRow.modelData.default ? Colors.charging : Colors.fg
                            font.pixelSize: 12
                            font.bold: srcRow.modelData.default
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: srcRow.modelData.default
                            text: "✓"
                            color: Colors.charging
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: srcMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached([popup.managerScript, "set-default", srcRow.modelData.id.toString(), srcRow.modelData.name, "source"]);
                            refTimer.restart();
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: refTimer
        interval: 300
        onTriggered: popup.refresh()
    }
}
