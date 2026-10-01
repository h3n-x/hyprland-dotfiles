// Reemplaza a swaync del todo -- ver Fase C del plan. Reproduce lo que
// daba swaync/config.json: historial de notificaciones + "limpiar todo",
// grid de accesos rapidos (wifi/bluetooth/hyprsunset/lock) y DND (el
// reproductor y el estado del equipo, incluida la dGPU, estan en el
// dashboard, Fase 4 B7). Una instancia por pantalla (ver shell.qml), toggle global via
// ControlCenterState.qml (bind SUPER+N, ver shell.qml + binds.lua).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Widgets
import Quickshell.Wayland
import ".." // Colors.qml, Tokens.qml, NotificationState.qml, ControlCenterState.qml, PowerProfileState.qml

PanelWindow {
    id: window

    anchors {
        top: true
        right: true
    }
    // Debajo de la barra (popupTop = margen + alto de la barra + md) y
    // alineado con su borde derecho; mismo valor que Osd.qml y los toasts. La
    // ventana suma el margen de la sombra alrededor de la tarjeta, asi que se
    // corre ese margen hacia afuera y solo acepta input sobre la tarjeta.
    WlrLayershell.namespace: "quickshell-panel"
    // Superficie invocada (Fase 8 B6): capa Overlay, por encima de una ventana en
    // pantalla completa (ver FullscreenState).
    WlrLayershell.layer: WlrLayer.Overlay
    margins {
        top: Tokens.popupTop - card.shadowMargin
        right: Tokens.screenEdge - card.shadowMargin
    }
    implicitWidth: Tokens.panel.widthLg + card.shadowMargin * 2
    implicitHeight: Math.min(600, card.implicitHeight) + card.shadowMargin * 2
    color: "transparent"
    mask: Region { item: card }
    exclusionMode: ExclusionMode.Ignore
    // Apertura/cierre animados (P2.5): la ventana queda mapeada mientras el
    // contenido anima la salida.
    Presence { id: presence; open: ControlCenterState.visible }
    visible: presence.shown

    // Estado y procesos de hardware
    property bool hyprsunsetActive: false
    Process {
        id: checkHyprsunset
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: (code) => window.hyprsunsetActive = (code === 0)
    }

    property bool gameModeActive: false
    Process {
        id: checkGameMode
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/game-mode.sh", "status"]
        onExited: (code) => window.gameModeActive = (code === 0)
    }

    Timer {
        id: gameModeTimer
        interval: 350
        onTriggered: checkGameMode.running = true
    }


    function refreshHardware() {
        checkHyprsunset.running = true;
        checkGameMode.running = true;
        PowerProfileState.refresh();
    }

    onVisibleChanged: if (window.visible) window.refreshHardware()

    // Nivel de elevacion 2 (surface_container translucida sobre blur, sombra sm),
    // igual que los desplegables. Padding 16 = radio lg: los hijos no necesitan
    // radio anidado (Q1).
    Surface {
        id: card
        x: card.shadowMargin
        y: card.shadowMargin
        width: Tokens.panel.widthLg
        implicitHeight: layout.implicitHeight + Tokens.pad.panel * 2
        level: 2
        translucent: true
        radius: Tokens.radius.lg
        // Entrada/salida: sube space.sm hacia la barra y crece desde su esquina.
        opacity: presence.progress
        scale: presence.contentScale
        transformOrigin: Item.TopRight
        transform: Translate { y: presence.offsetY }

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
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 5
                columnSpacing: Tokens.space.sm
                rowSpacing: Tokens.space.sm

                QuickToggle {
                    icon: "wifi"
                    active: Networking.wifiEnabled
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
                QuickToggle {
                    icon: "bluetooth"
                    active: !!(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
                    onClicked: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                }
                QuickToggle {
                    icon: "nightlight"
                    active: window.hyprsunsetActive
                    onClicked: {
                        Quickshell.execDetached(["sh", "-c", "pgrep -x hyprsunset >/dev/null && pkill hyprsunset || (hyprsunset &)"]);
                        checkHyprsunset.running = true;
                    }
                }
                QuickToggle {
                    icon: "sports_esports"
                    active: window.gameModeActive
                    onClicked: {
                        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/game-mode.sh", "toggle"]);
                        gameModeTimer.restart();
                    }
                }
                QuickToggle {
                    icon: "lock"
                    active: false
                    onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/lock", "--user"])
                }
            }

            // Selector de Perfiles de Rendimiento (power-profiles-daemon).
            // Botones segmentados: el perfil activo en secondary_container (C3).
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.space.xs

                Repeater {
                    model: PowerProfileState.profiles

                    Rectangle {
                        id: profBtn
                        required property var modelData
                        readonly property bool selected: PowerProfileState.current === profBtn.modelData.id
                        readonly property color contentColor: profBtn.selected ? Colors.textOnAccentAltContainer : Colors.textMuted
                        Layout.fillWidth: true
                        implicitHeight: Tokens.pill.height
                        radius: Tokens.radius.sm
                        color: profBtn.selected ? Colors.accentAltContainer : "transparent"
                        border.color: profBtn.selected ? Colors.accentAltContainer : Colors.divider
                        Behavior on color { ColorAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
                        Behavior on border.color { ColorAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
                        border.width: 1

                        StateLayer {
                            hovered: profMouse.containsMouse
                            pressed: profMouse.pressed
                            contentColor: profBtn.contentColor
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Tokens.space.xs

                            Icon {
                                name: profBtn.modelData.icon
                                filled: profBtn.selected
                                size: Tokens.icon.sm
                                color: profBtn.contentColor
                            }

                            Text {
                                text: profBtn.modelData.label
                                color: profBtn.contentColor
                                font.family: Tokens.font.ui
                                font.pixelSize: Tokens.type.label
                                font.weight: profBtn.selected ? Tokens.weight.semibold : Tokens.weight.regular
                            }
                        }

                        MouseArea {
                            id: profMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerProfileState.set(profBtn.modelData.id)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.space.xs

                Text {
                    text: "No molestar"
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                    Layout.fillWidth: true
                }

                Switch {
                    checked: NotificationState.doNotDisturb
                    onToggled: NotificationState.doNotDisturb = !NotificationState.doNotDisturb
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(300, historyList.implicitHeight)
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
