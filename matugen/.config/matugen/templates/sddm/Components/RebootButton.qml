// Generado por matugen -- no editar a mano
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
  implicitHeight: rebootButton.height
  implicitWidth: rebootButton.width
  Button {
    id: rebootButton
    height: inputHeight
    width: inputHeight
    hoverEnabled: true
    icon {
      source: Qt.resolvedUrl("../icons/reboot.svg")
      height: height
      width: width
      color: "{{status.on_error.default.hex}}"
    }
    background: Rectangle {
      id: rebootButtonBackground
      radius: 8
      color: "{{status.error.default.hex}}"
    }
    states: [
      State {
        name: "hovered"
        when: rebootButton.hovered
        PropertyChanges {
          target: rebootButtonBackground
          color: "{{status.error_container.default.hex}}"
        }
      }
    ]
    transitions: Transition {
      PropertyAnimation {
        properties: "color"

        duration: 100 // dur.fast + ease.standard (D7/M2)
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.33, 1, 0.68, 1, 1, 1]
      }
    }
    onClicked: sddm.reboot()
  }
}
