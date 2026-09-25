// Panel desplegable para visualizar y cerrar puertos abiertos en escucha
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml

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

    implicitWidth: Tokens.panel.widthLg
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
        implicitHeight: layout.implicitHeight + Tokens.pad.card * 2
        // Nivel de elevacion 2 (surface_container) con borde sutil; radio lg con
        // inset de 8 para que las filas (radio sm) queden concentricas (Q1).
        radius: Tokens.radius.lg
        color: Colors.m3surfaceContainer
        border.color: Colors.m3outlineVariant
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: Tokens.pad.card
            spacing: Tokens.space.xs

            // Encabezado con el mismo inset horizontal que el texto de las filas.
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.space.md
                Layout.rightMargin: Tokens.space.xs
                Layout.topMargin: Tokens.space.xs
                Layout.bottomMargin: Tokens.space.xs
                spacing: Tokens.gap.inline

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    Text {
                        text: popup.filterMode === "dev" ? "Puertos Dev / HTB" : "Todos los puertos"
                        color: Colors.m3onSurface
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.title
                        font.weight: Tokens.weight.semibold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: {
                            const count = popup.ports.length;
                            if (popup.filterMode === "dev") {
                                return count + (count === 1 ? " servicio activo" : " servicios activos");
                            }
                            return count + " sockets en el sistema";
                        }
                        color: Colors.m3onSurfaceVariant
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    implicitWidth: Tokens.pill.height
                    implicitHeight: Tokens.pill.height
                    radius: Tokens.radius.pill(height)
                    color: "transparent"

                    StateLayer { hovered: filterMouse.containsMouse; pressed: filterMouse.pressed }

                    Icon {
                        anchors.centerIn: parent
                        name: "filter_list"
                        filled: false
                        color: popup.filterMode === "dev" ? Colors.m3primary : Colors.m3onSurfaceVariant
                    }

                    MouseArea {
                        id: filterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.filterModeToggled()
                    }
                }
                Rectangle {
                    implicitWidth: Tokens.pill.height
                    implicitHeight: Tokens.pill.height
                    radius: Tokens.radius.pill(height)
                    color: "transparent"

                    StateLayer { hovered: refreshMouse.containsMouse; pressed: refreshMouse.pressed }

                    Icon {
                        anchors.centerIn: parent
                        name: "refresh"
                        filled: false
                        color: Colors.m3onSurface
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
                Layout.topMargin: Tokens.space.xs
                Layout.bottomMargin: Tokens.space.xs
                implicitHeight: 1
                color: Colors.m3outlineVariant
            }

            Item {
                visible: popup.ports.length === 0
                Layout.fillWidth: true
                implicitHeight: emptyCol.implicitHeight + Tokens.space.lg * 2

                ColumnLayout {
                    id: emptyCol
                    anchors.centerIn: parent
                    spacing: Tokens.space.xs

                    Icon {
                        name: "link_off"
                        size: Tokens.icon.lg
                        color: Colors.m3onSurfaceVariant
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: popup.filterMode === "dev" ? "Sin servidores Dev ni listeners HTB" : "No hay puertos en escucha"
                        color: Colors.m3onSurfaceVariant
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        visible: popup.filterMode === "dev"
                        text: "(Node, Python, Netcat, Chisel, Docker, etc.)"
                        color: Colors.m3onSurfaceVariant
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

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
                    spacing: Tokens.space.xs

                    Repeater {
                        model: popup.ports

                        Rectangle {
                            id: portRow
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: Tokens.row.heightLarge
                            radius: Tokens.radius.sm
                            color: Colors.m3surfaceContainerLow

                            StateLayer { hovered: rowMouse.containsMouse }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Tokens.space.sm
                                anchors.rightMargin: Tokens.space.xs
                                spacing: Tokens.gap.inline

                                // Badge de protocolo: radio xs, contenedores M3.
                                Rectangle {
                                    readonly property bool tcp: portRow.modelData.proto === "TCP"
                                    implicitWidth: protoText.implicitWidth + Tokens.space.sm * 2
                                    implicitHeight: 20
                                    radius: Tokens.radius.xs
                                    color: tcp ? Colors.m3secondaryContainer : Colors.m3tertiaryContainer

                                    Text {
                                        id: protoText
                                        anchors.centerIn: parent
                                        text: portRow.modelData.proto
                                        color: parent.tcp ? Colors.m3onSecondaryContainer : Colors.m3onTertiaryContainer
                                        font.family: Tokens.font.ui
                                        font.pixelSize: Tokens.type.caption
                                        font.weight: Tokens.weight.semibold
                                    }
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Layout.fillWidth: true

                                    RowLayout {
                                        spacing: Tokens.space.xs

                                        Text {
                                            text: ":" + portRow.modelData.port
                                            color: Colors.m3onSurface
                                            font.family: Tokens.font.mono
                                            font.pixelSize: Tokens.type.body
                                            font.weight: Tokens.weight.semibold
                                        }

                                        Text {
                                            text: "(" + portRow.modelData.host + ")"
                                            color: Colors.m3onSurfaceVariant
                                            font.family: Tokens.font.mono
                                            font.pixelSize: Tokens.type.caption
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        text: {
                                            const p = portRow.modelData.process || "-";
                                            const pid = portRow.modelData.pid ? " [PID " + portRow.modelData.pid + "]" : "";
                                            return p + pid;
                                        }
                                        color: Colors.m3onSurfaceVariant
                                        font.family: Tokens.font.ui
                                        font.pixelSize: Tokens.type.caption
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                // Cerrar puerto: boton de icono con capa de estado en el rol de
                                // error. Antes el hover hacia Colors.critical + "33", que QML lee
                                // como #AARRGGBB (opaco y amarillento), no como rojo al 20%.
                                Rectangle {
                                    id: closeBtn
                                    implicitWidth: Tokens.pill.height
                                    implicitHeight: Tokens.pill.height
                                    radius: Tokens.radius.pill(height)
                                    color: "transparent"

                                    StateLayer { hovered: closeMouse.containsMouse; pressed: closeMouse.pressed; contentColor: Colors.m3error }

                                    Icon {
                                        anchors.centerIn: parent
                                        name: "cancel"
                                        color: closeMouse.containsMouse ? Colors.m3error : Colors.m3onSurfaceVariant
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
                                z: -1
                            }
                        }
                    }
                }
            }
        }
    }
}
