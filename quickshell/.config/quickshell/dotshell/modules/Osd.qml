// Popup temporal (icono + barra de nivel) para volumen/mic/brillo --
// reemplaza a los notify-send que usaban antes esos tres. Una instancia
// por pantalla (ver shell.qml), igual patron que Bar.qml. exclusionMode
// Ignore: no reserva espacio ni empuja otras ventanas, solo se dibuja
// arriba de todo un instante y desaparece (OsdState.qml maneja el timer).
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, OsdState.qml

PanelWindow {
    id: osd

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 70
    margins {
        top: 60
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: OsdState.visible

    Rectangle {
        anchors.centerIn: parent
        implicitWidth: content.implicitWidth + 28
        implicitHeight: content.implicitHeight + 16
        radius: height / 2
        color: Colors.bg1

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 10

            Text {
                id: iconText
                Layout.alignment: Qt.AlignVCenter
                text: OsdState.icon
                color: Colors.fg
                font.pixelSize: 18
            }

            Item {
                Layout.alignment: Qt.AlignVCenter
                width: 120
                height: 6

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Colors.bg3

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, OsdState.value))
                        height: parent.height
                        radius: parent.radius
                        color: Colors.accent
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: OsdState.label
                color: Colors.fg
                font.pixelSize: 13
            }
        }
    }
}
