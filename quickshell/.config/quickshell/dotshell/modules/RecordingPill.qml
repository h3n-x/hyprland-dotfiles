// Pill de grabacion (Fase 4 B8): solo mientras se graba y un momento al
// terminar. Punto rojo y tiempo; clic = parar. El punto late en cada segundo,
// con el mismo timer que cambia el tiempo (sin animacion continua), y da un
// pulso al empezar. Al parar: "Guardada · m:ss" 1,5 s (o el error 3 s) y se
// pliega; la vista previa de capturas muestra el video.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, CaptureState.qml

Pill {
    id: pill
    // A un costado (Fase 11 B3): el punto y el tiempo en columna.
    vertical: Tokens.bar.vertical

    readonly property string result: CaptureState.recordResult
    readonly property bool recording: CaptureState.isRecording
    readonly property bool saved: pill.result === "saved"
    readonly property bool failed: pill.result === "error"

    // Si se muestra (Fase 11 B1: la disposicion de la barra lee shown, nunca visible).
    readonly property bool shown: pill.recording || pill.result !== ""
    visible: shown
    // Resultado (P8.7): guardado = success, error = danger (fijos); grabando, neutro con el punto danger (N6).
    color: pill.saved ? Colors.successContainer : pill.failed ? Colors.dangerContainer : Colors.surfaceLow
    hovered: mouse.containsMouse && pill.recording
    pressed: mouse.pressed && pill.recording

    function clock(s: int): string {
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    Item {
        Layout.alignment: Qt.AlignCenter
        implicitWidth: Tokens.icon.md
        implicitHeight: Tokens.icon.md

        Rectangle {
            id: dot
            visible: pill.recording && pill.result !== "stopping"
            anchors.centerIn: parent
            width: 10
            height: 10
            radius: 5
            color: Colors.danger
            // Late con el segundo: lleno en los pares, 45 % en los impares. Sin
            // fundido a proposito: 100 ms de fundido por segundo costaban 2,3 %
            // de un nucleo; el cambio seco, 0,3 % (medido en la sonda B8).
            opacity: CaptureState.elapsed % 2 === 0 ? 1 : 0.45
        }
        // Pulso de arranque: un anillo que crece y se apaga una vez.
        Rectangle {
            id: ring
            anchors.centerIn: parent
            width: 10
            height: 10
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Colors.danger
            opacity: 0
            ParallelAnimation {
                id: pulse
                NumberAnimation { target: ring; property: "scale"; from: 1; to: 2.2; duration: Tokens.motion.long; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
                NumberAnimation { target: ring; property: "opacity"; from: 0.9; to: 0; duration: Tokens.motion.long; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
            }
        }
        Icon {
            visible: !dot.visible
            anchors.centerIn: parent
            name: pill.failed ? "error" : pill.saved ? "check_circle" : "hourglass_top"
            filled: true
            size: Tokens.icon.sm
            color: pill.failed ? Colors.textOnDangerContainer : pill.saved ? Colors.textOnSuccessContainer : Colors.textMuted
        }
    }

    Text {
        Layout.alignment: Qt.AlignCenter
        // A un costado (Fase 11 B3) solo el tiempo o una marca: no entra la frase.
        text: Tokens.bar.vertical ? (pill.failed ? "!" : pill.saved ? "✓" : pill.result === "stopping" ? "…" : pill.clock(CaptureState.elapsed))
            : pill.failed ? "No se pudo grabar"
            : pill.saved ? "Guardada · " + pill.clock(Math.round(CaptureState.recordedMs / 1000))
            : pill.result === "stopping" ? "Guardando…"
            : pill.clock(CaptureState.elapsed)
        color: pill.failed ? Colors.textOnDangerContainer : pill.saved ? Colors.textOnSuccessContainer : Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.bar.vertical ? Tokens.type.caption : Tokens.type.body
        font.weight: Tokens.weight.medium
        font.features: Tokens.tabularNumbers
    }

    onRecordingChanged: if (pill.recording && Tokens.motion.scale > 0) pulse.restart()

    MouseArea {
        id: mouse
        // Hijo del RowLayout de Pill: se saca del layout y cubre la pill.
        parent: pill
        anchors.fill: parent
        hoverEnabled: true
        enabled: pill.recording
        cursorShape: Qt.PointingHandCursor
        onClicked: CaptureState.stopRecording()
    }
}
