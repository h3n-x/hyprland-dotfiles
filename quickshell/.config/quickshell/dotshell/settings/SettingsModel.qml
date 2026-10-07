// Lo que el centro de configuracion muestra, sacado del esquema del almacen
// (Fase 10 B1, P10.1-P10.2): paginas, secciones, el control de cada clave y
// la busqueda. No hay ninguna lista de opciones escrita a mano: una clave
// nueva en data/settings.schema.json aparece en su pagina, con su control,
// y se encuentra al buscar (lo comprueba la prueba de cobertura).
//
// Paginas: Inicio, las categorias del esquema que tienen al menos una clave
// (en el orden del esquema; las vacias no aparecen hasta tener opciones) y
// Acerca de.
import QtQuick
import Quickshell
import Quickshell.Io
import ".." // SettingsState.qml

QtObject {
    id: model

    readonly property var schema: SettingsState.schema
    readonly property var keys: model.schema && model.schema.keys ? model.schema.keys : ({})

    // Claves de cada categoria, ordenadas por "order" (y por nombre si empatan).
    readonly property var byCategory: {
        const out = {};
        for (const k in model.keys) {
            const c = model.keys[k].category;
            (out[c] = out[c] || []).push(k);
        }
        for (const c in out)
            out[c].sort((a, b) => ((model.keys[a].order || 0) - (model.keys[b].order || 0)) || a.localeCompare(b));
        return out;
    }
    readonly property var categories: {
        const cats = model.schema && model.schema.categories ? model.schema.categories : {};
        return Object.keys(cats)
            .filter(id => (model.byCategory[id] || []).length > 0)
            .sort((a, b) => (cats[a].order || 0) - (cats[b].order || 0))
            .map(id => ({ id: id, label: cats[id].label || id, icon: cats[id].icon || "settings" }));
    }
    readonly property var pages: [{ id: "home", label: "Inicio", icon: "home" }]
        .concat(model.categories)
        .concat([{ id: "about", label: "Acerca de", icon: "info" }])

    function page(id: string): var {
        return model.pages.find(p => p.id === id) || null;
    }
    function categoryLabel(id: string): string {
        const p = model.page(id);
        return p ? p.label : id;
    }

    // Secciones de una categoria en el orden de su primera clave:
    // [{ name, keys: [normales], advanced: [avanzadas] }].
    function sections(category: string): var {
        const out = [];
        for (const k of model.byCategory[category] || []) {
            const m = model.keys[k];
            const name = m.section || "";
            let s = out.find(x => x.name === name);
            if (!s) {
                s = { name: name, keys: [], advanced: [] };
                out.push(s);
            }
            (m.advanced ? s.advanced : s.keys).push(k);
        }
        return out;
    }
    function advancedCount(category: string): int {
        return (model.byCategory[category] || []).filter(k => model.keys[k].advanced).length;
    }

    // ---- Control por tipo -------------------------------------------------------------------
    // bool -> interruptor; enum de 3 o menos (o un numero con "presets") ->
    // segmentado; enum mas largo -> selector; int de rango corto (12 o menos)
    // -> paso a paso; el resto de los numeros -> deslizador; path -> ruta (con
    // "Elegir…" si es una imagen o una carpeta); texto de una fuente -> selector
    // de fuentes (Fase 10 B2).
    // "" = tipo sin control (la prueba de cobertura falla).
    function control(key: string): string {
        const m = model.keys[key];
        if (!m) return "";
        if (m.type === "bool") return "switch";
        if (m.type === "enum") return Object.keys(m.values || {}).length <= 3 ? "segmented" : "select";
        if ((m.type === "int" || m.type === "number") && Array.isArray(m.presets)) return "segmented";
        if (m.type === "int" && m.min !== undefined && m.max !== undefined && m.max - m.min <= 12) return "stepper";
        if ((m.type === "int" || m.type === "number") && m.min !== undefined && m.max !== undefined) return "slider";
        if (m.type === "path") return "path";
        if (m.type === "string" && String(m.kind || "").startsWith("font-")) return "font";
        if (m.type === "list" && m.kind === "xkb") return "layouts";
        if (m.type === "location") return "location";
        if (m.type === "string" && m.kind === "player") return "player";
        // Fase 10 B5: horas del dia (luz nocturna) y el panel de pantallas.
        if (m.type === "time") return "time";
        if (m.type === "outputs") return "outputs";
        return "";
    }
    // Opciones [[valor, texto], ...] de un enum (orden del esquema) o de presets.
    function options(key: string): var {
        const m = model.keys[key];
        if (!m) return [];
        // Reproductores (Fase 10 B4): automatico, los abiertos ahora (MediaState,
        // cliente pasivo de MPRIS) y el elegido aunque no este abierto.
        if (m.kind === "player") {
            const out = [["", "Automático"]];
            for (const p of MediaState.players) {
                const k = MediaState.keyOf(p);
                if (k && !out.some(o => o[0] === k)) out.push([k, MediaState.nameOf(p)]);
            }
            const cur = SettingsState.value(key);
            if (cur && !out.some(o => o[0] === cur)) out.push([cur, cur + " (cerrado)"]);
            return out;
        }
        if (m.type === "enum") return Object.keys(m.values).map(v => [v, m.values[v]]);
        if (Array.isArray(m.presets)) return m.presets.map(p => Array.isArray(p) ? p : [p, String(p)]);
        return [];
    }

    // Un valor como se lee en la interfaz ("encendido", "Alta", "1,5 s").
    function format(key: string, v: var): string {
        const m = model.keys[key];
        if (!m || v === undefined || v === null) return "";
        if (m.type === "bool") return v ? "Encendido" : "Apagado";
        if (m.type === "enum") return (m.values && m.values[v]) || String(v);
        if (m.type === "list") return (v || []).join(", ");
        if (m.type === "location") return v ? v.name : "Sin ciudad";
        if (m.kind === "player") return v || "Automático";
        if (m.type === "time") return String(v);
        if (m.type === "outputs") {
            const n = Object.keys(v || {}).length;
            return n === 0 ? "Automática" : n === 1 ? "1 pantalla ajustada" : n + " pantallas ajustadas";
        }
        if (m.labels && m.labels.hasOwnProperty(String(v))) return m.labels[String(v)];
        const preset = Array.isArray(m.presets) ? m.presets.find(p => Array.isArray(p) && Math.abs(p[0] - v) < 0.01) : null;
        if (preset) return preset[1];
        if (m.type === "path") {
            const home = SettingsState.home;
            return home && String(v).startsWith(home + "/") ? "~" + String(v).slice(home.length) : String(v);
        }
        return String(v).replace(".", ",") + (m.unit ? " " + m.unit : "");
    }

    // ---- Valor en Hyprland (Fase 10 B3) ---------------------------------------------------
    // Para las claves con "hypr": lo que Hyprland usa ahora (scripts/settings-apply
    // live, un solo proceso por pagina). live[clave] = { same, live: [...] }.
    // Se pide al abrir la pagina y despues de un cambio; nunca periodicamente.
    // Sin escuchar los eventos de Hyprland: recibirlos todos (foco, ventanas)
    // costaba CPU con la ventana quieta, por una recarga a mano que es rara.
    property var live: ({})
    property var liveKeys: []
    function refreshLive(category: string): void {
        model.liveKeys = (model.byCategory[category] || []).filter(k => !!model.keys[k].hypr);
        if (!model.liveKeys.length) return;
        liveTimer.restart();
    }
    property Timer liveTimer: Timer {
        interval: 250
        onTriggered: {
            if (liveProc.running) { liveTimer.restart(); return; }
            liveProc.command = [Quickshell.env("SETTINGS_APPLY_CMD") || (Quickshell.env("HOME") + "/.config/hypr/scripts/settings-apply"), "live"].concat(model.liveKeys);
            liveProc.running = true;
        }
    }
    // Despues de un cambio (el motor ya lo aplico).
    property Connections liveOnChange: Connections {
        target: SettingsState
        function onValuesChanged() { if (model.liveKeys.length) liveTimer.restart(); }
    }
    property Process liveProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    model.live = Object.assign({}, model.live, JSON.parse(this.text));
                } catch (e) {}
            }
        }
    }

    // Que pasa al cambiarla (badge de la fila); "" = al instante.
    function applyNote(key: string): string {
        const m = model.keys[key];
        return !m ? "" : ({
            "next-use": "La próxima vez",
            "reload-shell": "Reinicia la shell",
            "relogin": "Al volver a entrar",
            "reboot": "Al reiniciar el equipo"
        })[m.apply] || "";
    }

    // ---- Busqueda -------------------------------------------------------------------------
    // Sin tildes ni mayusculas; todas las palabras tienen que aparecer en la
    // etiqueta, la descripcion, las palabras clave, la categoria o la seccion.
    function fold(s: string): string {
        return String(s).normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
    }
    readonly property var index: {
        const out = [];
        for (const k in model.keys) {
            const m = model.keys[k];
            out.push({
                key: k,
                label: model.fold(m.label || k),
                text: model.fold([m.label, m.description || "", (m.keywords || []).join(" "), model.categoryLabel(m.category), m.section || ""].join(" "))
            });
        }
        return out;
    }
    // Hasta `limit` claves: primero las que empiezan con la busqueda, despues
    // las que la tienen en la etiqueta, despues el resto (orden del esquema).
    function search(query: string, limit: int): var {
        const words = model.fold(query).trim().split(/\s+/).filter(w => w);
        if (!words.length) return [];
        const hits = model.index.filter(e => words.every(w => e.text.indexOf(w) >= 0));
        const rank = e => e.label.startsWith(words[0]) ? 0 : words.every(w => e.label.indexOf(w) >= 0) ? 1 : 2;
        const pos = k => model.categories.findIndex(c => c.id === model.keys[k].category) * 10000 + (model.keys[k].order || 0);
        hits.sort((a, b) => (rank(a) - rank(b)) || (pos(a.key) - pos(b.key)));
        return hits.slice(0, limit > 0 ? limit : hits.length).map(e => e.key);
    }
}
