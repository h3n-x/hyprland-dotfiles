// Grafico chico de historia corta (Fase 11 B5c, P11.8): la vista Sistema.
// Dibujado con Shape (sin C++). Cambia en escalones, una vez por muestra,
// como los numeros: no se desliza ni anima (principio 14). El borde derecho
// es la ultima muestra; donde no se midio (dashboard cerrado) hay un hueco.
//
//   Sparkline { series: SystemState.series("cpu"); rev: SystemState.historyRev; maxValue: 1 }
//
// mode "line": linea + relleno tenue; con series2, una segunda linea (subida
// de la red). mode "strip": franjas donde el valor es 1 (la NVIDIA activa).
// maxValue 0 = escala automatica en potencias de 2 desde `floor` (no tiembla).
// Colores de identidad, nunca de estado (principio 23): el estado lo dicen la
// palabra y el nivel del instrumento.
import QtQuick
import QtQuick.Shapes
import ".." // Colors.qml, Tokens.qml

Item {
    id: root

    property var series: []
    property var series2: []
    // Cambia una vez por muestra (SystemState.historyRev): recalcula el dibujo.
    property int rev: 0
    property real span: 300000
    property real step: 2000
    property real maxValue: 1
    property real floor: 65536
    property string mode: "line"
    property color color: Colors.accent
    property color color2: Colors.accentAlt
    // Texto de un valor al pasar el raton.
    property var format: (v) => Math.round(v * 100) + " %"

    implicitHeight: 40

    readonly property real last: {
        void root.rev;
        const a = root.series, b = root.series2 || [];
        return Math.max(a.length ? a[a.length - 1].t : 0, b.length ? b[b.length - 1].t : 0);
    }
    readonly property real scaleTop: {
        void root.rev;
        if (root.maxValue > 0) return root.maxValue;
        let peak = 0;
        for (const p of root.series) peak = Math.max(peak, p.v);
        for (const p of (root.series2 || [])) peak = Math.max(peak, p.v);
        let t = root.floor;
        while (t < peak) t *= 2;
        return t;
    }
    readonly property bool enough: (root.series || []).length >= 2

    function xOf(t: real): real {
        return (t - (root.last - root.span)) / root.span * root.width;
    }
    function yOf(v: real): real {
        return root.height - 1 - Math.min(1, Math.max(0, v / root.scaleTop)) * (root.height - 2);
    }
    // Tramos sin huecos (un salto de mas de 2,5 muestras corta la linea).
    function segments(a: var): var {
        const out = [];
        let cur = [];
        const start = root.last - root.span;
        for (let i = 0; i < a.length; i++) {
            if (a[i].t < start) continue;
            if (cur.length && a[i].t - cur[cur.length - 1].t > 2.5 * root.step) {
                out.push(cur);
                cur = [];
            }
            cur.push(a[i]);
        }
        if (cur.length) out.push(cur);
        return out;
    }
    function linePath(a: var): string {
        void root.rev;
        let d = "";
        for (const seg of root.segments(a || [])) {
            if (seg.length < 2) continue;
            d += "M " + root.xOf(seg[0].t).toFixed(1) + " " + root.yOf(seg[0].v).toFixed(1);
            for (let i = 1; i < seg.length; i++) d += " L " + root.xOf(seg[i].t).toFixed(1) + " " + root.yOf(seg[i].v).toFixed(1);
            d += " ";
        }
        return d;
    }
    function fillPath(a: var): string {
        void root.rev;
        let d = "";
        const b = root.height.toFixed(1);
        for (const seg of root.segments(a || [])) {
            if (seg.length < 2) continue;
            const x0 = root.xOf(seg[0].t).toFixed(1);
            d += "M " + x0 + " " + b;
            for (const p of seg) d += " L " + root.xOf(p.t).toFixed(1) + " " + root.yOf(p.v).toFixed(1);
            d += " L " + root.xOf(seg[seg.length - 1].t).toFixed(1) + " " + b + " Z ";
        }
        return d;
    }
    // Franjas donde v = 1 (hasta la muestra siguiente).
    function stripPath(a: var): string {
        void root.rev;
        let d = "";
        const h = root.height.toFixed(1);
        for (const seg of root.segments(a || [])) {
            for (let i = 0; i < seg.length; i++) {
                if (seg[i].v < 0.5) continue;
                const t1 = i + 1 < seg.length ? seg[i + 1].t : seg[i].t + root.step;
                d += "M " + root.xOf(seg[i].t).toFixed(1) + " 0 H " + root.xOf(t1).toFixed(1) + " V " + h + " H " + root.xOf(seg[i].t).toFixed(1) + " Z ";
            }
        }
        return d;
    }

    // Base: una linea tenue (se ve aunque no haya datos).
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Colors.divider
    }
    Shape {
        anchors.fill: parent
        visible: root.enough || root.mode === "strip"
        // Lineas rectas: el renderizador de geometria (el de curvas cuesta mas y no hace falta).
        preferredRendererType: Shape.GeometryRenderer
        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillColor: root.mode === "strip" ? Colors.tint(root.color, Tokens.tint.hairline) : Colors.tint(root.color, Tokens.tint.track)
            PathSvg { path: root.mode === "strip" ? root.stripPath(root.series) : root.fillPath(root.series) }
        }
        ShapePath {
            strokeWidth: root.mode === "strip" ? 0 : 1.5
            strokeColor: root.mode === "strip" ? "transparent" : root.color
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathSvg { path: root.mode === "strip" ? "" : root.linePath(root.series) }
        }
        ShapePath {
            strokeWidth: root.series2 && root.series2.length ? 1.5 : 0
            strokeColor: root.series2 && root.series2.length ? root.color2 : "transparent"
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathSvg { path: root.mode === "strip" ? "" : root.linePath(root.series2) }
        }
    }
    Text {
        visible: !root.enough && root.mode !== "strip"
        anchors.centerIn: parent
        text: "Midiendo…"
        color: Colors.border
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.caption
    }

    function ago(ms: real): string {
        return ms < 5000 ? "ahora" : ms < 60000 ? "hace " + Math.round(ms / 1000) + " s" : "hace " + Math.round(ms / 60000) + " min";
    }
    // Al pasar el raton: una regla y el valor de esa muestra ("38 % · hace 1 min").
    HoverHandler { id: hover }
    readonly property var picked: {
        if (!hover.hovered || !root.enough) return null;
        const a = root.series;
        const t = root.last - root.span + hover.point.position.x / Math.max(1, root.width) * root.span;
        let best = null;
        for (const p of a) if (!best || Math.abs(p.t - t) < Math.abs(best.t - t)) best = p;
        return best;
    }
    Rectangle {
        visible: !!root.picked
        x: root.picked ? root.xOf(root.picked.t) : 0
        width: 1
        height: root.height
        color: Colors.textMuted
    }
    Text {
        visible: !!root.picked
        anchors.top: parent.top
        anchors.right: parent.right
        text: root.picked ? root.format(root.picked.v) + " · " + root.ago(root.last - root.picked.t) : ""
        color: Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.caption
        font.features: Tokens.tabularNumbers
    }
}
