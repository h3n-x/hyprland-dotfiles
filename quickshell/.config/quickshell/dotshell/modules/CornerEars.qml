// Panel de esquina pegado al marco (Fase 13 B2): el centro de control y los
// avisos tocan a la vez la barra y un lado fino (arriba a la derecha con la
// barra arriba; abajo a la derecha con la barra abajo; arriba a la izquierda
// con la barra a la izquierda; arriba a la derecha con la barra a la derecha).
// Dos orejas concavas (FrameCorner): una donde la tarjeta se junta con la
// barra y otra donde se junta con el lado fino. La forma depende solo de la
// esquina (corner: tr, br, tl, bl; de fabrica la del centro de control segun el
// borde de la barra): los avisos eligen la suya (notifications.position). Dice donde va la tarjeta en la
// ventana (cardX, cardY), cuanto mas grande es la ventana (un radio en cada
// direccion) y que esquina de la tarjeta queda redonda (la de afuera).
import QtQuick
import ".." // Colors.qml, Tokens.qml

Item {
    id: ce
    property bool on: false
    property string edge: Tokens.bar.edge
    property string corner: ({ top: "tr", bottom: "br", left: "tl", right: "tr" })[ce.edge] || "tr"
    property int ear: Tokens.frame.radius
    property real cardW: 0
    property real cardH: 0
    property real reveal: 1   // las orejas aparecen con la tarjeta

    readonly property int extra: ce.on ? ce.ear : 0
    readonly property real cardX: !ce.on ? 0 : (ce.corner === "tl" || ce.corner === "bl" ? 0 : ce.ear)
    readonly property real cardY: !ce.on ? 0 : (ce.corner === "br" || ce.corner === "bl" ? ce.ear : 0)
    // La esquina redonda: la opuesta a la esquina de la pantalla.
    readonly property string free: ({ tr: "bl", br: "tl", tl: "br", bl: "tr" })[ce.corner] || "bl"

    // [x, y, v, h] de cada oreja (relativo a la esquina de arriba a la izquierda de la ventana).
    readonly property var ears: ({
        tr: [[0, 0, "top", "right"], [ce.cardW, ce.cardH, "top", "right"]],
        br: [[0, ce.cardH, "bottom", "right"], [ce.cardW, 0, "bottom", "right"]],
        tl: [[0, ce.cardH, "top", "left"], [ce.cardW, 0, "top", "left"]],
        bl: [[ce.cardW, ce.cardH, "bottom", "left"], [0, 0, "bottom", "left"]]
    })[ce.corner] || []

    Repeater {
        model: ce.on ? ce.ears : []
        FrameCorner {
            required property var modelData
            x: modelData[0]; y: modelData[1]
            width: ce.ear; height: ce.ear
            v: modelData[2]; h: modelData[3]
            color: Colors.surfaceLow
            opacity: ce.reveal
        }
    }
}
