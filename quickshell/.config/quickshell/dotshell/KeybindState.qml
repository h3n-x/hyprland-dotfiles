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
    // Busca en la descripcion, el grupo y las teclas (en palabras); los grupos
    // sin coincidencias desaparecen.
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
