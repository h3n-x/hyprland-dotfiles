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

AnchoredPanel {
    id: popup
    popupId: "network"
    align: "end"
    padding: Tokens.pad.card
    heightCap: 420
    readonly property var wifiDevice: NetworkState.wifiDevice
    readonly property var wiredDevice: NetworkState.wiredDevice

    // Ancho del contenido (la tarjeta suma el margen interior).
    readonly property int contentWidth: Tokens.panel.widthMd - 2 * Tokens.pad.card

    // Sin esto la lista de redes solo mostraba la ya conectada -- el
    // dispositivo no escanea activamente por si solo. Igual criterio que
    // "discovering" en BluetoothDropdown.qml: solo mientras el popup esta
    // abierto, no tiene sentido dejarlo escaneando de fondo indefinido.
    onActiveChanged: {
        if (popup.wifiDevice) popup.wifiDevice.scannerEnabled = popup.active;
        if (!popup.active) popup.showAll = false;
    }

    // Lista de redes (Fase 8 B5, D6). Antes se reordenaban todos los puntos
    // de acceso (decenas, con el mismo nombre repetido) en cada cambio de
    // senal y el Repeater recreaba todas las filas: 30-40 % de CPU con el
    // panel abierto. Ahora: como mucho una actualizacion cada 2 s y solo con
    // el panel a la vista; una fila por nombre (la mas fuerte), la conectada
    // primero; las 12 mas fuertes y "Más redes" para el resto. Las filas se
    // identifican por nombre: se mueven, entran o salen, no se recrean (el
    // campo de contraseña sobrevive a un reordenamiento).
    readonly property int shownLimit: 12
    property bool showAll: false
    // nombre -> red de Quickshell (la mas fuerte con ese nombre).
    property var netByName: ({})
    property int totalNetworks: 0

    function refreshNetworks(): void {
        const best = {};
        for (const n of popup.wifiDevice ? popup.wifiDevice.networks.values : []) {
            if (!n.name) continue; // redes ocultas: sin nombre que mostrar
            const b = best[n.name];
            if (!b || (n.connected && !b.connected) || (n.connected === b.connected && n.signalStrength > b.signalStrength)) best[n.name] = n;
        }
        const names = Object.keys(best).sort((a, b) => (best[b].connected - best[a].connected) || (best[b].signalStrength - best[a].signalStrength));
        popup.totalNetworks = names.length;
        const shown = popup.showAll ? names : names.slice(0, popup.shownLimit);
        popup.netByName = best;
        // Sincronizar el modelo en el lugar: mover o insertar lo que cambio y
        // quitar lo que sobra.
        for (let i = 0; i < shown.length; i++) {
            if (i < netModel.count && netModel.get(i).name === shown[i]) continue;
            let j = i + 1;
            while (j < netModel.count && netModel.get(j).name !== shown[i]) j++;
            if (j < netModel.count) netModel.move(j, i, 1);
            else netModel.insert(i, { name: shown[i] });
        }
        if (netModel.count > shown.length) netModel.remove(shown.length, netModel.count - shown.length);
    }
    onShowAllChanged: popup.refreshNetworks()

    ListModel { id: netModel }
    Timer {
        interval: 2000
        repeat: true
        running: popup.active
        triggeredOnStart: true
        onTriggered: popup.refreshNetworks()
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
            model: netModel

            ColumnLayout {
                id: row
                required property string name
                // null si la red desaparecio entre dos actualizaciones.
                readonly property var net: popup.netByName[row.name] ?? null
                Layout.fillWidth: true
                spacing: Tokens.space.xs

                property bool needsPsk: false

                Connections {
                    target: row.net
                    function onConnectionFailed(reason) {
                        row.needsPsk = reason === ConnectionFailReason.NoSecrets;
                    }
                }

            Rectangle {
                id: netRow
                readonly property bool selected: !!row.net && row.net.connected
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
                            const s = row.net ? row.net.signalStrength : 0;
                            return s > 0.75 ? "signal_wifi_4_bar" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
                        }
                        filled: netRow.selected
                        color: netRow.selected ? Colors.textOnAccentAltContainer : Colors.text
                    }

                    Text {
                        text: row.name
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
                        if (row.net && !row.net.connected) row.net.connect();
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
                            if (row.net) row.net.connectWithPsk(pskField.text);
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

        // "Más redes": el resto de la lista (las mas debiles); se pliega al cerrar.
        Rectangle {
            visible: popup.totalNetworks > popup.shownLimit
            Layout.fillWidth: true
            implicitHeight: Tokens.row.height
            radius: Tokens.radius.sm
            color: "transparent"

            StateLayer { hovered: moreMouse.containsMouse; pressed: moreMouse.pressed }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.space.md
                anchors.rightMargin: Tokens.space.md
                spacing: Tokens.gap.inline

                Icon {
                    name: popup.showAll ? "expand_less" : "expand_more"
                    color: Colors.textMuted
                }
                Text {
                    text: popup.showAll ? "Menos redes" : "Más redes (" + (popup.totalNetworks - popup.shownLimit) + ")"
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: moreMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: popup.showAll = !popup.showAll
            }
        }
    }
}
