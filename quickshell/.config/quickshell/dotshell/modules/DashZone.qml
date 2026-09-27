// Zona del dashboard (Fase 4 B7): un tinte compartido dentro de la unica
// superficie, sin sombra ni borde propio (una sola superficie viva, no
// tarjetas). Anillo de foco del teclado (Tab) y, si se puede abrir, capa de
// estado al pasar el mouse. El contenido se pone como hijo, con el margen de
// la zona ya aplicado.
import QtQuick
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: zone
    property bool focused: false
    // Se puede abrir con un clic (lleva a su vista).
    property bool clickable: false
    // false: la zona dibuja su propio fondo (el reproductor).
    property bool tinted: true
    property int padding: Tokens.space.lg
    default property alias content: inner.data
    signal activated()

    // Radio anidado: 24 (dashboard) - 12 (su margen) = md.
    radius: Tokens.radius.md
    color: zone.tinted ? Colors.tint(Colors.surfaceHighest, Tokens.tint.well) : "transparent"

    StateLayer {
        visible: zone.clickable
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: zone.clickable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: zone.activated()
    }
    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: zone.padding
    }
    // Encima del contenido (el reproductor tiene fondo propio).
    Rectangle {
        anchors.fill: parent
        radius: zone.radius
        color: "transparent"
        border.width: 2
        border.color: Colors.accent
        opacity: zone.focused ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Tokens.motion.fast } }
    }
}
