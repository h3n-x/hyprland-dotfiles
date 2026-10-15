// Editor de la disposicion de la barra (Fase 11 B1, bar.layout): tres
// columnas (izquierda, centro, derecha) con sus pildoras (recuadro con sus
// modulos), modulos sueltos ("bare": grabacion, apagar) y espaciadores; abajo,
// los Disponibles (modulos que no estan + un espaciador siempre). Se arrastra:
//   sobre un modulo de una pildora -> entra en esa pildora (antes o despues
//   segun la mitad); sobre el borde de una pildora o un elemento suelto ->
//   elemento nuevo antes o despues (mitad de arriba / de abajo); sobre el
//   vacio de una columna -> al final; a Disponibles -> se quita.
// Teclado: los modulos toman el foco; <- / -> lo mueven dentro de su pildora o
// columna, Supr lo quita, Intro en uno disponible lo agrega al final de la
// derecha. Cada cambio se guarda al momento (SettingsState): la barra cambia
// en vivo. Senalar un modulo lo marca en la barra (IPC bar highlight;
// BAR_HIGHLIGHT_CMD="" lo apaga en las pruebas).
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, SettingsState.qml
import "../modules"

Item {
    id: editor

    readonly property var lay: SettingsState.value("bar.layout") || ({ "start": [], "center": [], "end": [] })
    readonly property var modules: (SettingsState.meta("bar.layout") || {}).modules || ({})
    readonly property var sections: [["start", I18n.trc("bar side", "Left")], ["center", I18n.trc("bar side", "Center")], ["end", I18n.trc("bar side", "Right")]]
    readonly property var used: {
        const out = [];
        for (const sec of ["start", "center", "end"])
            for (const it of editor.lay[sec] || [])
                if (it && it.pill) out.push(...it.pill);
                else if (typeof it === "string" && it !== "spacer") out.push(it);
        return out;
    }
    readonly property var available: Object.keys(editor.modules).filter(id => editor.used.indexOf(id) < 0)

    // ---- Operaciones sobre una copia --------------------------------------------------------
    function copy(): var {
        return JSON.parse(JSON.stringify(editor.lay));
    }
    function itemFor(id: string): var {
        if (id === "spacer") return "spacer";
        return (editor.modules[id] || {}).bare ? id : { "pill": [id] };
    }
    // Quita lo marcado como null y las pildoras vacias.
    function clean(l: var): var {
        for (const sec of ["start", "center", "end"]) {
            l[sec] = l[sec].filter(it => it !== null).map(it => it && it.pill ? { "pill": it.pill.filter(x => x !== null) } : it)
                .filter(it => !(it && it.pill && it.pill.length === 0));
        }
        return l;
    }
    // El origen (si lo hay) queda en null hasta limpiar, asi los indices de destino valen.
    function blank(l: var, src: var): void {
        if (!src) return;
        if (src.pidx >= 0) l[src.sec][src.idx].pill[src.pidx] = null;
        else l[src.sec][src.idx] = null;
    }
    function save(l: var): void {
        SettingsState.set("bar.layout", editor.clean(l));
    }
    // Destinos: dentro de una pildora (antes/despues de un modulo), como elemento
    // (antes/despues), al final de una columna, o fuera (Disponibles).
    function dropInPill(mid: string, src: var, sec: string, idx: int, pidx: int, after: bool): void {
        if (mid === "spacer" || (editor.modules[mid] || {}).bare) return editor.dropAsItem(mid, src, sec, idx, after);
        const l = editor.copy();
        editor.blank(l, src);
        l[sec][idx].pill.splice(pidx + (after ? 1 : 0), 0, mid);
        editor.save(l);
    }
    function dropAsItem(mid: string, src: var, sec: string, idx: int, after: bool): void {
        const l = editor.copy();
        editor.blank(l, src);
        l[sec].splice(idx + (after ? 1 : 0), 0, editor.itemFor(mid));
        editor.save(l);
    }
    function dropAtEnd(mid: string, src: var, sec: string): void {
        editor.dropAsItem(mid, src, sec, editor.lay[sec].length - 1, true);
    }
    function remove(src: var): void {
        const l = editor.copy();
        editor.blank(l, src);
        editor.save(l);
    }
    // Teclado: un lugar a la izquierda o a la derecha dentro de su contenedor.
    function shift(src: var, dir: int): void {
        const l = editor.copy();
        const list = src.pidx >= 0 ? l[src.sec][src.idx].pill : l[src.sec];
        const i = src.pidx >= 0 ? src.pidx : src.idx, j = i + dir;
        if (j < 0 || j >= list.length) return;
        [list[i], list[j]] = [list[j], list[i]];
        editor.save(l);
    }

    // ---- Marca en la barra ----------------------------------------------------------------------
    readonly property var highlightCmd: Quickshell.env("BAR_HIGHLIGHT_CMD") !== null && Quickshell.env("BAR_HIGHLIGHT_CMD") !== undefined
        ? (Quickshell.env("BAR_HIGHLIGHT_CMD") ? Quickshell.env("BAR_HIGHLIGHT_CMD").split(" ") : [])
        : ["qs", "-c", "dotshell", "ipc", "call", "bar", "highlight"]
    property string pointed: ""
    function point(id: string): void {
        if (id === editor.pointed) return;
        editor.pointed = id;
        if (editor.highlightCmd.length) Quickshell.execDetached(editor.highlightCmd.concat([id === "spacer" ? "" : id]));
    }
    Component.onDestruction: editor.point("")

    implicitHeight: body.implicitHeight

    // Lo que se arrastra cuelga de esta capa libre (encima de todo, sin posicionador).
    Item {
        id: dragLayer
        anchors.fill: parent
        z: 10
    }

    Column {
        id: body
        width: parent.width
        spacing: Tokens.space.md

        RowLayout {
            width: parent.width
            spacing: Tokens.space.sm
            Repeater {
                model: editor.sections
                Rectangle {
                    id: col
                    required property var modelData
                    readonly property string sec: col.modelData[0]
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: colBody.implicitHeight + 2 * Tokens.space.md
                    radius: Tokens.radius.md
                    color: Colors.tint(Colors.surfaceHigh, Tokens.tint.well)
                    border.width: tail.containsDrag ? 2 : 1
                    border.color: tail.containsDrag ? Colors.text : Colors.divider

                    // Vacio de la columna: al final.
                    DropArea {
                        id: tail
                        anchors.fill: parent
                        keys: ["barchip"]
                        onDropped: (d) => { editor.dropAtEnd(d.source.mid, d.source.src, col.sec); d.accept(); }
                    }
                    Column {
                        id: colBody
                        x: Tokens.space.md
                        y: Tokens.space.md
                        width: parent.width - 2 * Tokens.space.md
                        spacing: Tokens.space.sm
                        Text {
                            text: col.modelData[1]
                            color: Colors.textMuted
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            font.weight: Tokens.weight.medium
                        }
                        Repeater {
                            model: editor.lay[col.sec] || []
                            Loader {
                                id: it
                                required property var modelData
                                required property int index
                                width: colBody.width
                                sourceComponent: it.modelData && it.modelData.pill ? pillBox : looseItem
                                onLoaded: { it.item.sec = col.sec; it.item.idx = it.index; it.item.data_ = it.modelData; }
                            }
                        }
                        Text {
                            visible: (editor.lay[col.sec] || []).length === 0
                            text: I18n.tr("Empty: drag here")
                            color: Colors.textMuted
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                        }
                    }
                }
            }
        }

        // ---- Disponibles ---------------------------------------------------------------------------
        Rectangle {
            width: parent.width
            implicitHeight: availBody.implicitHeight + 2 * Tokens.space.md
            radius: Tokens.radius.md
            color: "transparent"
            border.width: out.containsDrag ? 2 : 1
            border.color: out.containsDrag ? Colors.text : Colors.divider
            DropArea {
                id: out
                anchors.fill: parent
                keys: ["barchip"]
                onDropped: (d) => { if (d.source.src) editor.remove(d.source.src); d.accept(); }
            }
            Column {
                id: availBody
                x: Tokens.space.md
                y: Tokens.space.md
                width: parent.width - 2 * Tokens.space.md
                spacing: Tokens.space.sm
                Text {
                    text: I18n.tr("Available (drag here to remove)")
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                    font.weight: Tokens.weight.medium
                }
                Flow {
                    width: parent.width
                    spacing: Tokens.space.sm
                    Repeater {
                        model: editor.available.concat(["spacer"])
                        Chip {
                            required property string modelData
                            mid: modelData
                            src: null
                        }
                    }
                }
            }
        }

    }

    // ---- Piezas -------------------------------------------------------------------------------------
    // Una pildora: recuadro con sus modulos; su borde recibe "antes/despues" como elemento.
    Component {
        id: pillBox
        Rectangle {
            id: box
            property string sec
            property int idx
            property var data_
            implicitHeight: pillFlow.implicitHeight + 2 * Tokens.space.sm
            radius: Tokens.radius.pill(Tokens.pill.height + 2 * Tokens.space.sm)
            color: Colors.surfaceLow
            border.width: edge.containsDrag ? 2 : 1
            border.color: edge.containsDrag ? Colors.text : Colors.divider
            DropArea {
                id: edge
                anchors.fill: parent
                keys: ["barchip"]
                onDropped: (d) => { editor.dropAsItem(d.source.mid, d.source.src, box.sec, box.idx, d.y > box.height / 2); d.accept(); }
            }
            Flow {
                id: pillFlow
                x: Tokens.space.sm
                y: Tokens.space.sm
                width: parent.width - 2 * Tokens.space.sm
                spacing: Tokens.space.xs
                Repeater {
                    model: box.data_ ? box.data_.pill : []
                    Chip {
                        required property string modelData
                        required property int index
                        mid: modelData
                        src: ({ "sec": box.sec, "idx": box.idx, "pidx": index })
                        inPill: true
                    }
                }
            }
        }
    }
    // Un elemento suelto: modulo "bare" o espaciador.
    Component {
        id: looseItem
        Item {
            id: loose
            property string sec
            property int idx
            property var data_
            implicitHeight: looseChip.implicitHeight
            Chip {
                id: looseChip
                mid: typeof loose.data_ === "string" ? loose.data_ : ""
                src: ({ "sec": loose.sec, "idx": loose.idx, "pidx": -1 })
            }
        }
    }

    // Un modulo (o un espaciador): se arrastra, recibe soltadas y se mueve con el
    // teclado. El lugar (chip) queda fijo en su fila; lo que se mueve es la cara
    // (face), que mientras se arrastra pasa a colgar del editor (encima de todo)
    // y al soltar vuelve a su lugar.
    component Chip: Item {
        id: chip
        property string mid
        property var src: null
        property bool inPill: false
        // El nombre del modulo viene del esquema en ingles (contexto "settings", Fase 15 B3).
        readonly property var info: chip.mid === "spacer" ? { "label": I18n.trc("bar module", "Spacer"), "icon": "space_bar" }
            : editor.modules[chip.mid] ? { "label": I18n.trc("settings", editor.modules[chip.mid].label), "icon": editor.modules[chip.mid].icon }
            : { "label": chip.mid, "icon": "help" }
        // Se arrastra a mano (el arrastre de MouseArea pierde el umbral y se corre al reparentar).
        property bool dragging: false

        implicitWidth: chipRow.implicitWidth + 2 * Tokens.space.md
        implicitHeight: Tokens.pill.height
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: chip.info.label

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Delete && chip.src) editor.remove(chip.src);
            else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !chip.src) editor.dropAtEnd(chip.mid, null, "end");
            else if (event.key === Qt.Key_Left && chip.src) editor.shift(chip.src, -1);
            else if (event.key === Qt.Key_Right && chip.src) editor.shift(chip.src, 1);
            else return;
            event.accepted = true;
        }
        onActiveFocusChanged: if (chip.activeFocus) editor.point(chip.mid)

        // Soltar sobre este modulo: dentro de su pildora o como elemento (nunca sobre si mismo).
        DropArea {
            id: here
            anchors.fill: parent
            keys: ["barchip"]
            enabled: !!chip.src && !chip.dragging
            onDropped: (d) => {
                if (chip.inPill) editor.dropInPill(d.source.mid, d.source.src, chip.src.sec, chip.src.idx, chip.src.pidx, d.x > chip.width / 2);
                else editor.dropAsItem(d.source.mid, d.source.src, chip.src.sec, chip.src.idx, d.y > chip.height / 2);
                d.accept();
            }
        }

        Rectangle {
            id: face
            width: chip.width
            height: chip.height
            radius: Tokens.radius.pill(height)
            color: chip.dragging ? Colors.surfaceHighest : Colors.surfaceHigh
            border.width: chip.activeFocus || here.containsDrag ? 2 : (chip.mid === "spacer" ? 1 : 0)
            border.color: chip.activeFocus || here.containsDrag ? Colors.text : Colors.divider
            opacity: chip.dragging ? 0.85 : 1

            Drag.active: chip.dragging
            Drag.keys: ["barchip"]
            Drag.source: chip

            states: State {
                when: chip.dragging
                ParentChange { target: face; parent: dragLayer }
            }

            Row {
                id: chipRow
                anchors.centerIn: parent
                spacing: Tokens.space.xs
                Icon { anchors.verticalCenter: parent.verticalCenter; name: chip.info.icon; size: Tokens.icon.sm; color: Colors.text }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: chip.info.label
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
            }
            MouseArea {
                id: drag
                property point grab
                anchors.fill: parent
                hoverEnabled: true
                // La pagina (Flickable) no se lleva el gesto: arrastrar no desplaza la pagina.
                preventStealing: true
                cursorShape: chip.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onEntered: editor.point(chip.mid)
                onExited: if (!chip.dragging) editor.point("")
                // Se suelta donde esta el puntero (no el centro del modulo).
                onPressed: (m) => {
                    drag.grab = Qt.point(m.x, m.y);
                    face.Drag.hotSpot.x = m.x;
                    face.Drag.hotSpot.y = m.y;
                }
                onPositionChanged: (m) => {
                    if (!drag.pressed) return;
                    if (!chip.dragging && Math.hypot(m.x - drag.grab.x, m.y - drag.grab.y) < 6) return;
                    const p = drag.mapToItem(dragLayer, m.x, m.y);
                    chip.dragging = true;
                    face.x = p.x - drag.grab.x;
                    face.y = p.y - drag.grab.y;
                }
                onReleased: {
                    if (chip.dragging) face.Drag.drop();
                    chip.dragging = false;
                    face.x = 0;
                    face.y = 0;
                }
            }
        }
    }
}
