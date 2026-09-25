// Popup temporal (icono + barra de nivel) para volumen/mic/brillo --
// reemplaza a los notify-send que usaban antes esos tres. Una instancia
// por pantalla (ver shell.qml), igual patron que Bar.qml. exclusionMode
// Ignore: no reserva espacio ni empuja otras ventanas, solo se dibuja
// arriba de todo un instante y desaparece (OsdState.qml maneja el timer).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".." // Colors.qml, Tokens.qml, OsdState.qml

PanelWindow {
    id: osd

    anchors {
        top: true
        left: true
        right: true
    }
    // La franja suma arriba y abajo el margen de la sombra. Sin input: el OSD
    // no es interactivo y la franja ocupa todo el ancho, asi que la mascara
    // vacia deja pasar los clicks (antes bloqueaba ese borde de la pantalla
    // mientras se veia).
    WlrLayershell.namespace: "quickshell-panel"
    implicitHeight: box.implicitHeight + box.shadowMargin * 2
    margins {
        top: Tokens.popupTop - box.shadowMargin
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    // Entrada dur.short (P2.6); volver a mostrarlo mientras se ve solo
    // reinicia el timer de OsdState, sin segunda entrada.
    Presence { id: presence; open: OsdState.visible; enterDuration: Tokens.motion.short }
    visible: presence.shown

    // Nivel de elevacion 3 (surface_container_high translucida sobre blur,
    // sombra md), forma de pildora.
    Surface {
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        y: box.shadowMargin
        implicitWidth: content.implicitWidth + Tokens.pad.panel * 2
        implicitHeight: content.implicitHeight + Tokens.space.sm * 2
        level: 3
        translucent: true
        radius: Tokens.radius.pill(height)
        opacity: presence.progress
        scale: presence.contentScale
        transformOrigin: Item.Top
        transform: Translate { y: presence.offsetY }

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
                    // Solo mientras ya esta abierto: al aparecer, el valor nuevo
                    // se escribe antes de abrir y no anima desde el anterior.
                    Behavior on width {
                        enabled: presence.open
                        NumberAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
                    }
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
