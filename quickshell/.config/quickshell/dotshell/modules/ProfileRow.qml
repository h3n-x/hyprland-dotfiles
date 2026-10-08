// Perfil de energia en el centro de control (Fase 4; componente propio desde
// la Fase 11 B6: el ajuste rapido "profile" en tamano fila). Selector de
// perfiles de power-profiles-daemon: botones segmentados, el perfil activo en
// secondary_container (C3).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, PowerProfileState.qml

RowLayout {
    spacing: Tokens.space.xs

    Repeater {
        model: PowerProfileState.profiles

        Rectangle {
            id: profBtn
            required property var modelData
            readonly property bool selected: PowerProfileState.current === profBtn.modelData.id
            readonly property color contentColor: profBtn.selected ? Colors.textOnAccentAltContainer : Colors.textMuted
            // Texto grande (Fase 10 B2): si no entra todo, primero se va
            // el icono; el nombre se corta solo si ni asi entra.
            readonly property bool roomy: profBtn.width - profBtn.border.width * 2 >= profText.implicitWidth + Tokens.icon.sm + Tokens.space.xs
            Layout.fillWidth: true
            implicitHeight: Tokens.pill.height
            radius: Tokens.radius.sm
            color: profBtn.selected ? Colors.accentAltContainer : "transparent"
            border.color: profBtn.selected ? Colors.accentAltContainer : Colors.divider
            Behavior on color { ColorAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            Behavior on border.color { ColorAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            border.width: 1

            StateLayer {
                hovered: profMouse.containsMouse
                pressed: profMouse.pressed
                contentColor: profBtn.contentColor
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: Tokens.space.xs

                Icon {
                    visible: profBtn.roomy
                    name: profBtn.modelData.icon
                    filled: profBtn.selected
                    size: Tokens.icon.sm
                    color: profBtn.contentColor
                }

                Text {
                    id: profText
                    Layout.maximumWidth: profBtn.width - profBtn.border.width * 2
                    elide: Text.ElideRight
                    text: profBtn.modelData.label
                    color: profBtn.contentColor
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                    font.weight: profBtn.selected ? Tokens.weight.semibold : Tokens.weight.regular
                }
            }

            MouseArea {
                id: profMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: PowerProfileState.set(profBtn.modelData.id)
            }
        }
    }
}
