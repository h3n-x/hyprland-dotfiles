// Panel propio para dispositivos bluetooth -- reemplaza al
// `kitty -e scripts/bluetooth menu` (fzf) que usaba antes Bluetooth.qml.
// "Escanear" prende discovering un rato (BlueZ va poblando
// Bluetooth.devices solo, reactivo) -- no hace falta pollear nada.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import ".." // Colors.qml

PopupWindow {
    id: popup
    required property var anchorItem
    required property var panelWindow

    function toggle() {
        popup.visible = !popup.visible;
    }

    implicitWidth: 280
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
        implicitHeight: layout.implicitHeight + 28
        radius: 16
        color: Colors.bg1
        border.color: Colors.br
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Bluetooth"
                    color: Colors.fg
                    font.pixelSize: 14
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    visible: !!popup.adapter && popup.adapter.discovering
                    text: "Buscando..."
                    color: Colors.br
                    font.pixelSize: 11
                }

                Rectangle {
                    width: 36
                    height: 20
                    radius: 10
                    color: (popup.adapter && popup.adapter.enabled) ? Colors.accent : Colors.bg3

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: Colors.bg0
                        anchors.verticalCenter: parent.verticalCenter
                        x: (popup.adapter && popup.adapter.enabled) ? parent.width - width - 2 : 2
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (popup.adapter) popup.adapter.enabled = !popup.adapter.enabled
                    }
                }
            }

            Text {
                visible: popup.devices.length === 0
                text: "Sin dispositivos"
                color: Colors.br
                font.pixelSize: 13
            }

            Repeater {
                model: popup.devices

                Rectangle {
                    id: deviceRow
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 8
                    color: btMouse.containsMouse ? Colors.hoverBg : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Text {
                            text: deviceRow.modelData.connected ? "󰂱" : "󰂯"
                            color: deviceRow.modelData.connected ? Colors.accent : Colors.fg
                            font.pixelSize: 14
                        }

                        Text {
                            text: deviceRow.modelData.name
                            color: deviceRow.modelData.connected ? Colors.accent : Colors.fg
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: deviceRow.modelData.batteryAvailable
                            text: Math.round(deviceRow.modelData.battery * 100) + "%"
                            color: Colors.br
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: btMouse
                        anchors.fill: parent
                        hoverEnabled: true
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
