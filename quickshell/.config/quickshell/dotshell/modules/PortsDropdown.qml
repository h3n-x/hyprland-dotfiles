// Panel desplegable para visualizar y cerrar puertos abiertos en escucha
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml

AnchoredPanel {
    id: popup
    popupId: "ports"
    align: "end"
    padding: Tokens.pad.card
    heightCap: Tokens.px(450)
    property var ports: []
    property string filterMode: "dev"

    signal refreshRequested()
    signal filterModeToggled()
    signal closePortRequested(string proto, int port, var pid, string process)

    // Ancho del contenido (la tarjeta suma el margen interior).
    readonly property int contentWidth: Tokens.panel.widthLg - 2 * Tokens.pad.card

    onActiveChanged: {
        if (popup.active) popup.refreshRequested();
    }

    ColumnLayout {
        id: layout
        width: popup.contentWidth
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
                    text: popup.filterMode === "dev" ? I18n.tr("Dev / HTB ports") : I18n.tr("All ports")
                    color: Colors.text
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
                            return I18n.trn("%n active service", "%n active services", count);
                        }
                        return I18n.trn("%n socket on the system", "%n sockets on the system", count);
                    }
                    color: Colors.textMuted
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
                    color: popup.filterMode === "dev" ? Colors.accent : Colors.textMuted
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
                    color: Colors.text
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
            color: Colors.divider
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
                    color: Colors.textMuted
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: popup.filterMode === "dev" ? I18n.tr("No Dev servers or HTB listeners") : I18n.tr("No listening ports")
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    visible: popup.filterMode === "dev"
                    text: I18n.tr("(Node, Python, Netcat, Chisel, Docker, etc.)")
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Flickable {
            visible: popup.ports.length > 0
            Layout.fillWidth: true
            implicitHeight: Math.min(Tokens.px(340), portCol.implicitHeight)
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
                        color: Colors.surfaceLow

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
                                implicitHeight: Tokens.px(20)
                                radius: Tokens.radius.xs
                                color: tcp ? Colors.accentAltContainer : Colors.decorContainer

                                Text {
                                    id: protoText
                                    anchors.centerIn: parent
                                    text: portRow.modelData.proto
                                    color: parent.tcp ? Colors.textOnAccentAltContainer : Colors.textOnDecorContainer
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
                                        color: Colors.text
                                        font.family: Tokens.font.mono
                                        font.pixelSize: Tokens.type.body
                                        font.weight: Tokens.weight.semibold
                                    }

                                    Text {
                                        text: "(" + portRow.modelData.host + ")"
                                        color: Colors.textMuted
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
                                    color: Colors.textMuted
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

                                StateLayer { hovered: closeMouse.containsMouse; pressed: closeMouse.pressed; contentColor: Colors.danger }

                                Icon {
                                    anchors.centerIn: parent
                                    name: "cancel"
                                    color: closeMouse.containsMouse ? Colors.danger : Colors.textMuted
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
