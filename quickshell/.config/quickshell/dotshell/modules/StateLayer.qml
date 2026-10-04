// Capa de estado de Material 3 (decision C3): el color del contenido del
// elemento superpuesto con opacidad segun el estado (hover 8%, focus/pressed
// 10%, Tokens.stateLayer). Funciona sobre cualquier nivel de superficie, a
// diferencia de un color de hover fijo. Se pone como hijo del elemento y
// recibe el estado del MouseArea del padre:
//
//   Rectangle { radius: Tokens.radius.sm; color: Colors.surfaceLow
//       StateLayer { hovered: ma.containsMouse; pressed: ma.pressed }
//       MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true } }
import QtQuick
import ".." // Tokens.qml, Colors.qml

Item {
    id: root
    property bool hovered: false
    property bool pressed: false
    property bool focused: false
    // Color del contenido del elemento (texto/icono), no del fondo.
    property color contentColor: Colors.text
    property real radius: parent && parent.radius !== undefined ? parent.radius : 0

    anchors.fill: parent

    // La capa: el color del contenido con la opacidad del estado.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.contentColor
        opacity: root.pressed ? Tokens.stateLayer.pressed
               : root.hovered ? Tokens.stateLayer.hover
               : root.focused ? Tokens.stateLayer.focus
               : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.motion.fast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.motion.easeStandard
            }
        }
    }
    // Foco siempre visible (Fase 10 B2, accessibility.focusRing): anillo de
    // acento con el foco del teclado, como el de DashZone. Aparte de la capa
    // para que no herede su opacidad.
    Rectangle {
        visible: root.focused && Tokens.focusRing
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: Tokens.focusRingWidth
        border.color: Colors.accent
    }
}
