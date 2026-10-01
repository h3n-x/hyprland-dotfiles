// Menu contextual personalizado para items de la bandeja del sistema (Tray)
// Permite abrir, detener la aplicacion en segundo plano o desplegar su menu nativo.
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, PopupState.qml

AnchoredPanel {
    id: popup
    popupId: "tray"
    align: "end"
    padding: Tokens.pad.card

    property var currentItem: null
    property var currentMenuAnchor: null

    readonly property string stopScript: Quickshell.env("HOME") + "/.config/hypr/scripts/tray-stop.sh"

    // Un solo panel para todos los iconos: se ancla al que se toco. Si ya
    // estaba abierto sobre otro icono, se reubica (place recalcula el ancla).
    function openFor(item, modelData, menuAnchor) {
        popup.anchorItem = item;
        popup.currentItem = modelData;
        popup.currentMenuAnchor = menuAnchor;
        if (popup.open) popup.place();
        else PopupState.open(popup.popupId, popup.hostScreenName);
    }
    // El item se limpia al terminar la salida, no al pedir el cierre: el
    // contenido sigue visible mientras anima.
    onActiveChanged: {
        if (popup.active) return;
        popup.currentItem = null;
        popup.currentMenuAnchor = null;
    }

    // Ancho del contenido (la tarjeta suma el margen interior).
    readonly property int contentWidth: Tokens.panel.widthSm - 2 * Tokens.pad.card

    ColumnLayout {
        id: layout
        width: popup.contentWidth
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
                color: Colors.text
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
            color: Colors.divider
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Tokens.row.height
            radius: Tokens.radius.sm
            color: "transparent"

            StateLayer { hovered: openMouse.containsMouse; pressed: openMouse.pressed; contentColor: Colors.text }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.space.md
                anchors.rightMargin: Tokens.space.md
                spacing: Tokens.gap.inline

                Icon { name: "open_in_new"; color: Colors.text }

                Text {
                    text: "Abrir ventana"
                    color: Colors.text
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

            StateLayer { hovered: stopMouse.containsMouse; pressed: stopMouse.pressed; contentColor: Colors.danger }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.space.md
                anchors.rightMargin: Tokens.space.md
                spacing: Tokens.gap.inline

                Icon { name: "stop_circle"; color: Colors.danger }

                Text {
                    text: "Detener aplicación"
                    color: Colors.danger
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

            StateLayer { hovered: nativeMouse.containsMouse; pressed: nativeMouse.pressed; contentColor: Colors.text }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.space.md
                anchors.rightMargin: Tokens.space.md
                spacing: Tokens.gap.inline

                Icon { name: "menu"; color: Colors.text }

                Text {
                    text: "Menú contextual nativo"
                    color: Colors.text
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
                    const item = popup.anchorItem;
                    popup.close();
                    if (!anchor) return;
                    popup.anchorMenu(anchor, item);
                    anchor.open();
                }
            }
        }
    }
}
