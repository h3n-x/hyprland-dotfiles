// Pantallas (Fase 10 B5, P10.9): una tarjeta por pantalla con todo lo que
// Hyprland deja elegir por salida, y la disposicion (arrastrar) cuando hay mas
// de una. Lee `hyprctl monitors all -j` y scripts/display-caps (EDID) al abrir,
// tras cada cambio y con "Detectar pantallas" (sin escuchar a Hyprland: costo
// con la ventana quieta, B3/B4). Los cambios quedan en la pagina hasta
// "Aplicar": se guardan en display.outputs (regla completa por pantalla, por
// su descripcion) y el motor los prueba: DisplayConfirm pregunta si mantener.
// Las opciones de color/10 bits/HDR/VRR se muestran siempre (dotfiles para
// cualquier equipo), con una nota cuando la pantalla no dice soportarlas.
// Pruebas: DISPLAY_MONITORS_JSON y DISPLAY_CAPS_JSON (archivos en vez de
// hyprctl y display-caps).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml, SettingsState.qml
import "../modules"

Column {
    id: panel

    property var monitors: []
    property var caps: ({})
    // Cambios sin aplicar: nombre -> {campo: valor}.
    property var edits: ({})
    readonly property var store: SettingsState.value("display.outputs") || ({})
    readonly property bool dirty: Object.keys(panel.edits).length > 0
    readonly property var views: panel.monitors.map(m => panel.view(m))
    readonly property bool overlap: canvas.overlap

    // Escalas con las que el espacio que queda es entero (Hyprland redondea las
    // demas en silencio, V0): para 1920x1080, 1 · 1,2 · 1,25 · 1,33 · 1,5 · 1,6 · 1,67 · 2 · 2,4 · 2,5 · 3.
    readonly property var scaleCandidates: [1, 1.2, 1.25, 4 / 3, 1.5, 1.6, 5 / 3, 1.75, 1.8, 2, 2.25, 2.4, 2.5, 3]
    readonly property var colorProfiles: [["auto", I18n.tr("Automatic")], ["srgb", "sRGB"], ["dcip3", "DCI-P3"], ["dp3", "Display P3"], // i18n-ok
        ["adobe", "Adobe RGB"], ["wide", I18n.tr("Wide (BT.2020)")], ["edid", I18n.tr("The display's own (EDID)")], ["hdr", "HDR"], ["hdredid", "HDR (EDID)"]] // i18n-ok

    function refresh(): void {
        monProc.running = true;
        capsProc.running = true;
    }
    function keyOf(m: var): string {
        return m.description ? "desc:" + m.description : m.name;
    }
    function sizes(m: var): var {
        const seen = [];
        for (const a of m.availableModes || []) {
            const s = a.split("@")[0];
            if (seen.indexOf(s) < 0) seen.push(s);
        }
        return seen.sort((a, b) => {
            const pa = a.split("x").map(Number), pb = b.split("x").map(Number);
            return pb[0] * pb[1] - pa[0] * pa[1];
        });
    }
    function rates(m: var, size: string): var {
        return (m.availableModes || []).filter(a => a.startsWith(size + "@")).map(a => parseFloat(a.split("@")[1]))
            .sort((a, b) => b - a);
    }
    function scales(size: string, current: real): var {
        const p = size.split("x").map(Number);
        const ok = panel.scaleCandidates.filter(s => Math.abs(p[0] / s - Math.round(p[0] / s)) < 0.01 && Math.abs(p[1] / s - Math.round(p[1] / s)) < 0.01);
        if (current && !ok.some(s => Math.abs(s - current) < 0.001)) ok.push(current);
        return ok.sort((a, b) => a - b).map(s => [Math.round(s * 1e6) / 1e6, String(Math.round(s * 100) / 100).replace(".", I18n.locale.decimalPoint)
            + " · " + Math.round(p[0] / s) + " × " + Math.round(p[1] / s)]);
    }
    // Lo que la pantalla tiene ahora (Hyprland), con lo guardado donde Hyprland
    // no lo distingue (VRR "pantalla completa", perfil "automatico"), y los cambios encima.
    function view(m: var): var {
        const r = panel.store[panel.keyOf(m)] || {};
        const base = {
            name: m.name, size: m.width + "x" + m.height, rate: m.refreshRate, scale: m.scale, transform: m.transform || 0,
            x: m.x, y: m.y, enabled: !m.disabled,
            vrr: r.vrr !== undefined ? r.vrr : (m.vrr ? 1 : 0),
            bitdepth: (m.currentFormat || "").indexOf("2101010") >= 0 ? 10 : 8,
            cm: r.cm !== undefined ? r.cm : "auto",
            sdrbrightness: m.sdrBrightness !== undefined ? m.sdrBrightness : 1,
            sdrsaturation: m.sdrSaturation !== undefined ? m.sdrSaturation : 1,
            mirror: r.mirror || ""
        };
        return Object.assign(base, panel.edits[m.name] || {});
    }
    function edit(name: string, field: string, value: var): void {
        const e = Object.assign({}, panel.edits);
        e[name] = Object.assign({}, e[name] || {});
        e[name][field] = value;
        // Una resolucion nueva: su frecuencia mas alta y una escala que le sirva.
        if (field === "size") {
            const m = panel.monitors.find(x => x.name === name);
            e[name].rate = panel.rates(m, value)[0];
            const sc = panel.scales(value, 0).map(o => o[0]);
            const cur = panel.view(m).scale;
            if (!sc.some(s => Math.abs(s - cur) < 0.001)) e[name].scale = sc.reduce((a, b) => Math.abs(b - cur) < Math.abs(a - cur) ? b : a);
        }
        panel.edits = e;
    }
    function rule(v: var): var {
        const r = {
            mode: v.size + "@" + (Math.round(v.rate * 1000) / 1000), position: Math.round(v.x) + "x" + Math.round(v.y),
            scale: Math.round(v.scale * 1e6) / 1e6, transform: v.transform, vrr: v.vrr, bitdepth: v.bitdepth, cm: v.cm,
            mirror: v.mirror, enabled: v.enabled
        };
        if (v.cm === "hdr" || v.cm === "hdredid") {
            r.sdrbrightness = Math.round(v.sdrbrightness * 100) / 100;
            r.sdrsaturation = Math.round(v.sdrsaturation * 100) / 100;
        }
        return r;
    }
    function apply(): void {
        const next = Object.assign({}, panel.store);
        for (const m of panel.monitors)
            if (panel.edits[m.name]) next[panel.keyOf(m)] = panel.rule(panel.view(m));
        panel.edits = ({});
        SettingsState.set("display.outputs", next);
        later.restart();
    }
    function resetAll(): void {
        panel.edits = ({});
        SettingsState.reset("display.outputs");
        later.restart();
    }

    spacing: Tokens.space.md
    Component.onCompleted: panel.refresh()

    Process {
        id: monProc
        command: Quickshell.env("DISPLAY_MONITORS_JSON") ? ["cat", Quickshell.env("DISPLAY_MONITORS_JSON")] : ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { panel.monitors = JSON.parse(this.text); } catch (e) {}
            }
        }
    }
    Process {
        id: capsProc
        command: Quickshell.env("DISPLAY_CAPS_JSON") ? ["cat", Quickshell.env("DISPLAY_CAPS_JSON")]
            : [Quickshell.env("HOME") + "/.config/hypr/scripts/display-caps"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { panel.caps = JSON.parse(this.text); } catch (e) {}
            }
        }
    }
    // Tras guardar: la pantalla ya cambio (o vuelve); se relee una vez.
    Timer {
        id: later
        interval: 1200
        onTriggered: panel.refresh()
    }
    // Una prueba que vuelve sola tambien cambia el almacen: se relee (no al
    // abrir: el almacen llega una vez y la lectura de arranque ya esta en curso).
    onStoreChanged: if (panel.monitors.length) later.restart()

    // ---- Disposicion (dos o mas pantallas) --------------------------------------------------
    DisplayCanvas {
        id: canvas
        visible: panel.monitors.length > 1
        width: parent.width
        items: panel.views
        onMoved: (name, x, y) => { panel.edit(name, "x", x); panel.edit(name, "y", y); }
    }

    // ---- Una tarjeta por pantalla ------------------------------------------------------------
    Repeater {
        model: panel.monitors
        Rectangle {
            id: card
            required property var modelData
            readonly property var m: card.modelData
            readonly property var v: panel.view(card.m)
            readonly property var c: panel.caps[card.m.name] || ({ known: false })
            readonly property bool internal: /^(eDP|LVDS|DSI)/.test(card.m.name)
            property bool advanced: false

            width: panel.width
            height: body.implicitHeight + 2 * Tokens.space.lg
            radius: Tokens.radius.lg
            color: Colors.tint(Colors.surfaceHigh, Tokens.tint.well)
            border.color: Colors.divider

            ColumnLayout {
                id: body
                x: Tokens.space.lg
                y: Tokens.space.lg
                width: parent.width - 2 * Tokens.space.lg
                spacing: Tokens.space.sm

                RowLayout {
                    spacing: Tokens.space.sm
                    Icon { name: card.internal ? "laptop" : "monitor"; color: Colors.textMuted }
                    Text {
                        text: card.m.name
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.title
                        font.weight: Tokens.weight.semibold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: [card.m.make, card.m.model].filter(x => x).join(" ") + (card.internal ? " · " + I18n.tr("built-in") : "")
                        elide: Text.ElideRight
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                    }
                }

                Line {
                    visible: panel.monitors.length > 1
                    label: I18n.tr("Enabled")
                    note: card.v.enabled && panel.views.filter(x => x.enabled).length <= 1 ? I18n.tr("It's the only one on.") : ""
                    Switch {
                        checked: card.v.enabled
                        onToggled: if (!card.v.enabled || panel.views.filter(x => x.enabled).length > 1) panel.edit(card.m.name, "enabled", !card.v.enabled)
                    }
                }
                Choice {
                    label: I18n.tr("Resolution")
                    options: panel.sizes(card.m).map(s => [s, s.replace("x", " × ")])
                    current: card.v.size
                    onChosen: (val) => panel.edit(card.m.name, "size", val)
                }
                Choice {
                    label: I18n.tr("Refresh rate")
                    options: panel.rates(card.m, card.v.size).map(r => [r, I18n.tr("%1 Hz", String(Math.round(r * 100) / 100).replace(".", I18n.locale.decimalPoint))])
                    current: panel.rates(card.m, card.v.size).reduce((a, b) => Math.abs(b - card.v.rate) < Math.abs(a - card.v.rate) ? b : a, 0)
                    onChosen: (val) => panel.edit(card.m.name, "rate", val)
                }
                Choice {
                    label: I18n.tr("Scale")
                    note: I18n.tr("The space left for the windows.")
                    options: panel.scales(card.v.size, card.v.scale)
                    current: Math.round(card.v.scale * 1e6) / 1e6
                    onChosen: (val) => panel.edit(card.m.name, "scale", val)
                }
                Line {
                    label: I18n.tr("Rotation")
                    Segmented {
                        options: [[0, I18n.trc("rotation", "Normal")], [1, "90°"], [2, "180°"], [3, "270°"]]
                        current: card.v.transform % 4
                        onChosen: (val) => panel.edit(card.m.name, "transform", val + (card.v.transform >= 4 ? 4 : 0))
                    }
                }
                Line {
                    label: I18n.tr("Flipped")
                    note: I18n.tr("Horizontal mirror (projectors, teleprompter).")
                    Switch {
                        checked: card.v.transform >= 4
                        onToggled: panel.edit(card.m.name, "transform", card.v.transform % 4 + (card.v.transform >= 4 ? 0 : 4))
                    }
                }
                Line {
                    label: I18n.tr("Variable refresh rate (VRR)")
                    note: card.c.known && !card.c.vrr ? I18n.tr("This display doesn't report a variable range: it may do nothing. Changing it reloads Hyprland (a flicker).")
                        : I18n.tr("Changing it reloads Hyprland (a flicker).")
                    Segmented {
                        options: [[0, I18n.trc("vrr", "Off")], [1, I18n.trc("vrr", "Always")], [2, I18n.trc("vrr", "Fullscreen")]]
                        current: card.v.vrr
                        onChosen: (val) => panel.edit(card.m.name, "vrr", val)
                    }
                }
                Choice {
                    visible: panel.monitors.length > 1
                    label: I18n.tr("Mirror")
                    note: I18n.tr("Shows the same as another display.")
                    options: [["", I18n.trc("mirror", "No")]].concat(panel.monitors.filter(o => o.name !== card.m.name).map(o => [o.name, o.name]))
                    current: card.v.mirror
                    onChosen: (val) => panel.edit(card.m.name, "mirror", val)
                }

                // Color avanzado: plegado.
                Button {
                    label: card.advanced ? I18n.tr("Hide advanced color") : I18n.tr("Advanced color (10 bits, profiles, HDR)")
                    icon: card.advanced ? "expand_less" : "expand_more"
                    onClicked: card.advanced = !card.advanced
                }
                Line {
                    visible: card.advanced
                    label: I18n.tr("Color depth")
                    note: card.c.maxBpc && card.c.maxBpc < 10 ? I18n.tr("This display reports %1 bits per color.", I18n.number(card.c.maxBpc)) : ""
                    Segmented {
                        options: [[8, I18n.tr("%1 bits", I18n.number(8))], [10, I18n.tr("%1 bits", I18n.number(10))]]
                        current: card.v.bitdepth
                        onChosen: (val) => panel.edit(card.m.name, "bitdepth", val)
                    }
                }
                Choice {
                    visible: card.advanced
                    label: I18n.tr("Color profile")
                    note: (card.v.cm === "hdr" || card.v.cm === "hdredid") && !card.c.hdr
                        ? (card.c.known ? I18n.tr("This display doesn't report HDR support: it will stay in sRGB.") : I18n.tr("Couldn't read whether it supports HDR."))
                        : (card.v.cm !== "auto" && card.v.cm !== "srgb" && !card.c.wide && card.c.known ? I18n.tr("This display doesn't report wide color.") : "")
                    options: panel.colorProfiles
                    current: card.v.cm
                    onChosen: (val) => panel.edit(card.m.name, "cm", val)
                }
                Line {
                    visible: card.advanced && (card.v.cm === "hdr" || card.v.cm === "hdredid")
                    label: I18n.tr("SDR brightness in HDR")
                    Slider {
                        from: 0.5
                        to: 2
                        step: 0.05
                        value: card.v.sdrbrightness
                        onMoved: (val) => panel.edit(card.m.name, "sdrbrightness", val)
                    }
                }
                Line {
                    visible: card.advanced && (card.v.cm === "hdr" || card.v.cm === "hdredid")
                    label: I18n.tr("SDR saturation in HDR")
                    Slider {
                        from: 0.5
                        to: 2
                        step: 0.05
                        value: card.v.sdrsaturation
                        onMoved: (val) => panel.edit(card.m.name, "sdrsaturation", val)
                    }
                }
            }
        }
    }

    // ---- Acciones --------------------------------------------------------------------------------
    Text {
        width: parent.width
        visible: panel.overlap
        text: I18n.tr("Two displays overlap: move them to be able to apply.")
        color: Colors.danger
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
        wrapMode: Text.WordWrap
    }
    Row {
        spacing: Tokens.space.sm
        Button {
            label: I18n.tr("Detect displays")
            icon: "refresh"
            onClicked: panel.refresh()
        }
        Button {
            visible: Object.keys(panel.store).length > 0
            label: I18n.trc("displays", "Automatic")
            icon: "restart_alt"
            onClicked: panel.resetAll()
        }
        Button {
            visible: panel.dirty
            label: I18n.tr("Discard")
            onClicked: panel.edits = ({})
        }
        Button {
            objectName: "display-apply"
            visible: panel.dirty
            enabled: !panel.overlap
            opacity: enabled ? 1 : 0.5
            label: I18n.tr("Apply")
            icon: "check"
            main: true
            onClicked: panel.apply()
        }
    }

    // Una fila: texto (y nota) a la izquierda, el control a la derecha.
    component Line: RowLayout {
        id: line
        property string label
        property string note: ""
        default property alias content: holder.data
        Layout.fillWidth: true
        spacing: Tokens.space.md
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.space.hair
            Text {
                Layout.fillWidth: true
                text: line.label
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
            }
            Text {
                visible: line.note !== ""
                Layout.fillWidth: true
                text: line.note
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                wrapMode: Text.WordWrap
            }
        }
        Item {
            id: holder
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
    // Una eleccion de lista: Select y, debajo, su lista a todo el ancho.
    component Choice: ColumnLayout {
        id: choice
        property string label
        property string note: ""
        property var options: []
        property var current
        signal chosen(var value)
        Layout.fillWidth: true
        spacing: Tokens.space.xs
        Line {
            Layout.fillWidth: true
            label: choice.label
            note: choice.note
            Select {
                id: sel
                options: choice.options
                current: choice.current
            }
        }
        SelectList {
            visible: sel.open
            Layout.fillWidth: true
            options: choice.options
            current: choice.current
            onChosen: (val) => { sel.open = false; choice.chosen(val); }
            onClosed: sel.open = false
        }
    }
}
