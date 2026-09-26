// Reemplaza a swaync del todo -- ver Fase C del plan. Reproduce lo que
// daba swaync/config.json: historial de notificaciones + "limpiar todo",
// grid de accesos rapidos (wifi/bluetooth/hyprsunset/lock) y DND (el
// reproductor esta en el media hub de la barra, Fase 4 B5). Una instancia por pantalla (ver shell.qml), toggle global via
// ControlCenterState.qml (bind SUPER+N, ver shell.qml + binds.lua).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Widgets
import Quickshell.Wayland
import ".." // Colors.qml, Tokens.qml, NotificationState.qml, ControlCenterState.qml

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

    property string powerProfile: "balanced"
    Process {
        id: checkPowerProfile
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim()) window.powerProfile = this.text.trim();
            }
        }
    }

    property var nvidiaData: ({ active: false, text: "Reposo (D3cold - 0W)", icon: "memory", processes: [] })
    Process {
        id: checkNvidia
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/nvidia-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    window.nvidiaData = JSON.parse(this.text);
                } catch (e) {}
            }
        }
    }

    function refreshHardware() {
        checkHyprsunset.running = true;
        checkGameMode.running = true;
        checkPowerProfile.running = true;
        checkNvidia.running = true;
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
                    color: Colors.m3onSurface
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
                        contentColor: Colors.m3primary
                    }

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Limpiar todo"
                        color: Colors.m3primary
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
                    onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"])
                }
            }

            // Selector de Perfiles de Rendimiento (power-profiles-daemon).
            // Botones segmentados: el perfil activo en secondary_container (C3).
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.space.xs

                Repeater {
                    model: [
                        { id: "power-saver", label: "Ahorro", icon: "eco" },
                        { id: "balanced", label: "Normal", icon: "balance" },
                        { id: "performance", label: "Rendimiento", icon: "rocket_launch" }
                    ]

                    Rectangle {
                        id: profBtn
                        required property var modelData
                        readonly property bool selected: window.powerProfile === profBtn.modelData.id
                        readonly property color contentColor: profBtn.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                        Layout.fillWidth: true
                        implicitHeight: Tokens.pill.height
                        radius: Tokens.radius.sm
                        color: profBtn.selected ? Colors.m3secondaryContainer : "transparent"
                        border.color: profBtn.selected ? Colors.m3secondaryContainer : Colors.m3outlineVariant
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
                            onClicked: {
                                Quickshell.execDetached(["powerprofilesctl", "set", profBtn.modelData.id]);
                                window.powerProfile = profBtn.modelData.id;
                            }
                        }
                    }
                }
            }

            // Monitor de dGPU NVIDIA RTX 3050. Activa = aviso (tertiary, como
            // el warning de la bateria); en reposo, texto secundario.
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Tokens.row.height
                radius: Tokens.radius.sm
                color: Colors.m3surfaceContainerHigh
                border.color: window.nvidiaData.active ? Colors.m3tertiary : "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.space.md
                    anchors.rightMargin: Tokens.space.md
                    spacing: Tokens.gap.inline

                    // Nombre de icono enviado por nvidia-status.sh (I5).
                    Icon {
                        name: window.nvidiaData.icon || "memory"
                        filled: window.nvidiaData.active
                        size: Tokens.icon.sm
                        color: window.nvidiaData.active ? Colors.m3tertiary : Colors.m3onSurfaceVariant
                    }

                    Text {
                        text: "NVIDIA RTX 3050"
                        color: Colors.m3onSurface
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        font.weight: Tokens.weight.semibold
                    }

                    Text {
                        text: {
                            if (!window.nvidiaData.active) return window.nvidiaData.text || "Reposo (0W)";
                            if (window.nvidiaData.processes && window.nvidiaData.processes.length > 0) {
                                const names = window.nvidiaData.processes.map(p => p.name).join(", ");
                                return "Activa (" + names + ")";
                            }
                            return "Activa";
                        }
                        color: window.nvidiaData.active ? Colors.m3tertiary : Colors.m3onSurfaceVariant
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        horizontalAlignment: Text.AlignRight
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.space.xs

                Text {
                    text: "No molestar"
                    color: Colors.m3onSurface
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
                        color: Colors.m3onSurfaceVariant
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
                            color: Colors.m3surfaceContainerHigh

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
                                        color: Colors.m3onSurface
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
                                                contentColor: Colors.m3onSurfaceVariant
                                            }
                                        }

                                        Icon {
                                            anchors.centerIn: parent
                                            name: "close"
                                            size: Tokens.icon.sm
                                            color: Colors.m3onSurfaceVariant
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
                                    color: Colors.m3onSurfaceVariant
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
