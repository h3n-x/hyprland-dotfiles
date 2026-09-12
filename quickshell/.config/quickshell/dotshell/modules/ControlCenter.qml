// Reemplaza a swaync del todo -- ver Fase C del plan. Reproduce lo que
// daba swaync/config.json: historial de notificaciones + "limpiar todo",
// grid de accesos rapidos (wifi/bluetooth/hyprsunset/lock), DND, widget de
// mpris. Una instancia por pantalla (ver shell.qml), toggle global via
// ControlCenterState.qml (bind SUPER+N, ver shell.qml + binds.lua).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Widgets
import ".." // Colors.qml, NotificationState.qml, ControlCenterState.qml

PanelWindow {
    id: window

    anchors {
        top: true
        right: true
    }
    // top: 60, no 10 -- la barra ocupa hasta y=44 (margin 6 + alto 38),
    // con 10 quedaba solapado encima de ella en vez de debajo (mismo
    // valor que usa Osd.qml por el mismo motivo).
    margins {
        top: 60
        right: 10
    }
    implicitWidth: 360
    implicitHeight: Math.min(600, card.implicitHeight)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: ControlCenterState.visible

    // hyprsunset no tiene servicio nativo en Quickshell -- se chequea con
    // pgrep cada vez que se abre el panel (no hace falta polling continuo
    // de fondo, con esto alcanza).
    property bool hyprsunsetActive: false
    Process {
        id: checkHyprsunset
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: (code) => window.hyprsunsetActive = (code === 0)
    }
    onVisibleChanged: if (window.visible) checkHyprsunset.running = true

    Rectangle {
        id: card
        width: window.implicitWidth
        implicitHeight: layout.implicitHeight + 28
        radius: 18
        color: Colors.bg1
        border.color: Colors.br
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Notificaciones"
                    color: Colors.fg
                    font.pixelSize: 15
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + 16
                    implicitHeight: 26
                    radius: 8
                    color: clearMouse.containsMouse ? Colors.hoverBg : "transparent"

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Limpiar todo"
                        color: Colors.fg
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: NotificationState.clearAll()
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 8
                rowSpacing: 8

                QuickToggle {
                    icon: "󰖩"
                    active: Networking.wifiEnabled
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
                QuickToggle {
                    icon: "󰂯"
                    active: !!(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
                    onClicked: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                }
                QuickToggle {
                    icon: "󰛨"
                    active: window.hyprsunsetActive
                    onClicked: {
                        Quickshell.execDetached(["sh", "-c", "pgrep -x hyprsunset >/dev/null && pkill hyprsunset || (hyprsunset &)"]);
                        checkHyprsunset.running = true;
                    }
                }
                QuickToggle {
                    icon: "󰌾"
                    active: false
                    onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"])
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "No molestar"
                    color: Colors.fg
                    font.pixelSize: 13
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 36
                    height: 20
                    radius: 10
                    color: NotificationState.doNotDisturb ? Colors.accent : Colors.bg3

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: Colors.bg0
                        anchors.verticalCenter: parent.verticalCenter
                        x: NotificationState.doNotDisturb ? parent.width - width - 2 : 2
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: NotificationState.doNotDisturb = !NotificationState.doNotDisturb
                    }
                }
            }

            Mpris {
                Layout.alignment: Qt.AlignHCenter
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
                    spacing: 6

                    Text {
                        visible: NotificationState.server.trackedNotifications.values.length === 0
                        text: "Sin notificaciones"
                        color: Colors.br
                        font.pixelSize: 13
                    }

                    Repeater {
                        model: NotificationState.server.trackedNotifications.values

                        Rectangle {
                            id: histItem
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: histContent.implicitHeight + 16
                            radius: 10
                            color: Colors.bg2

                            ColumnLayout {
                                id: histContent
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: histItem.modelData.summary
                                        color: Colors.fg
                                        font.pixelSize: 13
                                        font.bold: true
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "✕"
                                        color: Colors.br
                                        font.pixelSize: 12

                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            onClicked: histItem.modelData.dismiss()
                                        }
                                    }
                                }

                                Text {
                                    visible: !!histItem.modelData.body
                                    text: histItem.modelData.body
                                    color: Colors.br
                                    font.pixelSize: 12
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
