// Panel propio para dispositivos bluetooth -- reemplaza al
// `kitty -e scripts/bluetooth menu` (fzf) que usaba antes Bluetooth.qml.
// "Escanear" prende discovering un rato (BlueZ va poblando
// Bluetooth.devices solo, reactivo) -- no hace falta pollear nada.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import ".." // Colors.qml, Tokens.qml

PopupWindow {
    id: popup
    required property var anchorItem
    required property var panelWindow

    function toggle() {
        popup.visible = !popup.visible;
    }

    implicitWidth: Tokens.panel.widthSm
    implicitHeight: Math.min(400, card.implicitHeight)
    color: "transparent"
    grabFocus: true

    anchor.window: popup.panelWindow
    // Ver el comentario largo en NetworkDropdown.qml: mapToItem() no es
    // reactivo a cambios de layout, hay que recorrer padres leyendo ".x"
    // a mano.
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
    onVisibleChanged: {
        if (popup.adapter) popup.adapter.discovering = popup.visible;
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
                        text: "Bluetooth"
                        color: Colors.m3onSurface
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
                    color: Colors.m3onSurfaceVariant
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                }

                Switch {
                    checked: !!(popup.adapter && popup.adapter.enabled)
                    onToggled: if (popup.adapter) popup.adapter.enabled = !popup.adapter.enabled
                }
            }

            Text {
                visible: popup.devices.length === 0
                Layout.leftMargin: Tokens.space.md
                Layout.bottomMargin: Tokens.space.xs
                text: "Sin dispositivos"
                color: Colors.m3onSurfaceVariant
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
                    color: deviceRow.selected ? Colors.m3secondaryContainer : "transparent"

                    StateLayer { hovered: btMouse.containsMouse; pressed: btMouse.pressed }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.space.md
                        anchors.rightMargin: Tokens.space.md
                        spacing: Tokens.gap.inline

                        Icon {
                            name: deviceRow.modelData.connected ? "bluetooth_connected" : "bluetooth"
                            filled: deviceRow.selected
                            color: deviceRow.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                        }

                        Text {
                            text: deviceRow.modelData.name
                            color: deviceRow.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: deviceRow.selected ? Tokens.weight.medium : Tokens.weight.regular
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: deviceRow.modelData.batteryAvailable
                            text: Math.round(deviceRow.modelData.battery * 100) + "%"
                            color: deviceRow.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
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
}
