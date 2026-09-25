// Interruptor on/off compartido (reemplaza las tres copias del knob en
// NetworkDropdown, BluetoothDropdown y ControlCenter -- hallazgo F20). Colores
// de switch Material 3 (m3primary/m3onPrimary encendido, m3surfaceContainer-
// Highest/m3outline apagado); el knob se mueve con el spring calibrado de
// Hyprland (decision M1). No guarda estado propio: el consumidor enlaza
// "checked" y reacciona a "toggled":
//
//   Switch { checked: Networking.wifiEnabled
//            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled }
import QtQuick
import ".." // Tokens.qml, Colors.qml

Rectangle {
    id: root
    property bool checked: false
    signal toggled()

    implicitWidth: 36
    implicitHeight: 20
    radius: Tokens.radius.pill(height)
    color: checked ? Colors.m3primary : Colors.m3surfaceContainerHighest
    border.width: checked ? 0 : 1
    border.color: Colors.m3outline

    Behavior on color {
        ColorAnimation {
            duration: Tokens.motion.fast
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.motion.easeStandard
        }
    }

    Rectangle {
        id: knob
        width: 16
        height: 16
        radius: Tokens.radius.pill(height)
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 2 : 2
        color: root.checked ? Colors.m3onPrimary : Colors.m3outline
        // Un spring no tiene duracion que escalar: con movimiento reducido
        // (Tokens.motion.scale 0) el knob salta directo.
        Behavior on x {
            enabled: Tokens.motion.scale > 0
            SpringAnimation {
                spring: Tokens.motion.spring.qmlSpring
                damping: Tokens.motion.spring.qmlDamping
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
