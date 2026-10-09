// Forma de una portada (Fase 12 B2, media.cover.shape): un contorno propio
// (sin el plugin M3Shapes) que sirve de mascara. "rounded" = el cuadrado con
// esquinas de siempre; circle; cookie4/7/9 (borde ondulado de 4, 7 o 9
// lobulos); burst (12 puntas suaves). turn gira el contorno (grados): la
// portada lo anima al cambiar de cancion, nunca de forma continua.
//
// radiusAt(angulo) = distancia del centro al borde en ese angulo (radianes,
// 0 = derecha, sentido horario): de ahi salen las barras de B3.
import QtQuick
import QtQuick.Shapes
import ".." // Colors.qml, Tokens.qml

Item {
    id: root
    property string kind: "rounded"
    property real turn: 0
    property color fill: Colors.text   // como mascara solo cuenta el alfa
    // Contorno (el borde fino de la portada): transparente = sin contorno.
    property color stroke: "transparent"
    implicitWidth: Tokens.cover.music
    implicitHeight: Tokens.cover.music

    // Lobulos y profundidad (fraccion del radio) de cada forma ondulada.
    readonly property var waves: ({ cookie4: [4, 0.08], cookie7: [7, 0.07], cookie9: [9, 0.06], burst: [12, 0.09] })
    readonly property real r: Math.min(root.width, root.height) / 2

    function radiusAt(theta: real): real {
        const w = root.waves[root.kind];
        if (w) {
            const a = theta - root.turn * Math.PI / 180;
            return root.r * (1 - w[1] + w[1] * Math.cos(w[0] * a));
        }
        if (root.kind === "circle") return root.r;
        // Cuadrado redondeado: el borde de la caja (sin las esquinas, que no usa nadie).
        const c = Math.abs(Math.cos(theta)), s = Math.abs(Math.sin(theta));
        return root.r / Math.max(c, s);
    }

    readonly property var points: {
        if (root.kind === "rounded" || root.r <= 0) return [];
        const n = 180, out = [];
        for (let i = 0; i <= n; i++) {
            const t = i / n * 2 * Math.PI, d = root.radiusAt(t);
            out.push(Qt.point(root.width / 2 + d * Math.cos(t), root.height / 2 + d * Math.sin(t)));
        }
        return out;
    }

    Rectangle {
        visible: root.kind === "rounded"
        anchors.fill: parent
        radius: Tokens.radius.lg
        color: root.fill
        border.width: root.stroke.a > 0 ? 1 : 0
        border.color: root.stroke
    }
    Shape {
        visible: root.kind !== "rounded"
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: root.stroke.a > 0 ? 1 : -1
            strokeColor: root.stroke
            fillColor: root.fill
            PathPolyline { path: root.points }
        }
    }
}
