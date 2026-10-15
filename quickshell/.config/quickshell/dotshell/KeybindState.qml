// Atajos de Hyprland (Fase 4 B10): los lee la guia de atajos y, mas
// adelante, la pagina Atajos del centro de configuracion (P10.11) y la
// documentacion generada (P8.5). Una sola fuente: "keybinds data"
// (hypr/scripts/keybinds), que agrupa lo que devuelve hyprctl binds -j a
// partir de la descripcion de cada atajo en binds.lua.
//
// Se lee la primera vez que se abre y se guarda: los atajos solo cambian
// cuando Hyprland recarga su config (evento configreloaded), que marca los
// datos como viejos; la siguiente apertura los vuelve a leer (Fase 8 B3; antes
// se releia en cada apertura y rearmar la lista retrasaba el primer cuadro).
// Cerrado no corre nada.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: root

    readonly property string script: Quickshell.env("KEYBINDS_SCRIPT") || (Quickshell.env("HOME") + "/.config/hypr/scripts/keybinds")

    // ---- Opciones ---------------------------------------------------------------------------
    // Del settings store (Fase 8 B1), claves keybinds.* del esquema; las
    // editara la pagina Atajos del centro de configuracion (P10.11). La tecla
    // que abre la guia es un atajo mas (binds.lua); cambiarla pasara por los
    // overrides de Hyprland (P10.3), no por la shell.
    component Options: QtObject {
        // 0 = automatico segun el ancho de la pantalla.
        readonly property int columns: SettingsState.value("keybinds.columns")
        // "words" (Super, Ctrl, Alt, Shift) o "symbols" (iconos).
        readonly property string modifierStyle: SettingsState.value("keybinds.modifierStyle")
        // Mostrar los atajos de los modos (submaps: "Modo cambiar tamaño").
        readonly property bool showModes: SettingsState.value("keybinds.showModes")
    }
    readonly property Options options: Options {}

    // ---- Estado -----------------------------------------------------------------------------
    property bool visible: false
    property string screen: ""
    property string query: ""
    // { total, rows, problems, groups: [{ name, icon, mode, items: [{ text, submap, combos: [{ mods, keys }] }] }] }
    // tal como lo entrega el script: en ingles (Fase 15 B3).
    property var data: null
    // Los mismos grupos en el idioma elegido; source guarda el ingles (la busqueda
    // tambien lo mira). Se rearma al cambiar el catalogo (I18n.rev).
    readonly property var groups: root.translated(root.data, I18n.rev)
    function translated(d: var, rev: int): var {
        if (!d) return [];
        return d.groups.map(g => ({
            name: I18n.trc("keybind group", g.name), source: g.name, icon: g.icon, mode: g.mode,
            items: g.items.map(it => ({
                text: I18n.trc("keybind", it.text), source: it.text, submap: it.submap,
                combos: it.combos.map(c => ({ mods: c.mods, keys: c.keys.map(k => k.startsWith("@") ? k : I18n.trc("key", k)) }))
            }))
        }));
    }
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
    // Generacion de la config de Hyprland: sube con cada recarga. Los datos
    // valen si se leyeron en la generacion actual (una recarga en medio de una
    // lectura deja los datos como viejos y se vuelve a leer).
    property int configGen: 0
    property int readGen: -1
    property int runningGen: -1
    readonly property bool stale: root.readGen !== root.configGen
    // Solo lo necesario: si los datos siguen valiendo, no se lanza nada.
    function refresh(): void {
        if (!root.stale && root.data) return;
        if (root.proc.running) return;
        root.runningGen = root.configGen;
        root.proc.running = true;
    }
    // Solo la guia de la shell vigila las recargas (Fase 10 B4): en el centro
    // de configuracion, tocar Hyprland abre su socket de eventos y cada evento
    // cuesta CPU con la ventana quieta; ahi la pagina Atajos relee con reload()
    // cada vez que se abre.
    property bool watchReloads: false
    function reload(): void {
        root.readGen = -1;
        root.refresh();
    }
    property Connections hyprEvents: Connections {
        target: root.watchReloads ? Hyprland : null
        function onRawEvent(event: var): void {
            if (event.name !== "configreloaded") return;
            root.configGen += 1;
            // Con la guia abierta, se ve el cambio enseguida.
            if (root.visible) root.refresh();
        }
    }
    property Process proc: Process {
        command: [root.script, "data"]
        // Si Hyprland recargo mientras se leia y la guia sigue abierta, otra vez.
        onExited: if (root.visible && root.stale) Qt.callLater(root.refresh)
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.data = JSON.parse(this.text);
                    root.readGen = root.runningGen;
                } catch (e) {}
            }
        }
    }

    // ---- Filtro -------------------------------------------------------------------------------
    // Busca en la descripcion, el grupo (en el idioma elegido y en ingles) y las
    // teclas (en palabras); los grupos sin coincidencias desaparecen.
    readonly property var filtered: root.filter(root.query)
    // La misma busqueda para la guia (query) y la pagina Atajos del centro.
    function filter(query: string): var {
        const q = (query || "").trim();
        const out = [];
        for (const g of root.groups) {
            if (g.mode && !root.options.showModes) continue;
            if (!q) {
                out.push(g);
                continue;
            }
            const items = g.items.filter(it => {
                const keys = it.combos.map(c => c.mods.concat(c.keys.map(k => root.words(k))).join(" ")).join(" ");
                return Fuzzy.match(it.text, q) || Fuzzy.match(it.source, q) || Fuzzy.match(g.name, q) || Fuzzy.match(g.source, q)
                    || keys.toLowerCase().indexOf(q.toLowerCase()) >= 0;
            });
            if (items.length) out.push({ name: g.name, source: g.source, icon: g.icon, mode: g.mode, items: items });
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
    // Iconos en palabras (busqueda y lectores de pantalla); los mismos textos que
    // WORDS en scripts/keybinds (la tabla del README).
    readonly property var iconWords: ({
        "@arrows": I18n.trc("key", "Arrows"), "@volume_up": I18n.trc("key", "Volume up"), "@volume_down": I18n.trc("key", "Volume down"), "@volume_off": I18n.trc("key", "Mute"),
        "@mic_off": I18n.trc("key", "Microphone"), "@brightness_high": I18n.trc("key", "Brightness up"), "@brightness_low": I18n.trc("key", "Brightness down"),
        "@play_pause": I18n.trc("key", "Play/Pause"), "@skip_next": I18n.trc("key", "Next"), "@skip_previous": I18n.trc("key", "Previous")
    })
    function words(label: string): string {
        return root.iconWords[label] || label;
    }
}
