// Reemplaza a swaync del todo -- ver Fase C del plan. Reproduce lo que
// daba swaync/config.json: historial de notificaciones + "limpiar todo" y
// los ajustes rapidos (el reproductor y el estado del equipo, incluida la
// dGPU, estan en el dashboard, Fase 4 B7). Una instancia por pantalla (ver
// shell.qml), toggle global via ControlCenterState.qml (bind SUPER+N, ver
// shell.qml + binds.lua).
//
// Ajustes rapidos (Fase 11 B6): el lugar unico de los ajustes rapidos. Son
// datos (controlCenter.tiles) que dibuja y edita TileGrid; cada accion es de
// QuickTiles. El lapiz aparece al pasar el raton por los ajustes (como en
// Inicio); mientras se edita, el panel toma el teclado (sin editar, nunca).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import ".." // Colors.qml, Tokens.qml, NotificationState.qml, ControlCenterState.qml, QuickTiles.qml

PanelWindow {
    id: window

    // Junto al extremo final de la barra (Fase 11 B3): arriba a la derecha con
    // la barra arriba (como siempre), abajo a la derecha con la barra abajo,
    // arriba a la izquierda con la barra a la izquierda. Del lado de la barra
    // deja su reserva (Tokens.inset*), igual que el OSD y los avisos. La
    // ventana suma el margen de la sombra alrededor de la tarjeta, asi que se
    // corre ese margen hacia afuera y solo acepta input sobre la tarjeta.
    anchors {
        top: Tokens.bar.edge !== "bottom"
        bottom: Tokens.bar.edge === "bottom"
        right: Tokens.bar.edge !== "left"
        left: Tokens.bar.edge === "left"
    }
    WlrLayershell.namespace: "quickshell-panel"
    // Superficie invocada (Fase 8 B6): capa Overlay, por encima de una ventana en
    // pantalla completa (ver FullscreenState).
    WlrLayershell.layer: WlrLayer.Overlay
    // Pegado al marco (Fase 13 B2, estilo Marco): en la esquina, al ras de la
    // barra y del lado fino, con dos orejas (CornerEars); sin sombra.
    readonly property bool attached: Tokens.frame.on
    function edgeGap(side: string): int {
        return side === Tokens.bar.edge ? Tokens.bar.height : Tokens.frame.thickness;
    }
    margins {
        top: window.attached ? window.edgeGap("top") : Tokens.insetTop - card.shadowMargin
        bottom: window.attached ? window.edgeGap("bottom") : Tokens.insetBottom - card.shadowMargin
        right: window.attached ? window.edgeGap("right") : Tokens.insetRight - card.shadowMargin
        left: window.attached ? window.edgeGap("left") : Tokens.insetLeft - card.shadowMargin
    }
    implicitWidth: Tokens.panel.widthLg + (window.attached ? ears.extra : card.shadowMargin * 2)
    implicitHeight: Math.min(Tokens.px(600), card.implicitHeight) + (window.attached ? ears.extra : card.shadowMargin * 2)
    color: "transparent"
    mask: Region { item: card }
    exclusionMode: ExclusionMode.Ignore
    // El teclado solo mientras se editan los ajustes rapidos (TileGrid).
    WlrLayershell.keyboardFocus: ControlCenterState.editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // Apertura/cierre animados (P2.5): la ventana queda mapeada mientras el
    // contenido anima la salida.
    Presence { id: presence; open: ControlCenterState.visible }
    visible: presence.shown

    // Lo que hay que preguntar al sistema (modo juego, que existe) se pregunta al abrir.
    onVisibleChanged: if (window.visible) QuickTiles.refresh()

    // Nivel de elevacion 2 (surface_container translucida sobre blur, sombra sm),
    // igual que los desplegables. Padding 16 = radio lg: los hijos no necesitan
    // radio anidado (Q1).
    CornerEars {
        id: ears
        on: window.attached
        cardW: card.width
        cardH: card.height
        reveal: presence.progress
    }

    Surface {
        id: card
        x: window.attached ? ears.cardX : card.shadowMargin
        y: window.attached ? ears.cardY : card.shadowMargin
        width: Tokens.panel.widthLg
        implicitHeight: layout.implicitHeight + Tokens.pad.panel * 2
        level: 2
        translucent: true
        framed: window.attached
        radius: Tokens.radius.lg
        // Pegado: solo la esquina de afuera es redonda.
        topLeftRadius: window.attached && ears.free !== "tl" ? 0 : Tokens.radius.lg
        topRightRadius: window.attached && ears.free !== "tr" ? 0 : Tokens.radius.lg
        bottomLeftRadius: window.attached && ears.free !== "bl" ? 0 : Tokens.radius.lg
        bottomRightRadius: window.attached && ears.free !== "br" ? 0 : Tokens.radius.lg
        // Entrada/salida: sube space.sm hacia la barra y crece desde su esquina.
        // Pegado: sale del borde de la barra (recortada por la ventana).
        opacity: window.attached ? 1 : presence.progress
        scale: window.attached ? 1 : presence.contentScale
        transformOrigin: Item.TopRight
        readonly property real hidden: 1 - presence.progress
        transform: Translate {
            x: !window.attached ? 0 : Tokens.bar.edge === "left" ? -card.hidden * card.width : Tokens.bar.edge === "right" ? card.hidden * card.width : 0
            y: !window.attached ? presence.offsetY : Tokens.bar.edge === "top" ? -card.hidden * card.height : Tokens.bar.edge === "bottom" ? card.hidden * card.height : 0
        }

        // Editando: las teclas son del editor (Esc termina sin cerrar el panel).
        Item {
            id: editKeys
            Keys.onPressed: (event) => {
                if (ControlCenterState.editing && tiles.handleKey(event)) event.accepted = true;
            }
            Connections {
                target: ControlCenterState
                function onEditingChanged() { if (ControlCenterState.editing) editKeys.forceActiveFocus(); }
            }
        }

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: Tokens.pad.panel
            spacing: Tokens.space.md

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Notificaciones"
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.title
                    font.weight: Tokens.weight.semibold
                    Layout.fillWidth: true
                }

                // Boton de texto M3 (primary, sin contenedor).
                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + Tokens.pad.pillH * 2
                    implicitHeight: Tokens.pill.height
                    radius: Tokens.radius.pill(height)
                    color: "transparent"

                    StateLayer {
                        hovered: clearMouse.containsMouse
                        pressed: clearMouse.pressed
                        contentColor: Colors.accent
                    }

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Limpiar todo"
                        color: Colors.accent
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        font.weight: Tokens.weight.medium
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationState.clearAll()
                    }
                }

                // Centro de configuracion (Fase 10 B1): accion directa; el
                // panel se cierra para dejar ver la ventana.
                Rectangle {
                    implicitWidth: Tokens.pill.height
                    implicitHeight: Tokens.pill.height
                    radius: Tokens.radius.pill(height)
                    color: "transparent"

                    StateLayer {
                        hovered: settingsMouse.containsMouse
                        pressed: settingsMouse.pressed
                    }
                    Icon {
                        anchors.centerIn: parent
                        name: "settings"
                        size: Tokens.icon.md
                        color: Colors.textMuted
                    }
                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ControlCenterState.visible = false;
                            Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/settings-ui"]);
                        }
                    }
                }
            }

            // Ajustes rapidos (Fase 11 B6): la lista del almacen y su editor.
            TileGrid {
                id: tiles
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
            }
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Tokens.px(300), historyList.implicitHeight)
                contentWidth: width
                contentHeight: historyList.implicitHeight
                clip: true

                ColumnLayout {
                    id: historyList
                    width: parent.width
                    spacing: Tokens.space.sm

                    Text {
                        visible: NotificationState.server.trackedNotifications.values.length === 0
                        Layout.leftMargin: Tokens.space.xs
                        text: "Sin notificaciones"
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                    }

                    Repeater {
                        model: NotificationState.server.trackedNotifications.values

                        Rectangle {
                            id: histItem
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: histContent.implicitHeight + Tokens.space.md * 2
                            radius: Tokens.radius.md
                            color: Colors.surfaceHigh

                            ColumnLayout {
                                id: histContent
                                anchors.fill: parent
                                anchors.margins: Tokens.space.md
                                spacing: Tokens.space.xs

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.gap.inline

                                    Text {
                                        text: histItem.modelData.summary
                                        color: Colors.text
                                        font.family: Tokens.font.ui
                                        font.pixelSize: Tokens.type.body
                                        font.weight: Tokens.weight.semibold
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Boton de icono circular para descartar.
                                    Item {
                                        implicitWidth: Tokens.icon.lg
                                        implicitHeight: Tokens.icon.lg

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Tokens.radius.pill(height)
                                            color: "transparent"

                                            StateLayer {
                                                hovered: dismissMouse.containsMouse
                                                pressed: dismissMouse.pressed
                                                contentColor: Colors.textMuted
                                            }
                                        }

                                        Icon {
                                            anchors.centerIn: parent
                                            name: "close"
                                            size: Tokens.icon.sm
                                            color: Colors.textMuted
                                        }

                                        MouseArea {
                                            id: dismissMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: histItem.modelData.dismiss()
                                        }
                                    }
                                }

                                Text {
                                    visible: !!histItem.modelData.body
                                    text: histItem.modelData.body
                                    color: Colors.textMuted
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.label
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
