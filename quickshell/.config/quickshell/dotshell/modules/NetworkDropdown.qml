// Panel propio para elegir red Wi-Fi -- reemplaza al
// `kitty -e scripts/network menu` (fzf) que usaba antes Network.qml.
// Si una red pide contraseña (ConnectionFailReason.NoSecrets al llamar
// connect()), se muestra un campo de texto inline para reintentar con
// connectWithPsk() -- no hace falta saber de antemano si la red es
// "conocida" o no.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import ".." // Colors.qml, Tokens.qml, NetworkState.qml

PopupWindow {
    id: popup
    required property var anchorItem
    required property var panelWindow
    readonly property var wifiDevice: NetworkState.wifiDevice
    readonly property var wiredDevice: NetworkState.wiredDevice

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
    readonly property int cardWidth: Tokens.panel.widthMd
    implicitWidth: popup.cardWidth + card.shadowMargin * 2
    implicitHeight: Math.min(420, card.implicitHeight) + card.shadowMargin * 2
    color: "transparent"
    mask: Region { item: card }
    grabFocus: true

    // Sin esto la lista de redes solo mostraba la ya conectada -- el
    // dispositivo no escanea activamente por si solo. Igual criterio que
    // "discovering" en BluetoothDropdown.qml: solo mientras el popup esta
    // abierto, no tiene sentido dejarlo escaneando de fondo indefinido.
    onVisibleChanged: {
        if (!popup.visible && presence.shown) presence.snapClosed();
        if (popup.wifiDevice) popup.wifiDevice.scannerEnabled = popup.visible;
    }

    anchor.window: popup.panelWindow
    // NO usar mapToItem() aca: es una llamada a funcion, no una property --
    // el binding no vuelve a evaluar cuando el RowLayout de la barra
    // termina de acomodar todo (queda pegado a x=0, la posicion antes de
    // layout). Recorrer la cadena de padres leyendo ".x" en cada uno SI es
    // reactivo (son properties de verdad), y da el mismo resultado para
    // una jerarquia sin rotacion/escala como esta.
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

    readonly property var networks: popup.wifiDevice
        ? popup.wifiDevice.networks.values.slice().sort((a, b) => b.signalStrength - a.signalStrength)
        : []

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
                        text: "Wi-Fi"
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.title
                        font.weight: Tokens.weight.semibold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Switch {
                    checked: Networking.wifiEnabled
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            Rectangle {
                visible: !!(popup.wiredDevice && popup.wiredDevice.connected)
                Layout.fillWidth: true
                implicitHeight: Tokens.row.height
                radius: Tokens.radius.sm
                color: Colors.accentAltContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.space.md
                    anchors.rightMargin: Tokens.space.md
                    spacing: Tokens.gap.inline

                    Icon { name: "lan"; filled: true; color: Colors.textOnAccentAltContainer }
                    Text {
                        text: "Ethernet conectado"
                        color: Colors.textOnAccentAltContainer
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.weight: Tokens.weight.medium
                        Layout.fillWidth: true
                    }
                }
            }

            Repeater {
                model: popup.networks

                ColumnLayout {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Tokens.space.xs

                    property bool needsPsk: false

                    Connections {
                        target: row.modelData
                        function onConnectionFailed(reason) {
                            row.needsPsk = reason === ConnectionFailReason.NoSecrets;
                        }
                    }

                Rectangle {
                    id: netRow
                    readonly property bool selected: row.modelData.connected
                    Layout.fillWidth: true
                    implicitHeight: Tokens.row.height
                    radius: Tokens.radius.sm
                    // Fila seleccionada (conectada / por defecto) en secondary
                    // container (decision C3); el hover lo da la StateLayer.
                    color: netRow.selected ? Colors.accentAltContainer : "transparent"
                    Behavior on color { ColorAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }

                    StateLayer { hovered: netMouse.containsMouse; pressed: netMouse.pressed }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.space.md
                        anchors.rightMargin: Tokens.space.md
                        spacing: Tokens.gap.inline

                        Icon {
                            name: {
                                const s = row.modelData.signalStrength;
                                return s > 0.75 ? "signal_wifi_4_bar" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
                            }
                            filled: netRow.selected
                            color: netRow.selected ? Colors.textOnAccentAltContainer : Colors.text
                        }

                        Text {
                            text: row.modelData.name
                            color: netRow.selected ? Colors.textOnAccentAltContainer : Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: netRow.selected ? Tokens.weight.medium : Tokens.weight.regular
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Icon {
                            visible: netRow.selected
                            name: "check"
                            size: Tokens.icon.sm
                            color: Colors.textOnAccentAltContainer
                        }
                    }

                    MouseArea {
                        id: netMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!row.modelData.connected) row.modelData.connect();
                        }
                    }
                }

                    Rectangle {
                        visible: row.needsPsk
                        Layout.fillWidth: true
                        implicitHeight: Tokens.row.height
                        radius: Tokens.radius.sm
                        color: Colors.surfaceLowest
                        border.color: pskField.activeFocus ? Colors.accent : Colors.border
                        border.width: 1

                        TextInput {
                            id: pskField
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.space.md
                            anchors.rightMargin: Tokens.space.md
                            verticalAlignment: TextInput.AlignVCenter
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            echoMode: TextInput.Password
                            clip: true
                            focus: row.needsPsk
                            onAccepted: {
                                row.modelData.connectWithPsk(pskField.text);
                                row.needsPsk = false;
                            }
                        }

                        Text {
                            visible: pskField.text.length === 0
                            anchors.left: parent.left
                            anchors.leftMargin: Tokens.space.md
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Contraseña, Enter para conectar"
                            color: Colors.textMuted
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                        }
                    }
                }
            }
        }
    }
}
