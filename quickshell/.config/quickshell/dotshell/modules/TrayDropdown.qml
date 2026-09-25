// Menu contextual personalizado para items de la bandeja del sistema (Tray)
// Permite abrir, detener la aplicacion en segundo plano o desplegar su menu nativo.
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml

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

    implicitWidth: Tokens.panel.widthSm
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

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.space.md
                Layout.rightMargin: Tokens.space.md
                Layout.topMargin: Tokens.space.xs
                Layout.bottomMargin: Tokens.space.xs
                spacing: Tokens.gap.inline

                Image {
                    Layout.preferredWidth: Tokens.icon.sm
                    Layout.preferredHeight: Tokens.icon.sm
                    source: popup.currentItem ? (popup.currentItem.icon || "") : ""
                    smooth: true
                    visible: source !== ""
                }

                Text {
                    text: popup.currentItem ? (popup.currentItem.title || popup.currentItem.id || "Aplicación") : ""
                    color: Colors.m3onSurface
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.title
                    font.weight: Tokens.weight.semibold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.space.xs
                Layout.bottomMargin: Tokens.space.xs
                implicitHeight: 1
                color: Colors.m3outlineVariant
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Tokens.row.height
                radius: Tokens.radius.sm
                color: "transparent"

                StateLayer { hovered: openMouse.containsMouse; pressed: openMouse.pressed; contentColor: Colors.m3onSurface }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.space.md
                    anchors.rightMargin: Tokens.space.md
                    spacing: Tokens.gap.inline

                    Icon { name: "open_in_new"; color: Colors.m3onSurface }

                    Text {
                        text: "Abrir ventana"
                        color: Colors.m3onSurface
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.weight: Tokens.weight.regular
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: openMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (popup.currentItem) popup.currentItem.activate();
                        popup.close();
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Tokens.row.height
                radius: Tokens.radius.sm
                color: "transparent"

                StateLayer { hovered: stopMouse.containsMouse; pressed: stopMouse.pressed; contentColor: Colors.m3error }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.space.md
                    anchors.rightMargin: Tokens.space.md
                    spacing: Tokens.gap.inline

                    Icon { name: "stop_circle"; color: Colors.m3error }

                    Text {
                        text: "Detener aplicación"
                        color: Colors.m3error
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.weight: Tokens.weight.medium
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: stopMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
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
            Rectangle {
                    visible: !!(popup.currentItem && popup.currentItem.hasMenu)
                Layout.fillWidth: true
                implicitHeight: Tokens.row.height
                radius: Tokens.radius.sm
                color: "transparent"

                StateLayer { hovered: nativeMouse.containsMouse; pressed: nativeMouse.pressed; contentColor: Colors.m3onSurface }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.space.md
                    anchors.rightMargin: Tokens.space.md
                    spacing: Tokens.gap.inline

                    Icon { name: "menu"; color: Colors.m3onSurface }

                    Text {
                        text: "Menú contextual nativo"
                        color: Colors.m3onSurface
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.weight: Tokens.weight.regular
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: nativeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
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
