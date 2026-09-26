// Atajos de Hyprland (Fase 4 B10): los lee la guia de atajos y, mas
// adelante, la pagina Atajos del centro de configuracion (P10.11) y la
// documentacion generada (P8.5). Una sola fuente: "keybinds data"
// (hypr/scripts/keybinds), que agrupa lo que devuelve hyprctl binds -j a
// partir de la descripcion de cada atajo en binds.lua.
//
// Se lee al abrir (una llamada corta); cerrado no corre nada.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string script: Quickshell.env("KEYBINDS_SCRIPT") || (Quickshell.env("HOME") + "/.config/hypr/scripts/keybinds")

    // ---- Opciones ---------------------------------------------------------------------------
    // Entradas del futuro settings store (P8.1), editables desde la pagina
    // Atajos del centro de configuracion (P10.11): "keybinds.<nombre>". Hasta
    // entonces viven solo aca, con su valor por defecto. La tecla que abre la
    // guia es un atajo mas (binds.lua); cambiarla pasara por los overrides de
    // Hyprland (P10.3), no por la shell.
    component Options: QtObject {
        // 0 = automatico segun el ancho de la pantalla.
        property int columns: 0
        // "words" (Super, Ctrl, Alt, Shift) o "symbols" (iconos).
        property string modifierStyle: "words"
        // Mostrar los atajos de los modos (submaps: "Modo cambiar tamaño").
        property bool showModes: true
    }
    readonly property Options options: Options {}

    // ---- Estado -----------------------------------------------------------------------------
    property bool visible: false
    property string screen: ""
    property string query: ""
    // { total, rows, problems, groups: [{ name, icon, mode, items: [{ text, submap, combos: [{ mods, keys }] }] }] }
    property var data: null
    readonly property var groups: root.data ? root.data.groups : []
    readonly property int total: root.data ? root.data.total : 0
    readonly property int rowCount: root.data ? root.data.rows : 0

    function open(): void {
        root.refresh();
        FocusedScreen.request(name => {
            root.screen = name;
            root.query = "";
            root.visible = true;
        });
    }
    function close(): void {
        root.visible = false;
    }
    function toggle(): void {
        if (root.visible) root.close();
        else root.open();
    }
    function refresh(): void {
        if (!root.proc.running) root.proc.running = true;
    }
    property Process proc: Process {
        command: [root.script, "data"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.data = JSON.parse(this.text);
                } catch (e) {}
            }
        }
    }

    // ---- Filtro -------------------------------------------------------------------------------
    // Busca en la descripcion, el grupo y las teclas (en palabras); los grupos
    // sin coincidencias desaparecen.
    readonly property var filtered: {
        const q = root.query.trim();
        const out = [];
        for (const g of root.groups) {
            if (g.mode && !root.options.showModes) continue;
            if (!q) {
                out.push(g);
                continue;
            }
            const items = g.items.filter(it => {
                const keys = it.combos.map(c => c.mods.concat(c.keys.map(k => root.words(k))).join(" ")).join(" ");
                return Fuzzy.match(it.text, q) || Fuzzy.match(g.name, q) || keys.toLowerCase().indexOf(q.toLowerCase()) >= 0;
            });
            if (items.length) out.push({ name: g.name, icon: g.icon, mode: g.mode, items: items });
        }
        return out;
    }
    readonly property int shownCount: root.filtered.reduce((n, g) => n + g.items.length, 0)

    // ---- Etiquetas ----------------------------------------------------------------------------
    // Modificador tal como se dibuja: palabra o "@icono".
    function modLabel(m: string): string {
        if (root.options.modifierStyle !== "symbols") return m;
        return { Super: "@keyboard_command_key", Ctrl: "@keyboard_control_key", Alt: "@keyboard_option_key", Shift: "@shift" }[m] || m;
    }
    // Iconos en palabras (busqueda y lectores de pantalla).
    readonly property var iconWords: ({
        "@arrows": "flechas", "@volume_up": "subir volumen", "@volume_down": "bajar volumen", "@volume_off": "silencio",
        "@mic_off": "micrófono", "@brightness_high": "subir brillo", "@brightness_low": "bajar brillo",
        "@play_pause": "reproducir pausa", "@skip_next": "siguiente", "@skip_previous": "anterior"
    })
    function words(label: string): string {
        return root.iconWords[label] || label;
    }
}
