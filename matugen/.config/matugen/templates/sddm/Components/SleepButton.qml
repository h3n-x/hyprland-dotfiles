// Generado por matugen -- no editar a mano
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
  implicitHeight: sleepButton.height
  implicitWidth: sleepButton.width
  Button {
    id: sleepButton
    height: inputHeight
    width: inputHeight
    hoverEnabled: true
    icon {
      source: Qt.resolvedUrl("../icons/sleep.svg")
      height: height
      width: width
      color: "{{colors.on_error.default.hex}}"
    }
    background: Rectangle {
      id: sleepButtonBg
      color: "{{colors.error.default.hex}}"
      radius: 8
    }
    states: [
      State {
        name: "hovered"
        when: sleepButton.hovered
        PropertyChanges {
          target: sleepButtonBg
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
    onClicked: sddm.suspend()
  }
}
