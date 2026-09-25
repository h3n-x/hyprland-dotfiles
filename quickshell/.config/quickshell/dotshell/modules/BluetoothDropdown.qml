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
    readonly property int cardWidth: Tokens.panel.widthSm
    implicitWidth: popup.cardWidth + card.shadowMargin * 2
    implicitHeight: Math.min(400, card.implicitHeight) + card.shadowMargin * 2
    color: "transparent"
    mask: Region { item: card }
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
        return Math.max(0, x - popup.cardWidth + popup.anchorItem.width) - card.shadowMargin;
    }
    anchor.rect.y: popup.panelWindow ? popup.panelWindow.height - card.shadowMargin : 0

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
        if (!popup.visible && presence.shown) presence.snapClosed();
        if (popup.adapter) popup.adapter.discovering = popup.visible;
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
