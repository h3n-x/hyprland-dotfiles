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
        presence.open = !presence.open;
    }

    // Apertura/cierre animados (P2.5, guia DESIGN_TOKENS 3.6.1): la ventana
    // sigue a Presence y queda mapeada mientras el contenido anima la salida.
    // Si Quickshell cierra el popup por su cuenta (grabFocus, click afuera),
    // Presence se cierra al instante: Hyprland ya funde el popup al desmapearlo.
    Presence { id: presence }
    Connections {
        target: presence
        function onShownChanged() {
            popup.visible = presence.shown;
        }
    }

    // Ancho de la tarjeta; la ventana suma el margen de la sombra alrededor
    // (Surface.shadowMargin) y solo acepta input sobre la tarjeta (mask).
    readonly property int cardWidth: Tokens.panel.widthLg
    implicitWidth: popup.cardWidth + card.shadowMargin * 2
    implicitHeight: Math.min(450, card.implicitHeight) + card.shadowMargin * 2
    color: "transparent"
    mask: Region { item: card }
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
        return Math.max(0, x - popup.cardWidth + popup.anchorItem.width) - card.shadowMargin;
    }
    anchor.rect.y: popup.panelWindow ? popup.panelWindow.height - card.shadowMargin : 0

    onVisibleChanged: {
        if (!popup.visible && presence.shown) presence.snapClosed();
        if (popup.visible) popup.refreshRequested();
    }

    // Nivel de elevacion 2: surface_container translucida sobre el blur de
    // popups de la barra (blur_popups, ver rules.lua) y sombra sm. Radio lg con
    // inset de 8 para que las filas (radio sm) queden concentricas (Q1).
    Surface {
        id: card
        x: card.shadowMargin
        y: card.shadowMargin
        width: popup.cardWidth
        implicitHeight: layout.implicitHeight + Tokens.pad.card * 2
        level: 2
        translucent: true
        radius: Tokens.radius.lg
        // Entrada/salida: sube space.sm hacia la barra y crece desde 0.98.
        opacity: presence.progress
        scale: presence.contentScale
        transformOrigin: Item.Top
        transform: Translate { y: presence.offsetY }

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
                                return count + (count === 1 ? " servicio activo" : " servicios activos");
                            }
                            return count + " sockets en el sistema";
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
                        text: popup.filterMode === "dev" ? "Sin servidores Dev ni listeners HTB" : "No hay puertos en escucha"
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        visible: popup.filterMode === "dev"
                        text: "(Node, Python, Netcat, Chisel, Docker, etc.)"
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
                                    implicitHeight: 20
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
}
