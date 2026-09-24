// Generado por matugen -- no editar a mano
import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
  id: userField
  height: inputHeight
  width: inputWidth
  selectByMouse: true
  echoMode: TextInput.Normal
  selectionColor: "{{colors.outline.default.hex}}"
  renderType: Text.NativeRendering
  font {
    family: config.Font
    pointSize: config.FontSize
    bold: true
  }
  color: "{{colors.on_surface.default.hex}}"
  horizontalAlignment: Text.AlignHCenter
  placeholderText: "Username"
  text: userModel.lastUser
  background: Rectangle {
    id: userFieldBackground
    color: "{{colors.surface_container.default.hex}}"
    radius: 8
  }
  states: [
    State {
      name: "focused"
      when: userField.activeFocus
      PropertyChanges {
        target: userFieldBackground
        color: "{{colors.surface_container_high.default.hex}}"
      }
    },
    State {
      name: "hovered"
      when: userField.hovered
      PropertyChanges {
        target: userFieldBackground
        color: "{{colors.surface_container_high.default.hex}}"
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
}
