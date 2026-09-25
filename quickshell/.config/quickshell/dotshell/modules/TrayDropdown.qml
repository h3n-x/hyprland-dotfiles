// Menu contextual personalizado para items de la bandeja del sistema (Tray)
// Permite abrir, detener la aplicacion en segundo plano o desplegar su menu nativo.
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml

PopupWindow {
    id: popup
    property var anchorItem: null
    required property var panelWindow

    property var currentItem: null
    property var currentMenuAnchor: null

    readonly property string stopScript: Quickshell.env("HOME") + "/.config/hypr/scripts/tray-stop.sh"

    function openFor(item, modelData, menuAnchor) {
        popup.anchorItem = item;
        popup.currentItem = modelData;
        popup.currentMenuAnchor = menuAnchor;
        popup.visible = true;
    }

    function close() {
        popup.visible = false;
        popup.currentItem = null;
        popup.currentMenuAnchor = null;
    }

    implicitWidth: 220
    implicitHeight: card.implicitHeight
    color: "transparent"
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
        return Math.max(0, x - popup.implicitWidth + popup.anchorItem.width);
    }
    anchor.rect.y: popup.panelWindow ? popup.panelWindow.height : 0

    Rectangle {
        id: card
        width: popup.implicitWidth
        implicitHeight: layout.implicitHeight + 20
        radius: 14
        color: Colors.bg1
        border.color: Colors.br
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // Cabecera con icono y nombre de la app
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Image {
                    width: 18
                    height: 18
                    source: popup.currentItem ? (popup.currentItem.icon || "") : ""
                    smooth: true
                    visible: source !== ""
                }

                Text {
                    text: popup.currentItem ? (popup.currentItem.title || popup.currentItem.id || "Aplicación") : ""
                    color: Colors.fg
                    font.pixelSize: 13
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.br
            }

            // Opcion 1: Abrir ventana
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 8
                color: openMouse.containsMouse ? Colors.hoverBg : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    Text {
                        text: "󰅍"
                        color: Colors.fg
                        font.pixelSize: 14
                    }

                    Text {
                        text: "Abrir ventana"
                        color: Colors.fg
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: openMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (popup.currentItem) popup.currentItem.activate();
                        popup.close();
                    }
                }
            }

            // Opcion 2: Detener aplicacion
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 8
                color: stopMouse.containsMouse ? Colors.hoverBg : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    Text {
                        text: "󰓛"
                        color: Colors.critical
                        font.pixelSize: 14
                    }

                    Text {
                        text: "Detener aplicación"
                        color: Colors.critical
                        font.pixelSize: 12
                        font.bold: true
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: stopMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (popup.currentItem) {
                            const id = popup.currentItem.id || "";
                            const title = popup.currentItem.title || id;
                            Quickshell.execDetached([popup.stopScript, id, title]);
                        }
                        popup.close();
                    }
                }
            }

            // Opcion 3: Menu nativo (si la app provee uno)
            Rectangle {
                visible: popup.currentItem && popup.currentItem.hasMenu
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 8
                color: nativeMouse.containsMouse ? Colors.hoverBg : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    Text {
                        text: "󰍜"
                        color: Colors.fg
                        font.pixelSize: 14
                    }

                    Text {
                        text: "Menú contextual nativo"
                        color: Colors.fg
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: nativeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        const anchor = popup.currentMenuAnchor;
                        popup.close();
                        if (anchor) anchor.open();
                    }
                }
            }
        }
    }
}
