// Generado por matugen -- no editar a mano
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQml.Models 2.15

Item {
  property var session: sessionList.currentIndex
  implicitHeight: sessionButton.height
  implicitWidth: sessionButton.width
  DelegateModel {
    id: sessionWrapper
    model: sessionModel
    delegate: ItemDelegate {
      id: sessionEntry
      height: inputHeight
      width: parent.width
      highlighted: sessionList.currentIndex == index
      contentItem: Text {
        renderType: Text.NativeRendering
        font {
          family: config.Font
          pointSize: config.FontSize
          bold: true
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: "{{colors.on_surface.default.hex}}"
        text: name
      }
      background: Rectangle {
        id: sessionEntryBackground
        color: "{{colors.surface_container_high.default.hex}}"
        radius: 8
      }
      states: [
        State {
          name: "hovered"
          when: sessionEntry.hovered
          PropertyChanges {
            target: sessionEntryBackground
            color: "{{colors.surface_container_highest.default.hex}}"
          }
        }
      ]
      transitions: Transition {
        PropertyAnimation {
          property: "color"

          duration: 100 // dur.fast + ease.standard (D7/M2)
          easing.type: Easing.BezierSpline
          easing.bezierCurve: [0.33, 1, 0.68, 1, 1, 1]
        }
      }
      MouseArea {
        anchors.fill: parent
        onClicked: {
          sessionList.currentIndex = index
          sessionPopup.close()
        }
      }
    }
  }
  Button {
    id: sessionButton
    height: inputHeight
    width: inputHeight
    hoverEnabled: true
    icon {
      source: Qt.resolvedUrl("../icons/settings.svg")
      height: height
      width: width
      color: "{{colors.on_surface.default.hex}}"
    }
    background: Rectangle {
      id: sessionButtonBackground
      color: "{{colors.surface_container.default.hex}}"
      radius: 8
    }
    states: [
      State {
        name: "pressed"
        when: sessionButton.down
        PropertyChanges {
          target: sessionButtonBackground
          color: "{{colors.surface_container_high.default.hex}}"
        }
      },
      State {
        name: "hovered"
        when: sessionButton.hovered
        PropertyChanges {
          target: sessionButtonBackground
          color: "{{colors.surface_container_highest.default.hex}}"
        }
      },
      State {
        name: "selection"
        when: sessionPopup.visible
        PropertyChanges {
          target: sessionButtonBackground
          color: "{{colors.surface_container_highest.default.hex}}"
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
    onClicked: {
      sessionPopup.visible ? sessionPopup.close() : sessionPopup.open()
      sessionButton.state = "pressed"
    }
  }
  Popup {
    id: sessionPopup
    width: inputWidth + padding * 2
    x: (sessionButton.width + sessionList.spacing) * -7.6
    y: -(contentHeight + padding * 2) + sessionButton.height
    padding: inputHeight / 10
    background: Rectangle {
      radius: 12
      color: "{{colors.surface_container.default.hex}}"
    }
    contentItem: ListView {
      id: sessionList
      implicitHeight: contentHeight
      spacing: 8
      model: sessionWrapper
      currentIndex: sessionModel.lastIndex
      clip: true
    }
    enter: Transition {
      ParallelAnimation {
        NumberAnimation {
          property: "opacity"
          from: 0
          to: 1
          duration: 300 // dur.medium + ease.enter (D7/M2)
          easing.type: Easing.BezierSpline
          easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1]
        }
        NumberAnimation {
          property: "x"
          from: sessionPopup.x + (inputWidth * 0.1)
          to: sessionPopup.x
          duration: 300 // dur.medium + ease.enter (D7/M2)
          easing.type: Easing.BezierSpline
          easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1]
        }
      }
    }
    exit: Transition {
      NumberAnimation {
        property: "opacity"
        from: 1
        to: 0
        duration: 180 // exitFor(300) + ease.exit (D7/M2)
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.5, 0.5, 0.75, 1, 1, 1]
      }
    }
  }
}
