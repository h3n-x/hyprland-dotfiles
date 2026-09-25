// Capa de estado de Material 3 (decision C3): el color del contenido del
// elemento superpuesto con opacidad segun el estado (hover 8%, focus/pressed
// 10%, Tokens.stateLayer). Funciona sobre cualquier nivel de superficie, a
// diferencia de un color de hover fijo. Se pone como hijo del elemento y
// recibe el estado del MouseArea del padre:
//
//   Rectangle { radius: Tokens.radius.sm; color: Colors.m3surfaceContainerLow
//       StateLayer { hovered: ma.containsMouse; pressed: ma.pressed }
//       MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true } }
import QtQuick
import ".." // Tokens.qml, Colors.qml

Rectangle {
    id: root
    property bool hovered: false
    property bool pressed: false
    property bool focused: false
    // Color del contenido del elemento (texto/icono), no del fondo.
    property color contentColor: Colors.m3onSurface

    anchors.fill: parent
    radius: parent && parent.radius !== undefined ? parent.radius : 0
    color: contentColor
    opacity: pressed ? Tokens.stateLayer.pressed
           : hovered ? Tokens.stateLayer.hover
           : focused ? Tokens.stateLayer.focus
           : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Tokens.motion.fast
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.motion.easeStandard
        }
    }
}
