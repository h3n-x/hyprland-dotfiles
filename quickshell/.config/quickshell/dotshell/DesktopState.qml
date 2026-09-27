// Escritorios y ventanas de Hyprland en un solo lugar (Fase 4 B7). Lo usan
// la pill de workspaces de la barra (slots), el selector de ventanas (B4,
// lista por uso reciente) y el dashboard (miniaturas con la geometria real).
// Tambien las acciones sobre Hyprland (ir a un workspace, enfocar o cerrar
// una ventana): DESKTOP_DRY=1 (solo pruebas) las registra sin despacharlas.
//
// Workspaces y foco llegan por el socket de eventos (Quickshell.Hyprland,
// reactivo). La geometria de las ventanas, los monitores y la decoracion
// (gaps, rounding, borde y sus colores) no: salen de hyprctl en UNA consulta
// (~13 ms) cuando alguien la pide -- al abrir el selector o el dashboard -- y,
// solo mientras alguno de los dos se ve (Demand live), otra vez tras cada
// evento de ventanas (agrupados en 150 ms). Cerrado todo, no corre nada.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: root

    // ---- Slots de la barra: 1..N, con huecos rellenos --------------------------
    // Siempre al menos 5 (como el persistent-workspaces de waybar); N = el id
    // mas alto si es mayor. Un slot sin workspace real es un marcador liviano
    // {id, placeholder: true}: enfocarlo lo crea.
    // bar.minWorkspaces (settings store)
    readonly property int minWorkspaces: SettingsState.value("bar.minWorkspaces")
    readonly property var slots: {
        const real = Hyprland.workspaces.values.filter(w => w.id > 0);
        const maxId = real.reduce((m, w) => Math.max(m, w.id), 0);
        const count = Math.max(root.minWorkspaces, maxId);
        const result = [];
        for (let i = 1; i <= count; i++)
            result.push(real.find(w => w.id === i) || { id: i, placeholder: true });
        return result;
    }
    // ---- Acciones ---------------------------------------------------------------------
    readonly property bool dry: Quickshell.env("DESKTOP_DRY") === "1"
    property string lastCommand: ""
    function dispatch(cmd: string): void {
        root.lastCommand = cmd;
        if (root.dry) console.log("DESKTOP_DRY " + cmd);
        else Hyprland.dispatch(cmd);
    }
    function focusWorkspace(id: int): void {
        root.dispatch("hl.dsp.focus({ workspace = " + id + " })");
    }
    // Enfocar una ventana (y su workspace) en el acto. A los 250 ms se
    // comprueba que quedo activa y si no se repite una vez (a veces el primer
    // intento se pierde mientras se suelta el foco de un panel).
    property string focusTarget: ""
    function focusWindow(address: string): void {
        root.focusTarget = root.addr(address);
        root.dispatch('hl.dsp.focus({ window = "address:' + root.focusTarget + '" })');
        verify.restart();
    }
    function closeWindow(address: string): void {
        root.dispatch('hl.dsp.window.close({ window = "address:' + root.addr(address) + '" })');
    }
    property Timer verify: Timer {
        interval: 250
        onTriggered: {
            if (root.dry || !root.focusTarget) return;
            const t = root.toplevelOf(root.focusTarget);
            if (t && !t.activated) Hyprland.dispatch('hl.dsp.focus({ window = "address:' + root.focusTarget + '" })');
        }
    }

    // Ventana del reproductor que esta sonando (la usada mas recientemente de
    // esa aplicacion): las miniaturas le ponen el ecualizador.
    readonly property string mediaWindow: {
        const e = MediaState.playingEntry;
        if (!e) return "";
        const w = root.windows.filter(x => AppInfo.entry(x.cls) === e).sort((a, b) => a.history - b.history)[0];
        return w ? w.address : "";
    }

    // ---- Ventanas, monitores y decoracion (hyprctl) -----------------------------
    // windows: [{ address, title, cls, wsId, ws, special, monitor, x, y, w, h,
    //   floating, hidden (pestana no visible de un grupo), fullscreen, urgent,
    //   focused, history, capturable }]
    // (x, y relativos a su monitor, en pixeles logicos).
    property var windows: []
    // monitors: nombre -> { x, y, width, height (logicos), reserved [izq, arr, der, abajo] }
    property var monitors: ({})
    // Decoracion de Hyprland: las miniaturas se dibujan con los mismos valores.
    property var decoration: ({ gapsIn: 4, gapsOut: 12, border: 2, rounding: 12, active: [], angle: 0, inactive: [] })
    property bool loaded: false
    // Version de Hyprland ("0.56.0"), con la decoracion.
    property string version: ""
    signal updated()

    // Solo ventanas de al menos 24x24: capturar una mas chica (dwindle con
    // muchas ventanas da tamanos minimos o negativos) crea un buffer de 0x0 y
    // tira la conexion Wayland de la shell entera (KI-L18).
    readonly property int minCaptureSize: 24

    function addr(a: string): string {
        return a.startsWith("0x") ? a : "0x" + a;
    }
    function toplevelOf(address: string): var {
        const a = root.addr(address);
        return Hyprland.toplevels.values.find(t => root.addr(t.address) === a) || null;
    }
    function windowsOf(wsId: int): var {
        return root.windows.filter(w => w.wsId === wsId);
    }

    function refresh(): void {
        if (query.running) {
            root.again = true;
            return;
        }
        query.running = true;
    }
    property bool again: false

    // "#AARRGGBB" desde el "eeffb7b0" de hyprctl (ARGB sin prefijo).
    function argb(hex: string): string {
        return "#" + hex;
    }
    function gradient(value: string): var {
        const parts = (value || "").trim().split(/\s+/);
        const angle = parts.length && parts[parts.length - 1].endsWith("deg") ? parseInt(parts.pop()) : 0;
        return { colors: parts.filter(p => /^[0-9a-fA-F]{8}$/.test(p)).map(root.argb), angle: angle };
    }
    function parse(text: string): void {
        const docs = text.split("\x1e");
        let clients = [], mons = [], opts = {};
        try {
            clients = JSON.parse(docs[0]);
            mons = JSON.parse(docs[1]);
            for (let i = 2; i < docs.length; i++) {
                if (!docs[i].trim()) continue;
                const o = JSON.parse(docs[i]);
                if (o.option) opts[o.option] = o;
                else if (o.tag || o.version) root.version = String(o.tag || o.version).replace(/^v/, "").replace(/-.*$/, "");
            }
        } catch (e) {
            return;
        }
        const byId = {};
        const monitors = {};
        for (const m of mons) {
            const s = m.scale || 1;
            const r = m.reserved || [0, 0, 0, 0];
            byId[m.id] = m.name;
            monitors[m.name] = { x: m.x, y: m.y, width: Math.round(m.width / s), height: Math.round(m.height / s), reserved: r };
        }
        root.monitors = monitors;
        root.windows = clients
            .filter(c => c.mapped && !!c.workspace)
            .map(c => {
                const monName = byId[c.monitor] || "";
                const mon = monitors[monName] || { x: 0, y: 0 };
                return {
                    address: root.addr(c.address),
                    title: c.title || c.initialTitle || c["class"] || "",
                    cls: c["class"] || c.initialClass || "",
                    wsId: c.workspace.id,
                    ws: c.workspace.name,
                    special: c.workspace.name.startsWith("special"),
                    monitor: monName,
                    x: c.at[0] - mon.x,
                    y: c.at[1] - mon.y,
                    w: c.size[0],
                    h: c.size[1],
                    floating: !!c.floating,
                    hidden: !!c.hidden,
                    fullscreen: (c.fullscreen || 0) > 0,
                    urgent: !!c.urgent,
                    focused: c.focusHistoryID === 0,
                    history: c.focusHistoryID,
                    capturable: c.size[0] >= root.minCaptureSize && c.size[1] >= root.minCaptureSize
                };
            });
        const css = (o, i) => o && o.css ? parseInt(o.css.split(" ")[i || 0]) : undefined;
        const d = root.decoration;
        const act = root.gradient(opts["general:col.active_border"] ? opts["general:col.active_border"].gradient : "");
        const ina = root.gradient(opts["general:col.inactive_border"] ? opts["general:col.inactive_border"].gradient : "");
        if (Object.keys(opts).length) {
            root.decoration = {
                gapsIn: css(opts["general:gaps_in"]) ?? d.gapsIn,
                gapsOut: css(opts["general:gaps_out"]) ?? d.gapsOut,
                border: opts["general:border_size"] ? opts["general:border_size"].int : d.border,
                rounding: opts["decoration:rounding"] ? opts["decoration:rounding"].int : d.rounding,
                active: act.colors,
                angle: act.angle,
                inactive: ina.colors
            };
            root.decorationLoaded = true;
        }
        root.loaded = true;
        root.updated();
    }
    // La decoracion solo cambia al recargar la config: se pide la primera vez
    // y tras "configreloaded".
    property bool decorationLoaded: false
    readonly property var options: ["general:gaps_in", "general:gaps_out", "general:border_size",
        "decoration:rounding", "general:col.active_border", "general:col.inactive_border"]

    property Process query: Process {
        command: ["sh", "-c", 'hyprctl -j clients; printf "\\036"; hyprctl -j monitors; for o in "$@"; do printf "\\036"; hyprctl -j getoption "$o"; done; [ $# -gt 0 ] && { printf "\\036"; hyprctl -j version; }', "sh"]
            .concat(root.decorationLoaded ? [] : root.options)
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
        onExited: {
            if (root.again) {
                root.again = false;
                root.refresh();
            }
        }
    }

    // ---- Seguimiento mientras alguien lo mira (Fase 8 B3) -------------------------
    // Dashboard y selector de ventanas se suscriben (Subscription): mientras
    // hay alguien, cada evento de ventanas vuelve a consultar (con 150 ms de
    // espera). La lista se conserva al soltar: es chica y la proxima apertura
    // la muestra al instante mientras llega la nueva.
    property Demand live: Demand {
        name: "desktop.live"
        onActiveChanged: if (active) root.refresh()
    }
    property string lastActive: ""
    // Sin "windowtitlev2": un titulo que cambia seguido (una terminal con una
    // tarea en curso) dispararia una consulta cada 150 ms y no cambia nada
    // de lo que se dibuja. Hyprland tambien repite "activewindowv2" con cada
    // cambio de titulo de la ventana enfocada: cuenta solo si cambia la
    // ventana (su direccion).
    readonly property var windowEvents: ["openwindow", "closewindow", "movewindowv2", "changefloatingmode",
        "fullscreen", "activewindowv2", "movetoworkspacev2"]
    property Connections events: Connections {
        target: Hyprland
        function onRawEvent(event: var): void {
            if (event.name === "configreloaded") root.decorationLoaded = false;
            if (event.name === "activewindowv2") {
                if (event.data === root.lastActive) return;
                root.lastActive = event.data;
            }
            if (root.live.active && (root.windowEvents.indexOf(event.name) >= 0 || event.name === "configreloaded"))
                debounce.restart();
        }
    }
    property Timer debounce: Timer {
        interval: 150
        onTriggered: root.refresh()
    }
}
