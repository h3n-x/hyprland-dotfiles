// Panel propio para dispositivos bluetooth -- reemplaza al
// `kitty -e scripts/bluetooth menu` (fzf) que usaba antes Bluetooth.qml.
// "Escanear" prende discovering un rato (BlueZ va poblando
// Bluetooth.devices solo, reactivo) -- no hace falta pollear nada.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import ".." // Colors.qml, Tokens.qml, QuickTiles.qml

AnchoredPanel {
    id: popup
    popupId: "bluetooth"
    align: "end"
    padding: Tokens.pad.card
    heightCap: Tokens.px(400)

    // Ancho del contenido (la tarjeta suma el margen interior).
    readonly property int contentWidth: Tokens.panel.widthSm - 2 * Tokens.pad.card

    readonly property var adapter: Bluetooth.defaultAdapter
    // De-duplicado por MAC: algunos dispositivos (ej. TVs con BR/EDR+LE)
    // aparecen dos veces en Bluetooth.devices con el mismo "address" --
    // visto en vivo con una TV LG duplicada en la lista.
    readonly property var devices: {
        const seen = new Set();
        const unique = [];
        for (const d of Bluetooth.devices.values) {
            if (seen.has(d.address)) continue;
            seen.add(d.address);
            unique.push(d);
        }
        return unique.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            return a.name.localeCompare(b.name);
        });
    }

    // Escanear solo mientras el popup esta abierto -- no tiene sentido
    // dejar el adaptador escaneando de fondo indefinidamente.
    onActiveChanged: {
        if (popup.adapter) popup.adapter.discovering = popup.active;
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
                    text: "Bluetooth"
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.title
                    font.weight: Tokens.weight.semibold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: !!popup.adapter && popup.adapter.discovering
                text: "Buscando..."
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
            }

            Switch {
                checked: !!(popup.adapter && popup.adapter.enabled)
                onToggled: QuickTiles.toggleBluetooth()
            }
        }

        Text {
            visible: popup.devices.length === 0
            Layout.leftMargin: Tokens.space.md
            Layout.bottomMargin: Tokens.space.xs
            text: "Sin dispositivos"
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
        }

        Repeater {
            model: popup.devices

            Rectangle {
                id: deviceRow
                required property var modelData
                readonly property bool selected: deviceRow.modelData.connected
                Layout.fillWidth: true
                implicitHeight: Tokens.row.height
                radius: Tokens.radius.sm
                // Fila seleccionada (conectada / por defecto) en secondary
                // container (decision C3); el hover lo da la StateLayer.
                color: deviceRow.selected ? Colors.accentAltContainer : "transparent"
                Behavior on color { ColorAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }

                StateLayer { hovered: btMouse.containsMouse; pressed: btMouse.pressed }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.space.md
                    anchors.rightMargin: Tokens.space.md
                    spacing: Tokens.gap.inline

                    Icon {
                        name: deviceRow.modelData.connected ? "bluetooth_connected" : "bluetooth"
                        filled: deviceRow.selected
                        color: deviceRow.selected ? Colors.textOnAccentAltContainer : Colors.text
                    }

                    Text {
                        text: deviceRow.modelData.name
                        color: deviceRow.selected ? Colors.textOnAccentAltContainer : Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.weight: deviceRow.selected ? Tokens.weight.medium : Tokens.weight.regular
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: deviceRow.modelData.batteryAvailable
                        text: Math.round(deviceRow.modelData.battery * 100) + "%"
                        color: deviceRow.selected ? Colors.textOnAccentAltContainer : Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                        font.features: Tokens.tabularNumbers
                    }
                }

                MouseArea {
                    id: btMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const d = deviceRow.modelData;
                        if (d.connected) {
                            d.disconnect();
                        } else if (d.paired) {
                            d.connect();
                        } else {
                            d.pair();
                            d.connect();
                        }
                    }
                }
            }
        }
    }
}
