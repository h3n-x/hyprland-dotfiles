// Barra de desplazamiento de un Flickable (centro de configuracion, Fase 10
// B4): se ve solo si hay algo que desplazar. Clic en el riel lleva el pulgar
// ahi (centrado en el clic); arrastrar el pulgar lo mueve sin saltar (guarda
// el punto agarrado); la rueda sobre la barra desplaza como sobre el
// contenido. Con el puntero encima o arrastrando se ensancha. Sin
// temporizadores ni animaciones continuas: quieta no hace nada.
import QtQuick
import ".." // Colors.qml, Tokens.qml

Item {
    id: bar

    required property Flickable flickable

    readonly property real maxY: Math.max(0, bar.flickable.contentHeight - bar.flickable.height)
    readonly property bool active: area.containsMouse || area.pressed
    readonly property real thumbH: Math.min(bar.height, Math.max(32, bar.height * bar.flickable.height / Math.max(1, bar.flickable.contentHeight)))
    readonly property real thumbY: bar.maxY > 0 ? bar.flickable.contentY / bar.maxY * (bar.height - bar.thumbH) : 0
    // Donde se agarro el pulgar (desde su borde de arriba) mientras se arrastra.
    property real grab: 0

    function moveTo(y: real): void {
        const free = bar.height - bar.thumbH;
        if (free <= 0) return;
        bar.flickable.cancelFlick();
        bar.flickable.contentY = Math.max(0, Math.min(bar.maxY, (y - bar.grab) / free * bar.maxY));
    }

    visible: bar.maxY > 0
    implicitWidth: 14

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: Tokens.space.xs
        y: bar.thumbY
        width: bar.active ? 8 : 4
        height: bar.thumbH
        radius: width / 2
        color: Colors.tint(Colors.textMuted, bar.active ? Tokens.tint.well : Tokens.tint.hairline)
        Behavior on width { NumberAnimation { duration: Tokens.motion.fast } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        onPressed: (m) => {
            const onThumb = m.y >= bar.thumbY && m.y <= bar.thumbY + bar.thumbH;
            bar.grab = onThumb ? m.y - bar.thumbY : bar.thumbH / 2;
            bar.moveTo(m.y);
        }
        onPositionChanged: (m) => { if (area.pressed) bar.moveTo(m.y); }
        onWheel: (w) => {
            const d = w.pixelDelta.y !== 0 ? w.pixelDelta.y : w.angleDelta.y;
            bar.flickable.contentY = Math.max(0, Math.min(bar.maxY, bar.flickable.contentY - d));
        }
    }
}
