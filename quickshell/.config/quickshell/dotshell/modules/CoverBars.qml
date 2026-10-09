// Barras de audio alrededor de la portada (Fase 12 B3, P12.3, D-B3-4): una
// barra por valor de CavaState, desde el borde de la forma de la portada
// (CoverShape.radiusAt: sigue la forma y su giro) hacia afuera, tan larga como
// su valor dentro del anillo libre (ring). Todas en un solo trazo
// (PathMultiline): un cambio por cuadro, no uno por barra. Puntas redondas;
// color de identidad (Colors.accent; con B4, el de la portada).
// No corre nada propio: dibuja lo que llega mientras CavaState corre.
import QtQuick
import QtQuick.Shapes
import ".." // Colors.qml, Tokens.qml, CavaState.qml

Item {
    id: bars
    // El contorno de la portada (MediaCover.outline) y el ancho del anillo libre.
    property Item outline: null
    property real ring: Tokens.space.xxl
    readonly property var values: CavaState.values
    readonly property int n: bars.values.length
    readonly property real gap: Tokens.space.xs
    // Grosor: la mitad del lugar que le toca a cada barra en el borde.
    readonly property real stroke: bars.outline && bars.n > 0
        ? Math.max(2, Math.min(Tokens.space.sm, Math.PI * bars.outline.r / bars.n)) : 2
    readonly property real reach: Math.max(0, bars.ring - bars.gap - bars.stroke)

    readonly property var segments: {
        const o = bars.outline, v = bars.values, n = bars.n;
        if (!o || n === 0) return [];
        // El centro de la portada en estas coordenadas.
        const c = o.mapToItem(bars, o.width / 2, o.height / 2);
        const out = [];
        for (let i = 0; i < n; i++) {
            const t = i / n * 2 * Math.PI - Math.PI / 2;
            const d0 = o.radiusAt(t) + bars.gap + bars.stroke / 2;
            const d1 = d0 + Math.max(0.01, v[i]) * bars.reach;
            const cs = Math.cos(t), sn = Math.sin(t);
            out.push([Qt.point(c.x + d0 * cs, c.y + d0 * sn), Qt.point(c.x + d1 * cs, c.y + d1 * sn)]);
        }
        return out;
    }

    Shape {
        anchors.fill: parent
        visible: bars.n > 0
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: bars.stroke
            strokeColor: Colors.accent
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathMultiline { paths: bars.segments }
        }
    }
}
