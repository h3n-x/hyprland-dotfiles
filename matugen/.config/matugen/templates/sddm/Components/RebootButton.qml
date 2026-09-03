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
      color: "{{colors.on_error.default.hex}}"
    }
    background: Rectangle {
      id: rebootButtonBackground
      radius: 3
      color: "{{colors.error.default.hex}}"
    }
    states: [
      State {
        name: "hovered"
        when: rebootButton.hovered
        PropertyChanges {
          target: rebootButtonBackground
          color: "{{colors.error_container.default.hex}}"
        }
      }
    ]
    transitions: Transition {
      PropertyAnimation {
        properties: "color"
        duration: 300
      }
    }
    onClicked: sddm.reboot()
  }
}
