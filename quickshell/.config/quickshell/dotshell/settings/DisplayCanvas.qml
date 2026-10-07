// Disposicion de las pantallas (Fase 10 B5): cada una a su tamano logico
// (resolucion / escala, girada si va de costado), arrastrable; al soltarla se
// pega al borde de otra si queda cerca (48 px logicos) y emite moved(nombre, x,
// y). Dos que se pisan se marcan con el color fijo de peligro y `overlap`
// impide aplicar. Colores neutros: arrastrar es un estado, no identidad (P8.7).
import QtQuick
import ".." // Colors.qml, Tokens.qml
import "../modules"

Item {
    id: canvas

    // [{name, size "WxH", scale, transform, x, y, enabled}]
    property var items: []
    signal moved(string name, int x, int y)

    function box(v: var): var {
        const p = v.size.split("x").map(Number);
        let w = p[0] / v.scale, h = p[1] / v.scale;
        if (v.transform % 2 === 1) [w, h] = [h, w];
        return { name: v.name, x: v.x, y: v.y, w: Math.round(w), h: Math.round(h) };
    }
    readonly property var boxes: canvas.items.filter(v => v.enabled && !v.mirror).map(v => canvas.box(v))
    readonly property var bounds: {
        if (!canvas.boxes.length) return { x: 0, y: 0, w: 1, h: 1 };
        const x0 = Math.min(...canvas.boxes.map(b => b.x)), y0 = Math.min(...canvas.boxes.map(b => b.y));
        const x1 = Math.max(...canvas.boxes.map(b => b.x + b.w)), y1 = Math.max(...canvas.boxes.map(b => b.y + b.h));
        return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
    }
    readonly property real factor: Math.min((canvas.width - 2 * Tokens.space.xl) / canvas.bounds.w, (canvas.height - 2 * Tokens.space.lg) / canvas.bounds.h)
    readonly property real offX: (canvas.width - canvas.bounds.w * canvas.factor) / 2
    readonly property real offY: (canvas.height - canvas.bounds.h * canvas.factor) / 2

    function hits(a: var, b: var): bool {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    }
    readonly property var overlapping: canvas.boxes.filter(a => canvas.boxes.some(b => b.name !== a.name && canvas.hits(a, b))).map(a => a.name)
    readonly property bool overlap: canvas.overlapping.length > 0

    // Posicion logica al soltar, pegada al borde mas cercano de otra pantalla.
    function snap(b: var, x: real, y: real): var {
        let bx = x, by = y, dx = 48, dy = 48;
        for (const o of canvas.boxes) {
            if (o.name === b.name) continue;
            for (const cx of [o.x + o.w, o.x - b.w, o.x, o.x + o.w - b.w])
                if (Math.abs(cx - x) < dx) { dx = Math.abs(cx - x); bx = cx; }
            for (const cy of [o.y, o.y + o.h, o.y - b.h, o.y + o.h - b.h])
                if (Math.abs(cy - y) < dy) { dy = Math.abs(cy - y); by = cy; }
        }
        return [Math.round(bx), Math.round(by)];
    }

    implicitHeight: 200

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radius.lg
        color: Colors.tint(Colors.surfaceHighest, Tokens.tint.well)
    }

    Repeater {
        model: canvas.boxes
        Rectangle {
            id: r
            required property var modelData
            readonly property bool bad: canvas.overlapping.indexOf(r.modelData.name) >= 0
            x: canvas.offX + (r.modelData.x - canvas.bounds.x) * canvas.factor
            y: canvas.offY + (r.modelData.y - canvas.bounds.y) * canvas.factor
            width: r.modelData.w * canvas.factor
            height: r.modelData.h * canvas.factor
            radius: Tokens.radius.sm
            color: Colors.surfaceHigh
            border.width: r.bad || drag.pressed ? 2 : 1
            border.color: r.bad ? Colors.danger : drag.pressed ? Colors.text : Colors.divider
            z: drag.pressed ? 2 : 1
            Text {
                anchors.centerIn: parent
                text: r.modelData.name + "\n" + r.modelData.w + " × " + r.modelData.h
                horizontalAlignment: Text.AlignHCenter
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
            MouseArea {
                id: drag
                anchors.fill: parent
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: r
                onReleased: {
                    const lx = (r.x - canvas.offX) / canvas.factor + canvas.bounds.x;
                    const ly = (r.y - canvas.offY) / canvas.factor + canvas.bounds.y;
                    const p = canvas.snap(r.modelData, lx, ly);
                    canvas.moved(r.modelData.name, p[0], p[1]);
                }
            }
        }
    }
}
