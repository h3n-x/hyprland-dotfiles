// Temporizador en la barra (Fase 11 B5b, opcional; no esta en la barra de
// fabrica): mientras corre un temporizador, su icono y lo que queda ("12 min";
// el cronometro, lo que lleva). Clic: pausa o sigue. La cifra avanza una vez
// por minuto (Demand minutes de TimerState), nunca cada segundo.
import QtQuick
import ".." // Colors.qml, Tokens.qml, TimerState.qml

Item {
    id: root
    readonly property var run: TimerState.active
    readonly property bool shown: !!root.run
    readonly property string value: !root.run ? "" : root.run.left !== undefined ? TimerState.short(root.run.left) : TimerState.short(root.run.elapsed)
    // Texto de la informacion al pasar el raton (bar.tooltips).
    readonly property string tooltip: root.run ? root.run.label + " · " + root.value + " · clic pausa" : ""
    visible: shown

    Subscription { demand: TimerState.minutes; active: root.shown }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    BarFlow {
        id: row
        spacing: Tokens.space.xs
        Icon { name: root.run && root.run.mode === "stopwatch" ? "timer" : "hourglass_top"; size: Tokens.icon.md }
        Text {
            // Barra vertical: sin el espacio ("12min" no cabe; "12m").
            text: Tokens.bar.vertical ? root.value.replace(" min", "m").replace(" h ", "h") : root.value
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
            font.weight: Tokens.weight.semibold
            font.features: Tokens.tabularNumbers
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const m = root.run ? root.run.mode : "";
            if (m === "pomodoro") TimerState.togglePomodoro();
            else if (m === "countdown") TimerState.toggleCountdown();
            else if (m === "stopwatch") TimerState.toggleStopwatch();
        }
    }
}
