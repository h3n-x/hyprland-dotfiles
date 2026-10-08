// Ajustes rapidos del centro de control (Fase 11 B6, P11.7): la lista
// controlCenter.tiles = [{id, size}] (en orden) y su unico editor, en el
// centro de control mismo (como las zonas de Inicio: HomeZones).
//
// Tamanos: small = el cuadrado de siempre (1 de 5 columnas), wide = dos
// columnas con nombre y estado, row = el ancho entero (el selector de perfil
// y el interruptor de No molestar, como estaban). Las filas siguen el orden;
// entre dos filas de cuadrados hay space.sm, alrededor de una fila space.md:
// de fabrica queda identico al de antes. Un ajuste que el equipo no tiene
// (sin Bluetooth, sin hyprpicker...) no se muestra ni se ofrece.
//
// Edicion (lapiz al pasar el raton, como en Inicio, o "controlcenter edit"): contorno punteado,
// arrastrar ordena, el boton de tamano, la cruz; abajo, "Agregar". Teclado:
// Tab elige, flechas mueven, T tamano, Supr quita, A agrega (flechas + Enter),
// Esc / Enter terminan. Se guarda al soltar.
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import ".." // Colors.qml, Tokens.qml, SettingsState.qml, QuickTiles.qml, ControlCenterState.qml

Item {
    id: grid

    readonly property bool editing: ControlCenterState.editing
    readonly property var spec: (SettingsState.meta("controlCenter.tiles") || {}).widgets || ({})
    readonly property var stored: SettingsState.value("controlCenter.tiles") || []
    property var work: null
    function availableId(id: string): bool {
        const t = QuickTiles.get(id);
        return !!grid.spec[id] && !!t && t.available;
    }
    readonly property var list: (grid.work || grid.stored).filter(t => grid.availableId(t.id))
    readonly property var order: grid.list.map(t => t.id)
    readonly property var unplaced: Object.keys(grid.spec).filter(id => grid.availableId(id) && !grid.list.some(t => t.id === id))

    readonly property int columns: 5
    readonly property int gap: Tokens.space.sm
    readonly property real cell: (grid.width - (grid.columns - 1) * grid.gap) / grid.columns
    function units(size: string): int {
        return size === "row" ? grid.columns : size === "wide" ? 2 : 1;
    }

    // ---- Geometria: filas en orden; anchos de las filas, altos de lo que pide cada uno ----
    readonly property var rows: {
        const out = [];
        let row = [], used = 0;
        for (const t of grid.list) {
            const u = grid.units(t.size);
            if (row.length && used + u > grid.columns) {
                out.push(row);
                row = [];
                used = 0;
            }
            row.push(t);
            used += u;
            if (t.size === "row") {
                out.push(row);
                row = [];
                used = 0;
            }
        }
        if (row.length) out.push(row);
        return out;
    }
    property var ideals: ({})
    function report(id: string, h: real): void {
        if (grid.ideals[id] === h) return;
        const n = Object.assign({}, grid.ideals);
        n[id] = h;
        grid.ideals = n;
    }
    readonly property var geom: {
        const g = {};
        let y = 0, prevTiles = null;
        for (const row of grid.rows) {
            const tiles = row[0].size !== "row";
            if (prevTiles !== null) y += prevTiles && tiles ? grid.gap : Tokens.space.md;
            let c = 0, h = 0;
            for (const t of row) {
                const u = grid.units(t.size);
                // Bordes de columna redondeados como los reparte GridLayout (iguales al pixel a los de antes).
                const x = Math.round(c * (grid.cell + grid.gap));
                const w = t.size === "row" ? grid.width : Math.round((c + u) * (grid.cell + grid.gap)) - grid.gap - x;
                // La fila de No molestar va con su margen de siempre.
                const inset = t.id === "dnd" && t.size === "row" ? Tokens.space.xs : 0;
                g[t.id] = { x: x + inset, y: y, w: w - inset };
                c += u;
                h = Math.max(h, grid.ideals[t.id] || Tokens.row.heightLarge);
            }
            for (const t of row) g[t.id].h = h;
            y += h;
            prevTiles = tiles;
        }
        g.height = y;
        return g;
    }

    implicitHeight: grid.geom.height + (grid.editing ? Tokens.space.md + tray.implicitHeight : 0)

    // ---- Edicion --------------------------------------------------------------------
    property string selected: ""
    property int trayIndex: -1
    onEditingChanged: {
        grid.work = null;
        grid.trayIndex = -1;
        grid.selected = grid.editing && grid.order.length ? grid.order[0] : "";
    }
    function save(l: var): void {
        // Lo que no esta disponible en este equipo se conserva en su lugar.
        const kept = grid.stored.filter(t => !grid.availableId(t.id));
        SettingsState.set("controlCenter.tiles", l.map(t => ({ id: t.id, size: t.size })).concat(kept));
    }
    function move(id: string, to: int): void {
        const l = grid.list.slice();
        const from = l.findIndex(t => t.id === id);
        if (from < 0 || to < 0 || to >= l.length || to === from) return;
        const [it] = l.splice(from, 1);
        l.splice(to, 0, it);
        grid.save(l);
    }
    function resize(id: string): void {
        const sizes = (grid.spec[id] || {}).sizes || [];
        if (sizes.length < 2) return;
        grid.save(grid.list.map(t => t.id === id ? { id: t.id, size: sizes[(sizes.indexOf(t.size) + 1) % sizes.length] } : t));
    }
    function remove(id: string): void {
        const i = grid.order.indexOf(id);
        const rest = grid.order.filter(x => x !== id);
        grid.save(grid.list.filter(t => t.id !== id));
        if (grid.selected === id) grid.selected = rest.length ? rest[Math.min(i, rest.length - 1)] : "";
    }
    function add(id: string): void {
        const sizes = (grid.spec[id] || {}).sizes || ["small"];
        // Los que tambien son fila entran como cuadrado (la fila se elige con el tamano).
        grid.save(grid.list.concat([{ id: id, size: sizes.indexOf("small") >= 0 ? "small" : sizes[0] }]));
        grid.selected = id;
    }
    function handleKey(event: var): bool {
        const k = event.key;
        if (grid.trayIndex >= 0) {
            const n = grid.unplaced.length;
            if (k === Qt.Key_Left || k === Qt.Key_Up) grid.trayIndex = (grid.trayIndex - 1 + n) % n;
            else if (k === Qt.Key_Right || k === Qt.Key_Down) grid.trayIndex = (grid.trayIndex + 1) % n;
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                grid.add(grid.unplaced[grid.trayIndex]);
                grid.trayIndex = -1;
            } else if (k === Qt.Key_Tab || k === Qt.Key_Backtab || k === Qt.Key_Escape) grid.trayIndex = -1;
            return true;
        }
        const o = grid.order;
        const i = o.indexOf(grid.selected);
        if (k === Qt.Key_Tab || k === Qt.Key_Backtab) {
            if (o.length) grid.selected = o[i < 0 ? 0 : (i + (k === Qt.Key_Backtab ? -1 : 1) + o.length) % o.length];
        } else if (k === Qt.Key_Left || k === Qt.Key_Up) {
            if (i > 0) grid.move(grid.selected, i - 1);
        } else if (k === Qt.Key_Right || k === Qt.Key_Down) {
            if (i >= 0) grid.move(grid.selected, i + 1);
        } else if (k === Qt.Key_T) {
            if (i >= 0) grid.resize(grid.selected);
        } else if (k === Qt.Key_Delete || k === Qt.Key_Backspace) {
            if (i >= 0) grid.remove(grid.selected);
        } else if (k === Qt.Key_A) {
            if (grid.unplaced.length) grid.trayIndex = 0;
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Escape) {
            ControlCenterState.editing = false;
        }
        return true;
    }

    property string dragging: ""
    function dragTo(id: string, cx: real, cy: real): void {
        for (const other of grid.order) {
            if (other === id) continue;
            const g = grid.geom[other];
            if (g && cx >= g.x && cx <= g.x + g.w && cy >= g.y && cy <= g.y + g.h) {
                const l = (grid.work || grid.list).slice();
                const from = l.findIndex(t => t.id === id);
                const to = l.findIndex(t => t.id === other);
                const [it] = l.splice(from, 1);
                l.splice(to, 0, it);
                grid.work = l;
                return;
            }
        }
    }

    // ---- Un lugar estable por ajuste del registro (reordenar solo los mueve) ----
    Repeater {
        id: slots
        model: Object.keys(grid.spec)
        Item {
            id: slot
            required property string modelData
            readonly property var g: grid.geom[slot.modelData]
            readonly property var meta: grid.spec[slot.modelData] || ({})
            readonly property var tile: QuickTiles.get(slot.modelData)
            readonly property string size: (grid.list.find(t => t.id === slot.modelData) || {}).size || ""
            readonly property bool moving: grid.dragging === slot.modelData
            property real dragX: 0
            property real dragY: 0
            visible: !!slot.g
            z: slot.moving ? 2 : 0
            x: slot.moving ? slot.dragX : slot.g ? slot.g.x : 0
            y: slot.moving ? slot.dragY : slot.g ? slot.g.y : 0
            width: slot.g ? slot.g.w : 0
            height: slot.g ? slot.g.h : 0
            Behavior on x { enabled: grid.editing && !slot.moving && Tokens.motion.scale > 0; NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            Behavior on y { enabled: grid.editing && !slot.moving && Tokens.motion.scale > 0; NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }

            Loader {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: slot.size === "row" ? implicitHeight : parent.height
                active: !!slot.g && !!slot.tile
                enabled: !grid.editing
                opacity: grid.editing ? Tokens.tint.well : 1
                Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }
                sourceComponent: slot.size !== "row" ? tileC : slot.modelData === "profile" ? profileC : dndC
                // El alto que pide, a la vuelta siguiente: su ancho sale de la geometria (sin bucle).
                readonly property real ideal: slot.size === "row" ? content.implicitHeight : Tokens.row.heightLarge
                onIdealChanged: Qt.callLater(() => grid.report(slot.modelData, content.ideal))
                onLoaded: Qt.callLater(() => grid.report(slot.modelData, content.ideal))
            }
            Component {
                id: tileC
                QuickTile {
                    icon: slot.tile.icon
                    active: slot.tile.active
                    wide: slot.size === "wide"
                    label: slot.meta.label || slot.modelData
                    status: slot.tile.status
                    onClicked: slot.tile.toggle()
                }
            }
            Component { id: profileC; ProfileRow {} }
            Component { id: dndC; DndRow {} }

            // ---- Edicion: contorno, arrastre, tamano y quitar ----
            Item {
                anchors.fill: parent
                anchors.margins: -2
                visible: opacity > 0
                opacity: grid.editing ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: grid.selected === slot.modelData || slot.moving ? Colors.accent : Colors.border
                        strokeWidth: 1.5
                        strokeStyle: ShapePath.DashLine
                        dashPattern: [4, 3]
                        fillColor: slot.moving ? Colors.tint(Colors.text, Tokens.stateLayer.dragged) : "transparent"
                        PathRectangle { x: 1; y: 1; width: slot.width + 2; height: slot.height + 2; radius: Tokens.radius.md }
                    }
                }
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    enabled: grid.editing
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property point origin
                    property point start
                    onPressed: (m) => {
                        grid.selected = slot.modelData;
                        grid.trayIndex = -1;
                        dragArea.origin = Qt.point(slot.x, slot.y);
                        dragArea.start = dragArea.mapToItem(grid, m.x, m.y);
                        slot.dragX = slot.x;
                        slot.dragY = slot.y;
                        grid.work = grid.list.slice();
                        grid.dragging = slot.modelData;
                    }
                    onPositionChanged: (m) => {
                        if (!pressed) return;
                        const p = dragArea.mapToItem(grid, m.x, m.y);
                        slot.dragX = dragArea.origin.x + p.x - dragArea.start.x;
                        slot.dragY = dragArea.origin.y + p.y - dragArea.start.y;
                        grid.dragTo(slot.modelData, p.x, p.y);
                    }
                    onReleased: {
                        const l = grid.work;
                        grid.dragging = "";
                        grid.work = null;
                        if (l) grid.save(l);
                    }
                    onCanceled: {
                        grid.dragging = "";
                        grid.work = null;
                    }
                }
                // Tamano y quitar (los cuadrados son chicos: los botones van en la esquina, encima).
                Row {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: -Tokens.space.xs
                    spacing: 2
                    EditButton {
                        visible: (slot.meta.sizes || []).length > 1
                        scale: 0.8
                        icon: slot.size === "row" ? "width_normal" : slot.size === "wide" ? "view_agenda" : "width_wide"
                        onClicked: grid.resize(slot.modelData)
                    }
                    EditButton {
                        scale: 0.8
                        icon: "close"
                        onClicked: grid.remove(slot.modelData)
                    }
                }
            }
        }
    }

    // Lapiz (fuera de la edicion): arriba a la derecha, solo al pasar el raton (no ocupa lugar).
    HoverHandler { id: hover }
    EditButton {
        objectName: "editTiles"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: -Tokens.space.xs
        z: 3
        visible: opacity > 0
        opacity: !grid.editing && hover.hovered && grid.order.length > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Tokens.motion.fast } }
        icon: "edit"
        onClicked: ControlCenterState.editing = true
    }

    // ---- Agregar (solo en la edicion) --------------------------------------------------
    ColumnLayout {
        id: tray
        y: grid.geom.height + Tokens.space.md
        width: grid.width
        visible: grid.editing
        spacing: Tokens.space.sm
        Flow {
            Layout.fillWidth: true
            spacing: Tokens.space.xs
            Text {
                height: 28
                verticalAlignment: Text.AlignVCenter
                text: grid.unplaced.length ? "Agregar" : "Están todos"
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.weight: Tokens.weight.medium
            }
            Repeater {
                model: grid.unplaced
                Rectangle {
                    id: chip
                    required property string modelData
                    required property int index
                    readonly property var meta: grid.spec[chip.modelData] || ({})
                    readonly property bool picked: grid.trayIndex === chip.index
                    height: 28
                    width: chipRow.implicitWidth + Tokens.space.md * 2
                    radius: 14
                    color: "transparent"
                    border.width: chip.picked ? Tokens.focusRingWidth : 1
                    border.color: chip.picked ? Colors.accent : Colors.divider
                    StateLayer { hovered: chipMouse.containsMouse; pressed: chipMouse.pressed }
                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: Tokens.space.xs
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: chip.meta.icon || ""; size: Tokens.icon.sm; color: Colors.text }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.meta.label || chip.modelData
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.caption
                            font.weight: Tokens.weight.medium
                        }
                    }
                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: grid.add(chip.modelData)
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: grid.trayIndex >= 0 ? "Flechas eligen · Enter agrega · Esc vuelve" : "Arrastra · Tab elige · flechas mueven · T tamaño · Supr quita · A agrega"
                color: Colors.border
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                wrapMode: Text.WordWrap
            }
            Button {
                label: "Listo"
                icon: "check"
                main: true
                onClicked: ControlCenterState.editing = false
            }
        }
    }
}
