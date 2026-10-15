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
    // Las claves con sus textos en el idioma elegido (Fase 15 B3): el esquema esta en
    // ingles (la clave del catalogo, contexto "settings"); aqui se traduce una vez y
    // todas las paginas leen esto. "section" sigue en ingles (identifica la seccion,
    // p. ej. extras["Color"]) y sectionLabel es su texto; source guarda el ingles de
    // lo que se busca. Se rearma al cambiar el catalogo (I18n.rev).
    readonly property var keys: model.localized(model.schema && model.schema.keys ? model.schema.keys : ({}), I18n.rev)
    function t(s: var): var {
        return typeof s === "string" && s ? I18n.trc("settings", s) : s;
    }
    function localized(raw: var, rev: int): var {
        const each = (o, f) => {
            const r = {};
            for (const k in o) r[k] = f(o[k]);
            return r;
        };
        const out = {};
        for (const k in raw) {
            const m = raw[k];
            const c = Object.assign({}, m);
            for (const f of ["label", "description", "unit", "placeholder"])
                if (m[f] !== undefined) c[f] = model.t(m[f]);
            c.sectionLabel = model.t(m.section || "");
            if (m.values) c.values = each(m.values, model.t);
            if (m.labels) c.labels = each(m.labels, model.t);
            if (m.items && m.items.values) c.items = Object.assign({}, m.items, { values: each(m.items.values, model.t) });
            if (Array.isArray(m.presets)) c.presets = m.presets.map(p => Array.isArray(p) ? [p[0], model.t(p[1])] : p);
            if (m.modules) c.modules = each(m.modules, x => Object.assign({}, x, { label: model.t(x.label) }));
            if (m.widgets) c.widgets = each(m.widgets, x => x.description ? Object.assign({}, x, { description: model.t(x.description) }) : x);
            // Palabras clave: el ingles del esquema y su traduccion (una cadena por clave).
            const kw = (m.keywords || []).join(" | ");
            c.keywords = kw ? I18n.trc("settings keywords", kw).split(" | ") : [];
            c.source = { label: m.label || "", description: m.description || "", section: m.section || "", keywords: m.keywords || [] };
            out[k] = c;
        }
        return out;
    }

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
            .map(id => ({ id: id, label: model.t(cats[id].label || id), source: cats[id].label || id, icon: cats[id].icon || "settings" }));
    }
    readonly property var pages: [{ id: "home", label: I18n.tr("Home"), icon: "home" }]
        .concat(model.categories)
        .concat([{ id: "about", label: I18n.tr("About"), icon: "info" }])

    function page(id: string): var {
        return model.pages.find(p => p.id === id) || null;
    }
    function categoryLabel(id: string): string {
        const p = model.page(id);
        return p ? p.label : id;
    }

    // Secciones de una categoria en el orden de su primera clave:
    // [{ name (ingles, la identifica), label (su texto), keys: [normales], advanced: [avanzadas] }].
    function sections(category: string): var {
        const out = [];
        for (const k of model.byCategory[category] || []) {
            const m = model.keys[k];
            const name = m.section || "";
            let s = out.find(x => x.name === name);
            if (!s) {
                s = { name: name, label: m.sectionLabel, keys: [], advanced: [] };
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
        // Texto corto sin tipo especial (Fase 11 B5: el nombre del saludo).
        if (m.type === "string" && !m.kind) return "text";
        if (m.type === "string" && String(m.kind || "").startsWith("font-")) return "font";
        if (m.type === "list" && m.kind === "xkb") return "layouts";
        if (m.type === "location") return "location";
        if (m.type === "string" && m.kind === "player") return "player";
        // Fase 10 B5: horas del dia (luz nocturna) y el panel de pantallas.
        if (m.type === "time") return "time";
        if (m.type === "outputs") return "outputs";
        // Fase 11 B1: la disposicion de la barra y en que pantallas va.
        if (m.type === "barLayout") return "barLayout";
        if (m.type === "list" && m.kind === "screens") return "screens";
        // Fase 11 B5: aplicaciones y carpetas fijadas (Accesos rapidos).
        if (m.type === "list" && (m.kind === "apps" || m.kind === "folders")) return m.kind;
        // Fase 11 B5b: varias opciones de un enum, cada una con su interruptor.
        if (m.type === "list" && m.kind === "checks") return "checks";
        // Fase 11 B4: las zonas de Inicio (resumen; se editan en el dashboard).
        if (m.type === "homeZones") return "homeZones";
        if (m.type === "tiles") return "tiles";
        return "";
    }
    // Opciones [[valor, texto], ...] de un enum (orden del esquema) o de presets.
    function options(key: string): var {
        const m = model.keys[key];
        if (!m) return [];
        // Reproductores (Fase 10 B4): automatico, los abiertos ahora (MediaState,
        // cliente pasivo de MPRIS) y el elegido aunque no este abierto.
        if (m.kind === "player") {
            const out = [["", I18n.tr("Automatic")]];
            for (const p of MediaState.players) {
                const k = MediaState.keyOf(p);
                if (k && !out.some(o => o[0] === k)) out.push([k, MediaState.nameOf(p)]);
            }
            const cur = SettingsState.value(key);
            if (cur && !out.some(o => o[0] === cur)) out.push([cur, I18n.tr("%1 (closed)", cur)]);
            return out;
        }
        if (m.type === "enum") return Object.keys(m.values).map(v => [v, m.values[v]]);
        if (m.kind === "checks") return Object.keys((m.items || {}).values || {}).map(v => [v, m.items.values[v]]);
        if (Array.isArray(m.presets)) return m.presets.map(p => Array.isArray(p) ? p : [p, String(p)]);
        return [];
    }

    // Un valor como se lee en la interfaz ("On", "High", "1.5 s"), en el idioma elegido.
    function format(key: string, v: var): string {
        const m = model.keys[key];
        if (!m || v === undefined || v === null) return "";
        if (m.type === "bool") return v ? I18n.tr("On") : I18n.tr("Off");
        if (m.type === "enum") return (m.values && m.values[v]) || String(v);
        if (m.type === "list") return I18n.join(v || []);
        if (m.type === "location") return v ? v.name : I18n.tr("No city");
        if (m.kind === "player") return v || I18n.tr("Automatic");
        if (m.type === "time") return String(v);
        if (m.type === "barLayout") {
            const n = ["start", "center", "end"].reduce((a, s) => a + (v[s] || []).reduce((b, it) => b + (it && it.pill ? it.pill.length : it === "spacer" ? 0 : 1), 0), 0);
            return I18n.trn("%n module", "%n modules", n);
        }
        if (m.kind === "screens") return (v || []).length ? I18n.join(v) : I18n.trc("options", "All");
        if (m.kind === "checks") {
            const all = Object.keys((m.items || {}).values || {}).length;
            const n = (v || []).length;
            return n === all ? I18n.trc("options", "All") : n === 0 ? I18n.trc("options", "None") : I18n.tr("%1 of %2", I18n.number(n), I18n.number(all));
        }
        if (m.kind === "apps") return (v || []).length ? I18n.join((v || []).map(id => AppInfo.name(id))) : I18n.trc("options", "None");
        if (m.kind === "folders") return (v || []).length ? I18n.join((v || []).map(p => p.split("/").pop())) : I18n.tr("The personal folders");
        if (m.type === "tiles") {
            const n = (v || []).length;
            return n === 0 ? I18n.trc("tiles", "None") : I18n.trn("%n setting", "%n settings", n);
        }
        if (m.type === "homeZones") {
            const n = (v || []).length;
            return n === 0 ? I18n.tr("No zones") : I18n.trn("%n zone", "%n zones", n);
        }
        if (m.type === "outputs") {
            const n = Object.keys(v || {}).length;
            return n === 0 ? I18n.trc("displays", "Automatic") : I18n.trn("%n display adjusted", "%n displays adjusted", n);
        }
        if (m.labels && m.labels.hasOwnProperty(String(v))) return m.labels[String(v)];
        const preset = Array.isArray(m.presets) ? m.presets.find(p => Array.isArray(p) && Math.abs(p[0] - v) < 0.01) : null;
        if (preset) return preset[1];
        if (m.type === "path") {
            const home = SettingsState.home;
            return home && String(v).startsWith(home + "/") ? "~" + String(v).slice(home.length) : String(v);
        }
        if (m.percent) return I18n.tr("%1 %", I18n.number(Math.round(v * 100)));
        // Con los decimales del valor y sin separador de miles (6500 K), con la coma o el punto del idioma.
        return String(v).replace(".", I18n.locale.decimalPoint) + (m.unit ? " " + m.unit : "");
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
            "next-use": I18n.tr("Next time"),
            "reload-shell": I18n.tr("Restarts the shell"),
            "relogin": I18n.tr("On next login"),
            "reboot": I18n.tr("On reboot")
        })[m.apply] || "";
    }

    // ---- Busqueda -------------------------------------------------------------------------
    // Sin tildes ni mayusculas; todas las palabras tienen que aparecer en la
    // etiqueta, la descripcion, las palabras clave, la categoria o la seccion, en el
    // idioma elegido o en ingles (Fase 15 B3: un nombre visto en una guia en ingles
    // tambien se encuentra).
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
                text: model.fold([m.label, m.description || "", m.keywords.join(" "), model.categoryLabel(m.category), m.sectionLabel,
                    m.source.label, m.source.description, m.source.keywords.join(" "), (model.categories.find(c => c.id === m.category) || {}).source || "", m.source.section].join(" "))
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
