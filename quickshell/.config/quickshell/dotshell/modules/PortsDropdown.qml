// Panel desplegable para visualizar y cerrar puertos abiertos en escucha
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml

PopupWindow {
    id: popup
    required property var anchorItem
    required property var panelWindow
    property var ports: []
    property string filterMode: "dev"

    signal refreshRequested()
    signal filterModeToggled()
    signal closePortRequested(string proto, int port, var pid, string process)

    function toggle() {
        popup.visible = !popup.visible;
    }

    implicitWidth: 340
    implicitHeight: Math.min(450, card.implicitHeight)
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

    onVisibleChanged: {
        if (popup.visible) popup.refreshRequested();
    }

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
                    text: "󰛳"
                    color: Colors.accent
                    font.pixelSize: 16
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true

                    Text {
                        text: popup.filterMode === "dev" ? "Puertos Dev / HTB" : "Todos los Puertos"
                        color: Colors.fg
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        text: {
                            const count = popup.ports.length;
                            if (popup.filterMode === "dev") {
                                return count + (count === 1 ? " servicio activo" : " servicios activos");
                            }
                            return count + " sockets en el sistema";
                        }
                        color: Colors.br
                        font.pixelSize: 11
                    }
                }

                // Botón de alternar filtro Dev/HTB vs Todos
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: filterMouse.containsMouse ? Colors.hoverBg : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰈲"
                        color: popup.filterMode === "dev" ? Colors.accent : Colors.br
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: filterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.filterModeToggled()
                    }
                }

                // Botón de refresco manual
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: refreshMouse.containsMouse ? Colors.hoverBg : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: Colors.fg
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.refreshRequested()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.br
            }

            // Estado vacio
            Item {
                visible: popup.ports.length === 0
                Layout.fillWidth: true
                implicitHeight: 70

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰈂"
                        color: Colors.br
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: popup.filterMode === "dev" ? "Sin servidores Dev ni listeners HTB" : "No hay puertos en escucha"
                        color: Colors.br
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        visible: popup.filterMode === "dev"
                        text: "(Node, Python, Netcat, Chisel, Docker, etc.)"
                        color: Colors.br
                        font.pixelSize: 10
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Lista de puertos con scroll si excede la altura
            Flickable {
                visible: popup.ports.length > 0
                Layout.fillWidth: true
                implicitHeight: Math.min(340, portCol.implicitHeight)
                contentHeight: portCol.implicitHeight
                contentWidth: width
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: portCol
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: popup.ports

                        Rectangle {
                            id: portRow
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: 8
                            color: rowMouse.containsMouse ? Colors.hoverBg : Colors.bg0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                // Badge de protocolo
                                Rectangle {
                                    width: 32
                                    height: 20
                                    radius: 4
                                    color: portRow.modelData.proto === "TCP" ? Colors.bg2 : Colors.bg3

                                    Text {
                                        anchors.centerIn: parent
                                        text: portRow.modelData.proto
                                        color: portRow.modelData.proto === "TCP" ? Colors.accent : Colors.warning
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }

                                // Informacion de puerto y host
                                ColumnLayout {
                                    spacing: 1
                                    Layout.fillWidth: true

                                    RowLayout {
                                        spacing: 4

                                        Text {
                                            text: ":" + portRow.modelData.port
                                            color: Colors.fg
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        Text {
                                            text: "(" + portRow.modelData.host + ")"
                                            color: Colors.br
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        text: {
                                            const p = portRow.modelData.process || "-";
                                            const pid = portRow.modelData.pid ? " [PID " + portRow.modelData.pid + "]" : "";
                                            return p + pid;
                                        }
                                        color: Colors.br
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                // Boton para cerrar puerto
                                Rectangle {
                                    id: closeBtn
                                    width: 26
                                    height: 26
                                    radius: 13
                                    color: closeMouse.containsMouse ? (Colors.critical + "33") : "transparent"
                                    border.color: closeMouse.containsMouse ? Colors.critical : "transparent"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅙"
                                        color: closeMouse.containsMouse ? Colors.critical : Colors.br
                                        font.pixelSize: 13
                                    }

                                    MouseArea {
                                        id: closeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const d = portRow.modelData;
                                            popup.closePortRequested(d.proto, d.port, d.pid, d.process);
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }
            }
        }
    }
}
