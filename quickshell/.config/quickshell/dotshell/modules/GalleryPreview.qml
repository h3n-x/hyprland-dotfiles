// Columna derecha de la galeria de wallpapers (Fase 3 B3, P3.2): vista previa
// del wallpaper seleccionado con un mini escritorio pintado con SU paleta
// (la de la cache de wallpaper-cache.sh, modo oscuro) y muestras de color.
// Todo en memoria: no escribe ningun archivo de tema. La vista previa en vivo
// de la shell real llega en B7.
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml

ColumnLayout {
    id: root

    property string name: ""
    property string thumb: ""
    // Mapa rol -> {dark, light} de palettes.json (null si todavia no hay paleta).
    property var colors: null
    property bool isCurrent: false
    property bool isFavorite: false

    signal applyRequested()
    signal favoriteToggled()

    // Rol de la paleta candidata (modo oscuro); gris neutro mientras no hay.
    function c(role: string): color {
        return root.colors && root.colors[role] ? root.colors[role].dark : Colors.m3surfaceContainerHighest;
    }

    spacing: Tokens.space.md

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space.sm

        Text {
            Layout.fillWidth: true
            text: root.name
            elide: Text.ElideMiddle
            color: Colors.m3onSurface
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.title
            font.weight: Tokens.weight.semibold
        }

        // Aplicado ahora.
        Rectangle {
            visible: root.isCurrent
            implicitHeight: Tokens.pill.height - Tokens.space.sm
            implicitWidth: currentRow.implicitWidth + Tokens.space.md
            radius: Tokens.radius.pill(height)
            color: Colors.m3secondaryContainer
            Row {
                id: currentRow
                anchors.centerIn: parent
                spacing: Tokens.space.hair
                Icon { name: "check"; size: Tokens.icon.sm; color: Colors.m3onSecondaryContainer }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Actual"
                    color: Colors.m3onSecondaryContainer
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                    font.weight: Tokens.weight.semibold
                }
            }
        }
    }

    // Vista previa 16:9 con el mini escritorio encima.
    ClippingRectangle {
        id: preview
        Layout.fillWidth: true
        implicitHeight: Math.round(width * 9 / 16)
        radius: Tokens.radius.md
        color: Colors.m3surfaceContainerHighest

        Image {
            anchors.fill: parent
            source: root.thumb ? "file://" + root.thumb : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(480, 270)
        }

        // Mini escritorio: barra, reloj y un panel con toggles y filas, con los
        // roles que usa la shell real.
        Item {
            id: mini
            anchors.fill: parent
            anchors.margins: Tokens.space.sm
            readonly property real u: preview.width / 360   // escala del dibujo

            Rectangle { // workspaces
                width: 56 * mini.u; height: 12 * mini.u; radius: height / 2
                color: root.c("surface_container_low")
                Row {
                    anchors.centerIn: parent
                    spacing: 4 * mini.u
                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index
                            width: 6 * mini.u; height: width; radius: width / 2
                            color: index === 0 ? root.c("primary") : root.c("on_surface_variant")
                        }
                    }
                }
            }
            Rectangle { // reloj
                anchors.horizontalCenter: parent.horizontalCenter
                width: 38 * mini.u; height: 12 * mini.u; radius: height / 2
                color: root.c("surface_container_low")
                Text {
                    anchors.centerIn: parent
                    text: "12:00"
                    color: root.c("on_surface")
                    font.family: Tokens.font.ui
                    font.pixelSize: Math.max(6, 7 * mini.u)
                    font.weight: Tokens.weight.semibold
                }
            }
            Rectangle { // panel
                anchors { right: parent.right; top: parent.top; topMargin: 18 * mini.u }
                width: parent.width * 0.38; height: parent.height * 0.66
                radius: 8 * mini.u
                color: root.c("surface_container")
                border.color: root.c("outline_variant")
                Column {
                    x: 6 * mini.u; y: 6 * mini.u
                    width: parent.width - 12 * mini.u
                    spacing: 4 * mini.u
                    Row {
                        spacing: 4 * mini.u
                        Repeater {
                            model: 4
                            Rectangle {
                                required property int index
                                width: (mini.width * 0.38 - 24 * mini.u) / 4
                                height: 12 * mini.u
                                radius: 4 * mini.u
                                color: index < 2 ? root.c("primary_container") : root.c("surface_container_highest")
                            }
                        }
                    }
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            width: parent.width
                            height: 14 * mini.u
                            radius: 4 * mini.u
                            color: index === 0 ? root.c("secondary_container") : root.c("surface_container_high")
                        }
                    }
                }
            }
        }
    }

    // Muestras de la paleta candidata.
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space.sm
        Repeater {
            model: [["primary", "Primario"], ["secondary", "Secundario"], ["tertiary", "Terciario"],
                    ["primary_container", "Contenedor"], ["surface_container", "Superficie"]]
            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Tokens.space.hair
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Tokens.pill.height
                    radius: Tokens.radius.sm
                    color: root.c(parent.modelData[0])
                    border.color: Colors.m3outlineVariant
                }
                Text {
                    Layout.fillWidth: true
                    text: parent.modelData[1]
                    elide: Text.ElideRight
                    color: Colors.m3onSurfaceVariant
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                }
            }
        }
    }

    Item { Layout.fillHeight: true }

    // Acciones.
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space.sm

        // Favorito (boton de icono).
        Rectangle {
            implicitWidth: Tokens.row.height
            implicitHeight: Tokens.row.height
            radius: Tokens.radius.pill(height)
            color: "transparent"
            border.color: Colors.m3outlineVariant
            StateLayer { hovered: favMouse.containsMouse; pressed: favMouse.pressed }
            Icon {
                anchors.centerIn: parent
                name: "favorite"
                filled: root.isFavorite
                color: root.isFavorite ? Colors.m3primary : Colors.m3onSurfaceVariant
            }
            MouseArea {
                id: favMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.favoriteToggled()
            }
        }

        // Aplicar (boton lleno primary).
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Tokens.row.height
            radius: Tokens.radius.pill(height)
            color: Colors.m3primary
            StateLayer { hovered: applyMouse.containsMouse; pressed: applyMouse.pressed; contentColor: Colors.m3onPrimary }
            Row {
                anchors.centerIn: parent
                spacing: Tokens.space.sm
                Icon { name: "wallpaper"; filled: true; color: Colors.m3onPrimary }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Aplicar"
                    color: Colors.m3onPrimary
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                    font.weight: Tokens.weight.semibold
                }
            }
            MouseArea {
                id: applyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.applyRequested()
            }
        }
    }
}
