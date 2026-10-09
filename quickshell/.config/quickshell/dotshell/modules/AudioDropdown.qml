// Panel emergente para seleccionar dispositivos de entrada y salida de audio al vuelo
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml

AnchoredPanel {
    id: popup
    popupId: "audio"
    align: "end"
    padding: Tokens.pad.card
    heightCap: Tokens.px(460)

    property var audioData: ({ sinks: [], sources: [] })
    readonly property string managerScript: Quickshell.env("HOME") + "/.config/hypr/scripts/audio-manager.sh"

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

    onActiveChanged: {
        if (popup.active) popup.refresh();
    }

    // Ancho del contenido (la tarjeta suma el margen interior).
    readonly property int contentWidth: Tokens.panel.widthMd - 2 * Tokens.pad.card

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
                    text: "Dispositivos de audio"
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.title
                    font.weight: Tokens.weight.semibold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: "Salidas y micrófonos (PipeWire)"
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

                StateLayer { hovered: refMouse.containsMouse; pressed: refMouse.pressed }

                Icon {
                    anchors.centerIn: parent
                    name: "refresh"
                    filled: false
                    color: Colors.text
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
            color: Colors.divider
        }

        Text {
            text: "SALIDA (ALTAVOCES / AURICULARES)"
            // Con el texto grande (hasta 150 %) se corta en vez de salirse de la tarjeta.
            Layout.fillWidth: true
            Layout.rightMargin: Tokens.space.md
            elide: Text.ElideRight
            color: Colors.accent
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
                color: sinkRow.selected ? Colors.accentAltContainer : "transparent"
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
                        color: sinkRow.selected ? Colors.textOnAccentAltContainer : Colors.text
                    }

                    Text {
                        text: sinkRow.modelData.name
                        color: sinkRow.selected ? Colors.textOnAccentAltContainer : Colors.text
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
                        color: Colors.textOnAccentAltContainer
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
            color: Colors.divider
        }

        Text {
            text: "ENTRADA (MICRÓFONO)"
            Layout.fillWidth: true
            Layout.rightMargin: Tokens.space.md
            elide: Text.ElideRight
            color: Colors.decor
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
                color: srcRow.selected ? Colors.accentAltContainer : "transparent"
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
                        color: srcRow.selected ? Colors.textOnAccentAltContainer : Colors.text
                    }

                    Text {
                        text: srcRow.modelData.name
                        color: srcRow.selected ? Colors.textOnAccentAltContainer : Colors.text
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
                        color: Colors.textOnAccentAltContainer
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

    Timer {
        id: refTimer
        interval: 300
        onTriggered: popup.refresh()
    }
}
