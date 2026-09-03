// Generado por matugen -- no editar a mano
import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
  id: passwordField
  focus: true
  selectByMouse: true
  placeholderText: "Password"
  echoMode: TextInput.Password
  passwordCharacter: "•"
  passwordMaskDelay: config.PasswordShowLastLetter
  selectionColor: "{{colors.outline.default.hex}}"
  renderType: Text.NativeRendering
  font {
    family: config.Font
    pointSize: config.FontSize
    bold: true
  }
  color: "{{colors.on_surface.default.hex}}"
  horizontalAlignment: TextInput.AlignHCenter
  background: Rectangle {
    id: passFieldBackground
    radius: 3
    color: "{{colors.surface_container.default.hex}}"
  }
  states: [
    State {
      name: "focused"
      when: passwordField.activeFocus
      PropertyChanges {
        target: passFieldBackground
        color: "{{colors.surface_container_high.default.hex}}"
      }
    },
    State {
      name: "hovered"
      when: passwordField.hovered
      PropertyChanges {
        target: passFieldBackground
        color: "{{colors.surface_container_high.default.hex}}"
      }
    }
  ]
  transitions: Transition {
    PropertyAnimation {
      properties: "color"
      duration: 300
    }
  }
}
