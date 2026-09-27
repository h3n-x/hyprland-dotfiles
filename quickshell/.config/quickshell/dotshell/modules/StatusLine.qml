// Frase de estado del equipo con su punto de color (Fase 4 B7): Inicio y
// Sistema. Al cambiar, la frase se funde (sale y entra) y el punto cambia de
// color; nada se mueve mientras el estado sigue igual.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, SystemState.qml

RowLayout {
    id: line
    property int textSize: Tokens.type.title
    spacing: Tokens.space.sm

    readonly property string statusText: SystemState.status.text
    property string shownText: SystemState.status.text
    onStatusTextChanged: {
        if (Tokens.motion.scale > 0 && line.visible) swap.restart();
        else line.shownText = line.statusText;
    }
    SequentialAnimation {
        id: swap
        NumberAnimation { target: label; property: "opacity"; to: 0; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeExit }
        ScriptAction { script: line.shownText = line.statusText }
        NumberAnimation { target: label; property: "opacity"; to: 1; duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
    }

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: Math.round(line.textSize / 2)
        implicitHeight: implicitWidth
        radius: implicitWidth / 2
        color: SystemState.status.level >= 2 ? Colors.danger : SystemState.status.level === 1 ? Colors.warning : Colors.accent
        Behavior on color { ColorAnimation { duration: Tokens.motion.medium } }
    }
    Text {
        id: label
        Layout.fillWidth: true
        text: line.shownText
        color: Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: line.textSize
        font.weight: Tokens.weight.semibold
        elide: Text.ElideRight
    }
}
