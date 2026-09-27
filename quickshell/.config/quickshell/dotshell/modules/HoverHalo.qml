// Capa de estado de un control de la barra (P2.4, decision Q2 = A): una
// pildora de alto pill.height centrada sobre el control, circular si el
// control es solo un icono y alargada si lleva texto (bateria, puertos).
// Va detras del contenido (z -1) y lee el estado del MouseArea del control.
// En pills de accion unica (Clock, Mpris) se ilumina la pill entera (Pill.qml).
//
//   HoverHalo { hovered: mouse.containsMouse; pressed: mouse.pressed }
import QtQuick
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root
    property bool hovered: false
    property bool pressed: false
    property color contentColor: Colors.text

    readonly property real contentWidth: parent ? parent.width : 0
    anchors.centerIn: parent
    height: Tokens.pill.height
    width: root.contentWidth <= root.height ? root.height : root.contentWidth + Tokens.space.sm * 2
    radius: Tokens.radius.pill(root.height)
    color: "transparent"
    z: -1

    StateLayer {
        hovered: root.hovered
        pressed: root.pressed
        contentColor: root.contentColor
    }
}
