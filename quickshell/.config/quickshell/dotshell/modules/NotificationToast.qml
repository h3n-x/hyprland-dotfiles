// Popups temporales de notificaciones reales (no OSD -- ver Osd.qml para
// eso) -- reemplaza a las notificaciones emergentes de swaync. Una
// instancia por pantalla (ver shell.qml). Se autodescartan a los
// expireTimeout segundos salvo urgencia critica (quedan hasta que el
// usuario las cierra a mano, mismo criterio que la mayoria de los
// daemons de notificaciones).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import ".." // Colors.qml, Tokens.qml, NotificationState.qml

PanelWindow {
    id: toastWindow

    anchors {
        top: true
        right: true
    }
    // Debajo de la barra y alineado con su borde derecho, igual que
    // ControlCenter.qml (mismo ancho: los toasts quedan encolumnados con el panel).
    margins {
        top: Tokens.popupTop
        right: Tokens.screenEdge
    }
    implicitWidth: Tokens.panel.widthLg
    implicitHeight: column.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: NotificationState.activeToasts.length > 0

    ColumnLayout {
        id: column
        width: parent.width
        spacing: Tokens.space.sm

        Repeater {
            model: NotificationState.activeToasts

            // Nivel de elevacion 3 (surface_container_high); critica con
            // borde en error.
            Rectangle {
                id: toast
                required property var modelData
                readonly property bool critical: toast.modelData.urgency === NotificationUrgency.Critical
                Layout.fillWidth: true
                implicitHeight: content.implicitHeight + Tokens.space.md * 2
                radius: Tokens.radius.lg
                color: Colors.m3surfaceContainerHigh
                border.color: toast.critical ? Colors.m3error : Colors.m3outlineVariant
                border.width: 1

                Timer {
                    running: !toast.critical
                    interval: toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout * 1000 : 5000
                    onTriggered: toast.modelData.expire()
                }

                ColumnLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: Tokens.space.md
                    spacing: Tokens.space.xs

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.gap.inline

                        // Icono de la app que manda la notificacion (identifica
                        // el origen; no es iconografia de la shell).
                        IconImage {
                            visible: !!toast.modelData.appIcon
                            Layout.alignment: Qt.AlignVCenter
                            implicitSize: Tokens.icon.md
                            source: toast.modelData.appIcon ? Quickshell.iconPath(toast.modelData.appIcon) : ""
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: toast.modelData.summary
                            color: Colors.m3onSurface
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: Tokens.weight.semibold
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        visible: !!toast.modelData.body
                        Layout.fillWidth: true
                        text: toast.modelData.body
                        color: Colors.m3onSurfaceVariant
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        wrapMode: Text.WordWrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    RowLayout {
                        visible: toast.modelData.actions.length > 0
                        Layout.topMargin: Tokens.space.xs
                        spacing: Tokens.space.sm

                        Repeater {
                            model: toast.modelData.actions

                            // Boton tonal M3 (secondary_container), forma de pildora.
                            Rectangle {
                                id: actionBtn
                                required property var modelData
                                implicitWidth: actionLabel.implicitWidth + Tokens.pad.pillH * 2
                                implicitHeight: Tokens.pill.height
                                radius: Tokens.radius.pill(height)
                                color: Colors.m3secondaryContainer

                                StateLayer {
                                    hovered: actionMouse.containsMouse
                                    pressed: actionMouse.pressed
                                    contentColor: Colors.m3onSecondaryContainer
                                }

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: actionBtn.modelData.text
                                    color: Colors.m3onSecondaryContainer
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.label
                                    font.weight: Tokens.weight.medium
                                }

                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: actionBtn.modelData.invoke()
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: toast.modelData.dismiss()
                }
            }
        }
    }
}
