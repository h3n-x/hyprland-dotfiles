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
    // Superficie respuesta (Fase 8 B6): capa Overlay, por encima de una ventana en
    // pantalla completa (ver FullscreenState).
    WlrLayershell.layer: WlrLayer.Overlay
    // Pegado al marco (Fase 13 B2, estilo Marco): al ras del borde de arriba (la
    // barra, o el lado fino si la barra esta en otro borde), con dos orejas, y
    // sale de ese borde deslizandose; sin sombra.
    property var home: null
    Component.onCompleted: osd.home = osd.screen
    readonly property bool attached: BarVisibility.framed(osd.home)
    readonly property int ear: osd.attached ? Tokens.frame.radius : 0
    implicitHeight: box.implicitHeight + (osd.attached ? 0 : box.shadowMargin * 2)
    margins {
        // Arriba al centro; debajo de la barra si esta arriba (Fase 11 B3: inset).
        top: osd.attached ? BarVisibility.edgeSize("top") : Tokens.insetTop - box.shadowMargin
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
    Repeater {
        model: osd.attached ? 2 : 0
        FrameCorner {
            required property int index
            x: index === 0 ? box.x - osd.ear : box.x + box.width
            y: 0
            width: osd.ear; height: osd.ear
            v: "top"; h: index === 0 ? "right" : "left"
            color: Colors.frame
            opacity: presence.progress
        }
    }

    Surface {
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        y: osd.attached ? 0 : box.shadowMargin
        implicitWidth: content.implicitWidth + Tokens.pad.panel * 2
        implicitHeight: content.implicitHeight + Tokens.space.sm * 2
        level: 3
        translucent: true
        framed: osd.attached
        radius: Tokens.radius.pill(height)
        // Pegado: rectas las esquinas de arriba (contra el borde).
        topLeftRadius: osd.attached ? 0 : Tokens.radius.pill(height)
        topRightRadius: osd.attached ? 0 : Tokens.radius.pill(height)
        opacity: osd.attached ? 1 : presence.progress
        scale: osd.attached ? 1 : presence.contentScale
        transformOrigin: Item.Top
        transform: Translate { y: osd.attached ? -(1 - presence.progress) * box.height : presence.offsetY }

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
            // Sin barra si el aviso no tiene nivel (valor < 0: grabacion, B6).
            Rectangle {
                visible: OsdState.value >= 0
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Tokens.px(128)
                implicitHeight: Tokens.space.xs
                radius: Tokens.radius.pill(height)
                color: Colors.accentAltContainer

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, OsdState.value))
                    height: parent.height
                    radius: parent.radius
                    color: Colors.accent
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
                Layout.minimumWidth: OsdState.value >= 0 ? widest.width : 0
                text: OsdState.label
                color: Colors.text
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
