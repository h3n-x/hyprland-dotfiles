// Generado por matugen -- no editar a mano
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
  implicitHeight: powerButton.height
  implicitWidth: powerButton.width
  Button {
    id: powerButton
    height: inputHeight
    width: inputHeight
    hoverEnabled: true
    icon {
      source: Qt.resolvedUrl("../icons/power.svg")
      height: height
      width: width
      color: "{{colors.on_error.default.hex}}"
    }
    background: Rectangle {
      id: powerButtonBackground
      radius: 8
      color: "{{colors.error.default.hex}}"
    }
    states: [
      State {
        name: "hovered"
        when: powerButton.hovered
        PropertyChanges {
          target: powerButtonBackground
          color: "{{colors.error_container.default.hex}}"
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
    onClicked: sddm.powerOff()
  }
}
