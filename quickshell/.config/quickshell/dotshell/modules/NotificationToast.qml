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
import ".." // Colors.qml, NotificationState.qml

PanelWindow {
    id: toastWindow

    anchors {
        top: true
        right: true
    }
    // top: 60, no 10 -- ver el mismo comentario en ControlCenter.qml.
    margins {
        top: 60
        right: 10
    }
    implicitWidth: 340
    implicitHeight: column.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: NotificationState.activeToasts.length > 0

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            model: NotificationState.activeToasts

            Rectangle {
                id: toast
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: content.implicitHeight + 20
                radius: 14
                color: Colors.bg1
                border.color: toast.modelData.urgency === NotificationUrgency.Critical ? Colors.critical : Colors.br
                border.width: 1

                Timer {
                    running: toast.modelData.urgency !== NotificationUrgency.Critical
                    interval: toast.modelData.expireTimeout > 0 ? toast.modelData.expireTimeout * 1000 : 5000
                    onTriggered: toast.modelData.expire()
                }

                ColumnLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        IconImage {
                            visible: !!toast.modelData.appIcon
                            Layout.alignment: Qt.AlignVCenter
                            implicitSize: 20
                            source: toast.modelData.appIcon ? Quickshell.iconPath(toast.modelData.appIcon) : ""
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: toast.modelData.summary
                            color: Colors.fg
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        visible: !!toast.modelData.body
                        Layout.fillWidth: true
                        text: toast.modelData.body
                        color: Colors.fg
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    RowLayout {
                        visible: toast.modelData.actions.length > 0
                        spacing: 6

                        Repeater {
                            model: toast.modelData.actions

                            Rectangle {
                                id: actionBtn
                                required property var modelData
                                implicitWidth: actionLabel.implicitWidth + 16
                                implicitHeight: 26
                                radius: 8
                                color: actionMouse.containsMouse ? Colors.hoverBg : Colors.bg2

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: actionBtn.modelData.text
                                    color: Colors.fg
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
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
