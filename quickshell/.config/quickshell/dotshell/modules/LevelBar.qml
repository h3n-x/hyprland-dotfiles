// Barra fina de nivel (Fase 4 B7): Inicio y Sistema. Color segun la gravedad
// (0 acento, 1 warning, 2 danger; los dos ultimos fijos, P8.7). Solo se desliza cuando el valor cambia
// de verdad (5 puntos o mas): las variaciones chicas de cada muestra se
// aplican sin animar, para que nada se mueva todo el tiempo.
import QtQuick
import ".." // Colors.qml, Tokens.qml

Item {
    id: bar
    property real fraction: 0
    property int level: 0
    property color tint: bar.level >= 2 ? Colors.danger : bar.level === 1 ? Colors.warning : Colors.accent
    implicitHeight: 4

    property real shown: 0
    onFractionChanged: {
        const to = Math.max(0, Math.min(1, bar.fraction));
        if (Math.abs(to - bar.shown) >= 0.05 && Tokens.motion.scale > 0 && bar.visible) {
            slide.to = to;
            slide.restart();
        } else {
            slide.stop();
            bar.shown = to;
        }
    }
    Component.onCompleted: bar.shown = Math.max(0, Math.min(1, bar.fraction))
    NumberAnimation {
        id: slide
        target: bar
        property: "shown"
        duration: Tokens.motion.medium
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.motion.easeStandard
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colors.tint(Colors.textMuted, Tokens.tint.track)
    }
    Rectangle {
        width: parent.width * bar.shown
        height: parent.height
        radius: height / 2
        color: bar.tint
        Behavior on color { ColorAnimation { duration: Tokens.motion.medium } }
    }
}
