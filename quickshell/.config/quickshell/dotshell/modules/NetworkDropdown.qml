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
import ".." // Colors.qml

PopupWindow {
    id: popup
    required property var anchorItem
    required property var panelWindow
    property var wifiDevice
    property var wiredDevice

    function toggle() {
        popup.visible = !popup.visible;
    }

    implicitWidth: 300
    implicitHeight: Math.min(420, card.implicitHeight)
    color: "transparent"
    grabFocus: true

    // Sin esto la lista de redes solo mostraba la ya conectada -- el
    // dispositivo no escanea activamente por si solo. Igual criterio que
    // "discovering" en BluetoothDropdown.qml: solo mientras el popup esta
    // abierto, no tiene sentido dejarlo escaneando de fondo indefinido.
    // Sin esto la lista de redes solo mostraba la ya conectada -- el
    // dispositivo no escanea activamente por si solo. Igual criterio que
    // "discovering" en BluetoothDropdown.qml: solo mientras el popup esta
    // abierto, no tiene sentido dejarlo escaneando de fondo indefinido.
    onVisibleChanged: {
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
        return Math.max(0, x - popup.implicitWidth + popup.anchorItem.width);
    }
    anchor.rect.y: popup.panelWindow ? popup.panelWindow.height : 0

    readonly property var networks: popup.wifiDevice
        ? popup.wifiDevice.networks.values.slice().sort((a, b) => b.signalStrength - a.signalStrength)
        : []

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
                    text: "Wi-Fi"
                    color: Colors.fg
                    font.pixelSize: 14
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 36
                    height: 20
                    radius: 10
                    color: Networking.wifiEnabled ? Colors.accent : Colors.bg3

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: Colors.bg0
                        anchors.verticalCenter: parent.verticalCenter
                        x: Networking.wifiEnabled ? parent.width - width - 2 : 2
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

            Text {
                visible: !!(popup.wiredDevice && popup.wiredDevice.connected)
                text: "󰈀  Ethernet conectado"
                color: Colors.fg
                font.pixelSize: 13
            }

            Repeater {
                model: popup.networks

                ColumnLayout {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 4

                    property bool needsPsk: false

                    Connections {
                        target: row.modelData
                        function onConnectionFailed(reason) {
                            row.needsPsk = reason === ConnectionFailReason.NoSecrets;
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8
                        color: netMouse.containsMouse ? Colors.hoverBg : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            Text {
                                text: {
                                    const s = row.modelData.signalStrength;
                                    return s > 0.75 ? "󰤨" : s > 0.5 ? "󰤥" : s > 0.25 ? "󰤢" : "󰤟";
                                }
                                color: row.modelData.connected ? Colors.accent : Colors.fg
                                font.pixelSize: 14
                            }

                            Text {
                                text: row.modelData.name
                                color: row.modelData.connected ? Colors.accent : Colors.fg
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: row.modelData.connected
                                text: "󰄬"
                                color: Colors.accent
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            id: netMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (!row.modelData.connected) row.modelData.connect();
                            }
                        }
                    }

                    Rectangle {
                        visible: row.needsPsk
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 6
                        color: Colors.bg0
                        border.color: Colors.br
                        border.width: 1

                        TextInput {
                            id: pskField
                            anchors.fill: parent
                            anchors.margins: 6
                            color: Colors.fg
                            font.pixelSize: 13
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
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Contraseña, Enter para conectar"
                            color: Colors.br
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
