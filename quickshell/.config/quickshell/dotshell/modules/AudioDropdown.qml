// Panel emergente para seleccionar dispositivos de entrada y salida de audio al vuelo
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml

PopupWindow {
    id: popup
    required property var anchorItem
    required property var panelWindow

    property var audioData: ({ sinks: [], sources: [] })
    readonly property string managerScript: Quickshell.env("HOME") + "/.config/hypr/scripts/audio-manager.sh"

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
        if (!popup.visible && presence.shown) presence.snapClosed();
        if (popup.visible) popup.refresh();
    }

    // Ancho de la tarjeta; la ventana suma el margen de la sombra alrededor
    // (Surface.shadowMargin) y solo acepta input sobre la tarjeta (mask).
    readonly property int cardWidth: Tokens.panel.widthMd
    implicitWidth: popup.cardWidth + card.shadowMargin * 2
    implicitHeight: Math.min(460, card.implicitHeight) + card.shadowMargin * 2
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
                        text: "Dispositivos de audio"
                        color: Colors.m3onSurface
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.title
                        font.weight: Tokens.weight.semibold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "Salidas y micrófonos (PipeWire)"
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

                    StateLayer { hovered: refMouse.containsMouse; pressed: refMouse.pressed }

                    Icon {
                        anchors.centerIn: parent
                        name: "refresh"
                        filled: false
                        color: Colors.m3onSurface
                    }

                    MouseArea {
                        id: refMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.refresh()
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

            Text {
                text: "SALIDA (ALTAVOCES / AURICULARES)"
                color: Colors.m3primary
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                font.weight: Tokens.weight.semibold
                Layout.leftMargin: Tokens.space.md
                Layout.topMargin: Tokens.space.xs
                Layout.bottomMargin: Tokens.space.xs
            }

            Repeater {
                model: popup.audioData.sinks

                Rectangle {
                    id: sinkRow
                    required property var modelData
                    readonly property bool selected: sinkRow.modelData.default
                    Layout.fillWidth: true
                    implicitHeight: Tokens.row.height
                    radius: Tokens.radius.sm
                    // Fila seleccionada (conectada / por defecto) en secondary
                    // container (decision C3); el hover lo da la StateLayer.
                    color: sinkRow.selected ? Colors.m3secondaryContainer : "transparent"
                    Behavior on color { ColorAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }

                    StateLayer { hovered: sinkMouse.containsMouse; pressed: sinkMouse.pressed }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.space.md
                        anchors.rightMargin: Tokens.space.md
                        spacing: Tokens.gap.inline

                        Icon {
                            name: sinkRow.modelData.name.toLowerCase().includes("headphone") ? "headphones" : "speaker"
                            filled: sinkRow.selected
                            color: sinkRow.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                        }

                        Text {
                            text: sinkRow.modelData.name
                            color: sinkRow.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: sinkRow.selected ? Tokens.weight.medium : Tokens.weight.regular
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Icon {
                            visible: sinkRow.selected
                            name: "check"
                            size: Tokens.icon.sm
                            color: Colors.m3onSecondaryContainer
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
                Layout.topMargin: Tokens.space.xs
                Layout.bottomMargin: Tokens.space.xs
                implicitHeight: 1
                color: Colors.m3outlineVariant
            }

            Text {
                text: "ENTRADA (MICRÓFONO)"
                color: Colors.m3tertiary
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                font.weight: Tokens.weight.semibold
                Layout.leftMargin: Tokens.space.md
                Layout.topMargin: Tokens.space.xs
                Layout.bottomMargin: Tokens.space.xs
            }

            Repeater {
                model: popup.audioData.sources

                Rectangle {
                    id: srcRow
                    required property var modelData
                    readonly property bool selected: srcRow.modelData.default
                    Layout.fillWidth: true
                    implicitHeight: Tokens.row.height
                    radius: Tokens.radius.sm
                    // Fila seleccionada (conectada / por defecto) en secondary
                    // container (decision C3); el hover lo da la StateLayer.
                    color: srcRow.selected ? Colors.m3secondaryContainer : "transparent"
                    Behavior on color { ColorAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }

                    StateLayer { hovered: srcMouse.containsMouse; pressed: srcMouse.pressed }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.space.md
                        anchors.rightMargin: Tokens.space.md
                        spacing: Tokens.gap.inline

                        Icon {
                            name: "mic"
                            filled: srcRow.selected
                            color: srcRow.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                        }

                        Text {
                            text: srcRow.modelData.name
                            color: srcRow.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: srcRow.selected ? Tokens.weight.medium : Tokens.weight.regular
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Icon {
                            visible: srcRow.selected
                            name: "check"
                            size: Tokens.icon.sm
                            color: Colors.m3onSecondaryContainer
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
