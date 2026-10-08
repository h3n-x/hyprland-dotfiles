// Zonas de Inicio (Fase 11 B4, P11.5): lo que va debajo de la hora y la musica,
// como datos (dashboard.home.zones = [{id, size}], en orden). Los widgets que
// existen y sus tamanos estan en el registro del esquema (widgets de
// dashboard.home.zones); cada uno carga solo mientras esta puesto.
//
// Filas: compacta + ancha (272 + el resto, como Sistema + Escritorios desde
// B7), ancha sola, dos compactas mitad y mitad; una sola en la fila ocupa
// todo. Angosto: una por fila. El alto de una fila es el de su zona mas alta
// (148 como minimo, salvo angosto).
//
// Modo edicion (el unico editor; el centro de configuracion solo lleva aca):
// lapiz al pasar el raton, Ctrl+E o "Editar Inicio". Cada zona con contorno
// punteado: arrastrar ordena (las demas se corren), el boton de tamano y la
// cruz; abajo, lo que se puede agregar. Teclado: Tab elige zona, flechas la
// mueven, T tamano, Supr la quita, A va a "Agregar" (flechas + Enter),
// Esc / Enter / Ctrl+E terminan. Todo se guarda en el almacen al soltar.
//
// Fase 11 B5: un widget es una entrada del registro + un Component en
// `components` (id -> Component; los de Inicio mismo, la linea de contexto y
// el reproductor, llegan en `external`). Tamano "full": siempre sola en su
// fila; "bare": sin el tinte de zona ni margen ni alto minimo (la linea de
// contexto, el reproductor con su propio fondo). Una zona abre su vista (`view`), hace su
// accion (`action`: "avatar" lleva a Configuracion) o, si su contenido es
// interactivo (Notas, Tareas, Accesos rapidos), no es clicable. Los campos de
// texto de una zona se quedan con sus teclas; Esc los deja (fieldDone: el
// dashboard recupera el foco).
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import ".." // Colors.qml, Tokens.qml, SettingsState.qml, DashboardState.qml, DesktopState.qml, WeatherState.qml

Item {
    id: zones
    // El dashboard se ve (datos y animaciones).
    property bool active: false
    property bool narrow: false
    property string screenName: ""
    // Zona con el anillo de foco de Inicio ("" = ninguna).
    property string focusKey: ""
    readonly property bool editing: DashboardState.editing
    // Avance de "hay musica" (0..1, DashboardHome): el reproductor se pliega con el.
    property real mediaP: 0
    // Componentes que da Inicio (context, media).
    property var external: ({})
    // Abrir la vista de una zona (y de cual sale, para la transicion).
    signal openView(string view, string from)
    // Un campo de texto de una zona se dejo (Esc): el foco vuelve al dashboard.
    signal fieldDone()

    readonly property var spec: (SettingsState.meta("dashboard.home.zones") || {}).widgets || ({})
    readonly property var stored: SettingsState.value("dashboard.home.zones") || []
    // Copia de trabajo mientras se arrastra (las demas zonas se corren); se guarda al soltar.
    property var work: null
    readonly property var list: (zones.work || zones.stored).filter(z => !!zones.spec[z.id])
    function usable(id: string): bool {
        const needs = (zones.spec[id] || {}).needs;
        return needs === "weather" ? WeatherState.configured : needs === "now" ? !!NowState.item : needs === "media" ? zones.mediaP > 0 : true;
    }
    // Fuera de la edicion, una zona que no puede mostrar nada (Proximas horas sin ciudad) no ocupa lugar.
    readonly property var shown: zones.editing ? zones.list : zones.list.filter(z => zones.usable(z.id))
    readonly property var order: zones.shown.map(z => z.id)
    readonly property var unplaced: Object.keys(zones.spec).filter(id => !zones.list.some(z => z.id === id))

    readonly property int gap: Tokens.space.md
    readonly property int compactWidth: 272
    readonly property int baseHeight: 148

    // ---- Geometria ------------------------------------------------------------------
    // Primero filas y anchos (no dependen de los altos); despues los altos, con
    // lo que cada zona pide para su ancho (ideal).
    readonly property var rows: {
        const out = [];
        const l = zones.shown;
        const W = zones.width;
        for (let i = 0; i < l.length;) {
            const a = l[i], b = l[i + 1];
            if (!zones.narrow && b && a.size !== "full" && b.size !== "full" && !(a.size === "wide" && b.size === "wide")) {
                let wa, wb;
                if (a.size === b.size) {
                    wa = Math.floor((W - zones.gap) / 2);
                    wb = W - zones.gap - wa;
                } else if (a.size === "compact") {
                    wa = zones.compactWidth;
                    wb = W - zones.gap - wa;
                } else {
                    wb = zones.compactWidth;
                    wa = W - zones.gap - wb;
                }
                out.push([{ id: a.id, x: 0, w: wa }, { id: b.id, x: wa + zones.gap, w: wb }]);
                i += 2;
            } else {
                out.push([{ id: a.id, x: 0, w: W }]);
                i += 1;
            }
        }
        return out;
    }
    // Ancho y x de cada zona (solo de las filas): el alto que pide una zona depende
    // de su ancho, nunca de la geometria entera (si no, bucle de enlaces).
    readonly property var cols: {
        const c = {};
        for (const row of zones.rows)
            for (const z of row) c[z.id] = z;
        return c;
    }
    property var ideals: ({})
    function report(id: string, h: real): void {
        if (zones.ideals[id] === h) return;
        const n = Object.assign({}, zones.ideals);
        n[id] = h;
        zones.ideals = n;
    }
    readonly property var geom: {
        const g = {};
        let y = 0;
        for (const row of zones.rows) {
            const bare = row.every(c => (zones.spec[c.id] || {}).bare);
            let h = zones.narrow || bare ? 0 : zones.baseHeight;
            for (const c of row) h = Math.max(h, zones.ideals[c.id] !== undefined ? zones.ideals[c.id] : zones.baseHeight);
            for (const c of row) g[c.id] = { x: c.x, y: y, w: c.w, h: h };
            y += h + zones.gap;
        }
        g.height = Math.max(0, y - zones.gap);
        return g;
    }
    function rectOf(id: string, target: Item): rect {
        const s = slots.itemAt(Object.keys(zones.spec).indexOf(id));
        if (!s || !zones.geom[id]) return Qt.rect(0, 0, 0, 0);
        const p = s.mapToItem(target, 0, 0);
        return Qt.rect(p.x, p.y, s.width, s.height);
    }
    // La zona que lleva a una vista (para la transicion de contenedor): la ultima tocada, o la primera.
    property string lastFrom: ""
    function zoneFor(view: string): string {
        if (zones.lastFrom && zones.geom[zones.lastFrom] && (zones.spec[zones.lastFrom] || {}).view === view) return zones.lastFrom;
        return zones.order.find(id => (zones.spec[id] || {}).view === view) || "";
    }

    implicitHeight: zones.geom.height + (zones.editing ? zones.gap + tray.implicitHeight : 0)

    // ---- Abrir una zona -------------------------------------------------------------
    // Abre algo (vista o accion) o no: las de contenido interactivo no.
    function opens(id: string): bool {
        const m = zones.spec[id] || {};
        return !!(m.view || m.action);
    }
    // Clic o Enter: su vista, su accion o, si tiene un campo, entrar a escribir.
    function activate(id: string): bool {
        const m = zones.spec[id] || {};
        if (m.view) {
            zones.lastFrom = id;
            zones.openView(m.view, id);
            return true;
        }
        if (m.action === "avatar") {
            DashboardState.close();
            Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/settings-ui", "open", "appearance.avatar"]);
            return true;
        }
        const s = slots.itemAt(Object.keys(zones.spec).indexOf(id));
        if (s && s.widget && s.widget.focusField) {
            s.widget.focusField();
            return true;
        }
        return false;
    }

    // ---- Edicion --------------------------------------------------------------------
    property string selected: ""
    // A: elegir que agregar (indice en unplaced; -1 = no).
    property int trayIndex: -1
    onEditingChanged: {
        zones.work = null;
        zones.trayIndex = -1;
        zones.selected = zones.editing && zones.order.length ? zones.order[0] : "";
    }
    function save(l: var): void {
        SettingsState.set("dashboard.home.zones", l.map(z => ({ id: z.id, size: z.size })));
    }
    function move(id: string, to: int): void {
        const l = zones.list.slice();
        const from = l.findIndex(z => z.id === id);
        if (from < 0 || to < 0 || to >= l.length || to === from) return;
        const [it] = l.splice(from, 1);
        l.splice(to, 0, it);
        zones.save(l);
    }
    function resize(id: string): void {
        const sizes = (zones.spec[id] || {}).sizes || [];
        if (sizes.length < 2) return;
        zones.save(zones.list.map(z => z.id === id ? { id: z.id, size: sizes[(sizes.indexOf(z.size) + 1) % sizes.length] } : z));
    }
    function remove(id: string): void {
        const i = zones.order.indexOf(id);
        const rest = zones.order.filter(x => x !== id);
        zones.save(zones.list.filter(z => z.id !== id));
        if (zones.selected === id) zones.selected = rest.length ? rest[Math.min(i, rest.length - 1)] : "";
    }
    function add(id: string): void {
        const sizes = (zones.spec[id] || {}).sizes || ["wide"];
        zones.save(zones.list.concat([{ id: id, size: sizes[0] }]));
        zones.selected = id;
    }
    function handleKey(event: var): bool {
        const k = event.key;
        if (k === Qt.Key_E && (event.modifiers & Qt.ControlModifier)) {
            DashboardState.editing = false;
            return true;
        }
        if (zones.trayIndex >= 0) {
            const n = zones.unplaced.length;
            if (k === Qt.Key_Left || k === Qt.Key_Up) zones.trayIndex = (zones.trayIndex - 1 + n) % n;
            else if (k === Qt.Key_Right || k === Qt.Key_Down) zones.trayIndex = (zones.trayIndex + 1) % n;
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                zones.add(zones.unplaced[zones.trayIndex]);
                zones.trayIndex = -1;
            } else if (k === Qt.Key_Tab || k === Qt.Key_Backtab) zones.trayIndex = -1;
            return true;
        }
        const o = zones.order;
        const i = o.indexOf(zones.selected);
        if (k === Qt.Key_Tab || k === Qt.Key_Backtab) {
            if (o.length) zones.selected = o[i < 0 ? 0 : (i + (k === Qt.Key_Backtab ? -1 : 1) + o.length) % o.length];
        } else if (k === Qt.Key_Left || k === Qt.Key_Up) {
            if (i > 0) zones.move(zones.selected, i - 1);
        } else if (k === Qt.Key_Right || k === Qt.Key_Down) {
            if (i >= 0) zones.move(zones.selected, i + 1);
        } else if (k === Qt.Key_T) {
            if (i >= 0) zones.resize(zones.selected);
        } else if (k === Qt.Key_Delete || k === Qt.Key_Backspace) {
            if (i >= 0) zones.remove(zones.selected);
        } else if (k === Qt.Key_A) {
            if (zones.unplaced.length) zones.trayIndex = 0;
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            DashboardState.editing = false;
        }
        // En edicion ninguna otra tecla hace nada (ni las letras de las vistas).
        return true;
    }
    // Esc: primero deja "Agregar", despues termina.
    function leave(): void {
        if (zones.trayIndex >= 0) zones.trayIndex = -1;
        else DashboardState.editing = false;
    }

    // ---- Arrastre ------------------------------------------------------------------
    property string dragging: ""
    function dragTo(id: string, cx: real, cy: real): void {
        for (const other of zones.order) {
            if (other === id) continue;
            const g = zones.geom[other];
            if (cx >= g.x && cx <= g.x + g.w && cy >= g.y && cy <= g.y + g.h) {
                const l = (zones.work || zones.list).slice();
                const from = l.findIndex(z => z.id === id);
                const to = l.findIndex(z => z.id === other);
                const [it] = l.splice(from, 1);
                l.splice(to, 0, it);
                zones.work = l;
                return;
            }
        }
    }

    // Lapiz: aparece al pasar el raton por las zonas (no ocupa lugar).
    HoverHandler { id: hover }

    // ---- Zonas: una por widget del registro (estables: reordenar solo las mueve) ----
    Repeater {
        id: slots
        model: Object.keys(zones.spec)
        Item {
            id: slot
            required property string modelData
            required property int index
            readonly property var g: zones.geom[slot.modelData]
            readonly property var meta: zones.spec[slot.modelData] || ({})
            readonly property bool placed: !!slot.g
            readonly property bool moving: zones.dragging === slot.modelData
            property real dragX: 0
            property real dragY: 0
            visible: slot.placed
            z: slot.moving ? 2 : 0
            readonly property var col: zones.cols[slot.modelData]
            readonly property Item widget: content.item
            x: slot.moving ? slot.dragX : slot.col ? slot.col.x : 0
            y: slot.moving ? slot.dragY : slot.g ? slot.g.y : 0
            width: slot.col ? slot.col.w : 0
            height: slot.g ? slot.g.h : 0
            // Al reordenar en la edicion, las zonas se deslizan a su lugar.
            Behavior on x { enabled: zones.editing && !slot.moving && Tokens.motion.scale > 0; NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            Behavior on y { enabled: zones.editing && !slot.moving && Tokens.motion.scale > 0; NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            Behavior on width { enabled: zones.editing && Tokens.motion.scale > 0; NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }

            DashZone {
                id: zone
                anchors.fill: parent
                focused: zones.editing ? zones.selected === slot.modelData : zones.focusKey === slot.modelData
                clickable: !zones.editing && zones.opens(slot.modelData)
                tinted: !slot.meta.bare
                padding: slot.meta.bare ? 0 : Tokens.space.lg
                onActivated: zones.activate(slot.modelData)
                Loader {
                    id: content
                    anchors.fill: parent
                    active: !!slot.col
                    enabled: !zones.editing
                    // Editando: apenas visible, el nombre de la zona encima.
                    opacity: zones.editing ? Tokens.tint.track : 1
                    Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }
                    // Sin ciudad, el aviso; Ahora sin nada (solo en la edicion) se muestra a si misma.
                    sourceComponent: !zones.usable(slot.modelData) && slot.meta.needs === "weather" ? needsC : zones.components[slot.modelData] || null
                    // Lo que la zona pide de alto para su ancho.
                    readonly property real ideal: content.item && content.item.ideal !== undefined ? content.item.ideal + 2 * zone.padding : zones.baseHeight
                    onIdealChanged: zones.report(slot.modelData, content.ideal)
                    Component.onCompleted: zones.report(slot.modelData, content.ideal)
                }
            }

            // ---- Edicion: contorno punteado, nombre, tamano y quitar ----
            Item {
                anchors.fill: parent
                visible: opacity > 0
                opacity: zones.editing ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: slot.moving ? Colors.accent : Colors.border
                        strokeWidth: 1.5
                        strokeStyle: ShapePath.DashLine
                        dashPattern: [4, 3]
                        fillColor: slot.moving ? Colors.tint(Colors.text, Tokens.stateLayer.dragged) : "transparent"
                        PathRectangle { x: 1; y: 1; width: slot.width - 2; height: slot.height - 2; radius: Tokens.radius.md }
                    }
                }
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    enabled: zones.editing
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property point origin
                    property point start
                    onPressed: (m) => {
                        zones.selected = slot.modelData;
                        zones.trayIndex = -1;
                        dragArea.origin = Qt.point(slot.x, slot.y);
                        dragArea.start = dragArea.mapToItem(zones, m.x, m.y);
                        slot.dragX = slot.x;
                        slot.dragY = slot.y;
                        zones.work = zones.list.slice();
                        zones.dragging = slot.modelData;
                    }
                    onPositionChanged: (m) => {
                        if (!pressed) return;
                        const p = dragArea.mapToItem(zones, m.x, m.y);
                        slot.dragX = dragArea.origin.x + p.x - dragArea.start.x;
                        slot.dragY = dragArea.origin.y + p.y - dragArea.start.y;
                        zones.dragTo(slot.modelData, p.x, p.y);
                    }
                    onReleased: {
                        const l = zones.work;
                        zones.dragging = "";
                        zones.work = null;
                        if (l) zones.save(l);
                    }
                    onCanceled: {
                        zones.dragging = "";
                        zones.work = null;
                    }
                }
                // Nombre al centro, sobre el contenido atenuado.
                Rectangle {
                    anchors.centerIn: parent
                    implicitHeight: 36
                    implicitWidth: nameRow.implicitWidth + Tokens.space.lg * 2
                    radius: 18
                    color: Colors.surfaceHigh
                    Row {
                        id: nameRow
                        anchors.centerIn: parent
                        spacing: Tokens.space.sm
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: slot.meta.icon || ""; size: Tokens.icon.md; color: Colors.text }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (slot.meta.label || slot.modelData) + (zones.usable(slot.modelData) ? ""
                                : slot.meta.needs === "now" ? " · aparece cuando hay algo"
                                : slot.meta.needs === "media" ? " · aparece mientras suena algo" : " · necesita una ciudad")
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: Tokens.weight.medium
                        }
                    }
                }
                // Tamano y quitar, arriba a la derecha.
                Row {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.space.sm
                    spacing: Tokens.space.xs
                    EditButton {
                        visible: (slot.meta.sizes || []).length > 1 && !zones.narrow
                        icon: slot.g && zones.shown.find(z => z.id === slot.modelData)?.size === "wide" ? "width_normal" : "width_wide"
                        onClicked: zones.resize(slot.modelData)
                    }
                    EditButton {
                        icon: "close"
                        onClicked: zones.remove(slot.modelData)
                    }
                }
            }
        }
    }

    // Lapiz (fuera de la edicion): arriba a la derecha de la primera zona con
    // superficie (no sobre el clima de la linea de contexto), solo al pasar el raton.
    readonly property string pencilZone: zones.order.find(id => !(zones.spec[id] || {}).bare) || ""
    readonly property var pencilAt: zones.pencilZone && zones.geom[zones.pencilZone] ? zones.geom[zones.pencilZone] : { x: 0, y: 0, w: zones.width }
    EditButton {
        x: zones.pencilAt.x + zones.pencilAt.w - width - Tokens.space.sm
        y: zones.pencilAt.y + Tokens.space.sm
        z: 3
        visible: opacity > 0
        opacity: !zones.editing && hover.hovered && zones.order.length > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Tokens.motion.fast } }
        icon: "edit"
        onClicked: DashboardState.editing = true
    }

    // ---- Agregar (solo en la edicion) --------------------------------------------------
    ColumnLayout {
        id: tray
        y: zones.geom.height + (zones.order.length ? zones.gap : 0)
        width: zones.width
        visible: zones.editing
        spacing: Tokens.space.sm
        // Con muchos widgets las fichas siguen en otra linea; "Listo" queda a la derecha.
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.space.sm
            Flow {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Tokens.space.sm
                Text {
                    height: 32
                    verticalAlignment: Text.AlignVCenter
                    text: zones.unplaced.length ? "Agregar" : "Todo está en Inicio"
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                    font.weight: Tokens.weight.medium
                }
                Repeater {
                    model: zones.unplaced
                    Rectangle {
                        id: chip
                        required property string modelData
                        required property int index
                        readonly property var meta: zones.spec[chip.modelData] || ({})
                        readonly property bool picked: zones.trayIndex === chip.index
                        implicitHeight: 32
                        implicitWidth: chipRow.implicitWidth + Tokens.space.lg * 2
                        radius: 16
                        color: "transparent"
                        border.width: chip.picked ? Tokens.focusRingWidth : 1
                        border.color: chip.picked ? Colors.accent : Colors.divider
                        StateLayer { hovered: chipMouse.containsMouse; pressed: chipMouse.pressed }
                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: Tokens.space.xs + 2
                            Icon { anchors.verticalCenter: parent.verticalCenter; name: "add"; size: Tokens.icon.sm; color: Colors.textMuted }
                            Icon { anchors.verticalCenter: parent.verticalCenter; name: chip.meta.icon || ""; size: Tokens.icon.sm; color: Colors.text }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: chip.meta.label || chip.modelData
                                color: Colors.text
                                font.family: Tokens.font.ui
                                font.pixelSize: Tokens.type.label
                                font.weight: Tokens.weight.medium
                            }
                        }
                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: zones.add(chip.modelData)
                        }
                    }
                }
            }
            Button {
                Layout.alignment: Qt.AlignTop
                label: "Listo"
                icon: "check"
                main: true
                onClicked: DashboardState.editing = false
            }
        }
        Text {
            Layout.fillWidth: true
            text: zones.trayIndex >= 0 ? "Flechas eligen · Enter agrega · Esc vuelve"
                : "Arrastra para ordenar · Tab elige · flechas mueven · T tamaño · Supr quita · A agrega · Esc termina"
            color: Colors.border
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
            elide: Text.ElideRight
        }
    }

    // ---- Contenido de cada widget (ideal: el alto que pide para su ancho) ----------------
    // Un widget nuevo: su entrada en el registro del esquema y su Component aca.
    readonly property var components: Object.assign({
        system: systemC, workspaces: workspacesC, calendar: calendarC, weather: weatherC,
        profile: profileC, quick: quickC, notes: notesC, todo: todoC,
        timer: timerC, now: nowC
    }, zones.external)
    // El contenido de una zona puesta (p. ej. el reproductor, para sus teclas).
    function widgetOf(id: string): var {
        const s = slots.itemAt(Object.keys(zones.spec).indexOf(id));
        return s ? s.widget : null;
    }
    // Ahora decide si aparece aunque no se vea: su hora y, si las muestra, las tareas.
    readonly property bool nowPlaced: zones.stored.some(z => z.id === "now")
    Subscription { demand: NowState.clock; active: zones.active && zones.nowPlaced }
    Subscription { demand: TodoState.demand; active: zones.active && zones.nowPlaced && !NowState.todoPlaced && NowState.kinds.indexOf("todo") >= 0 }
    // Tamano con el que esta puesta una zona.
    function wideOf(id: string): bool {
        const z = zones.list.find(x => x.id === id);
        return !!z && z.size === "wide" && !zones.narrow;
    }
    property Item strip: null
    Component {
        id: systemC
        // Arriba con su alto de siempre: junto a una zona mas alta no se estira.
        Item {
            readonly property real ideal: zones.narrow ? 112 - 2 * Tokens.space.lg : zones.baseHeight - 2 * Tokens.space.lg
            SystemGlance {
                width: parent.width
                height: Math.min(parent.height, parent.ideal)
                wide: zones.narrow
            }
        }
    }
    Component {
        id: workspacesC
        WorkspaceStrip {
            id: ws
            // Las miniaturas crecen con el ancho: sola a todo el ancho, la zona crece con ellas.
            readonly property real ideal: zones.narrow ? ws.implicitHeight : Math.max(zones.baseHeight - 2 * Tokens.space.lg, ws.implicitHeight)
            screenName: zones.screenName
            // Oculta, no sigue a las ventanas.
            live: zones.active
            Component.onCompleted: zones.strip = ws
            Component.onDestruction: if (zones.strip === ws) zones.strip = null
        }
    }
    Component {
        id: calendarC
        Item {
            readonly property real ideal: cal.implicitHeight
            CalendarMonth {
                id: cal
                anchors.horizontalCenter: parent.horizontalCenter
                active: zones.active
                cell: Math.max(28, Math.min(40, Math.floor(parent.width / 7)))
            }
        }
    }
    Component {
        id: weatherC
        ColumnLayout {
            id: wz
            readonly property real ideal: wz.implicitHeight
            spacing: Tokens.space.sm
            // Al abrir el dashboard, si los datos estan viejos, se consultan (como la vista Hoy).
            readonly property bool on: zones.active
            onOnChanged: if (wz.on) WeatherState.ensureFresh()
            Component.onCompleted: if (wz.on) WeatherState.ensureFresh()
            ZoneTitle { Layout.fillWidth: true; text: "Próximas horas"; detail: WeatherState.location ? WeatherState.location.name : ""; opens: true }
            WeatherHours {
                Layout.fillWidth: true
                count: wz.width < 400 ? 3 : 6
            }
            Item { Layout.fillHeight: true }
        }
    }
    Component {
        id: profileC
        ProfileZone {
            active: zones.active
            wide: zones.wideOf("profile")
        }
    }
    Component {
        id: quickC
        QuickZone {
            wide: zones.wideOf("quick")
        }
    }
    Component {
        id: notesC
        NotesZone {
            active: zones.active
            wide: zones.wideOf("notes")
            baseHeight: zones.baseHeight - 2 * Tokens.space.lg
            onDone: zones.fieldDone()
        }
    }
    Component {
        id: todoC
        TodoZone {
            active: zones.active
            wide: zones.wideOf("todo")
            onDone: zones.fieldDone()
        }
    }
    Component {
        id: timerC
        TimerZone {
            active: zones.active
            wide: zones.wideOf("timer")
        }
    }
    Component {
        id: nowC
        NowZone {
            active: zones.active
            wide: zones.wideOf("now")
        }
    }
    Component {
        id: needsC
        Item {
            readonly property real ideal: zones.baseHeight - 2 * Tokens.space.lg
            Text {
                anchors.centerIn: parent
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "Sin ciudad no hay clima: elígela en Hoy (C) o en Configuración → Dashboard."
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
        }
    }
}
