// Popup temporal (icono + barra de nivel) para volumen/mic/brillo --
// reemplaza a los notify-send que usaban antes esos tres. Una instancia
// por pantalla (ver shell.qml), igual patron que Bar.qml. exclusionMode
// Ignore: no reserva espacio ni empuja otras ventanas, solo se dibuja
// arriba de todo un instante y desaparece (OsdState.qml maneja el timer).
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, OsdState.qml

PanelWindow {
    id: osd

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: box.implicitHeight
    margins {
        top: Tokens.popupTop
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: OsdState.visible

    // Nivel de elevacion 3 (surface_container_high), forma de pildora.
    Rectangle {
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: content.implicitWidth + Tokens.pad.panel * 2
        implicitHeight: content.implicitHeight + Tokens.space.sm * 2
        radius: Tokens.radius.pill(height)
        color: Colors.m3surfaceContainerHigh

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Tokens.space.md

            // OsdState.icon es un nombre de ligadura de Material Symbols.
            Icon {
                Layout.alignment: Qt.AlignVCenter
                name: OsdState.icon
                filled: true
                size: Tokens.icon.xl
            }

            // Barra de nivel: pista activa en primary, inactiva en
            // secondary_container (slider M3).
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 128
                implicitHeight: Tokens.space.xs
                radius: Tokens.radius.pill(height)
                color: Colors.m3secondaryContainer

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, OsdState.value))
                    height: parent.height
                    radius: parent.radius
                    color: Colors.m3primary
                }
            }

            // Ancho minimo = "100%": la pildora no cambia de ancho mientras
            // se sube o baja el valor.
            Text {
                Layout.alignment: Qt.AlignVCenter
                Layout.minimumWidth: widest.width
                text: OsdState.label
                color: Colors.m3onSurface
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.headline
                font.weight: Tokens.weight.medium
                font.features: Tokens.tabularNumbers

                TextMetrics {
                    id: widest
                    text: "100%"
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.headline
                    font.weight: Tokens.weight.medium
                    font.features: Tokens.tabularNumbers
                }
            }
        }
    }
}
