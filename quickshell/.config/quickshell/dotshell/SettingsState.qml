// Opciones del ecosistema en la shell (Fase 8 B1, P8.1). Solo lee la cache
// efectiva que deja hypr/scripts/settings (el motor: la unica implementacion
// de tipos, rangos, migraciones y cuarentena) y le pide los cambios; nunca
// lee ni escribe settings.json. Las claves y sus valores de fabrica viven en
// data/settings.schema.json (principio 22: todo valor ajustable se declara
// ahi desde el primer dia).
//
//   SettingsState.value("capture.cardSeconds")      // se reevalua al cambiar
//   SettingsState.set("accessibility.reduceMotion", true)
//
// Al arrancar lee la cache de la sesion anterior de forma sincronica (sin
// parpadeo) y pide una regeneracion; despues sigue la cache (cambios de
// cualquier escritor) y el archivo del usuario (ediciones a mano). Quieto no
// hace nada. Pruebas: SETTINGS_* (ver el script) y SETTINGS_SCRIPT.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string script: Quickshell.env("SETTINGS_SCRIPT") || (root.home + "/.config/hypr/scripts/settings")
    readonly property string schemaPath: Quickshell.env("SETTINGS_SCHEMA") || Quickshell.shellPath("data/settings.schema.json")
    readonly property string userPath: Quickshell.env("SETTINGS_FILE") || (root.home + "/.config/dotfiles/settings.json")
    readonly property string effectivePath: Quickshell.env("SETTINGS_EFFECTIVE")
        || ((Quickshell.env("XDG_CACHE_HOME") || root.home + "/.cache") + "/dotfiles/settings.effective.json")

    // ---- Lectura -------------------------------------------------------------------------------
    // values: todas las claves con su valor efectivo; modified: las que el
    // usuario cambio; problems: valores en cuarentena (no aplicados).
    property var values: ({})
    property var modified: []
    property var problems: []
    property bool ready: false
    // Cambios pedidos que el motor todavia no confirmo (se ven al instante).
    property var pending: ({})

    function value(key: string): var {
        if (root.pending.hasOwnProperty(key)) return root.pending[key];
        if (root.ready) return root.values[key];
        // Todavia construyendose (un consumidor la pidio al arrancar): se lee
        // la cache, o el esquema, de forma sincronica y sin asignar nada; los
        // enlaces se reevaluan cuando llega la carga normal (ready).
        return root.bootValues()[key];
    }
    function bootValues(): var {
        try {
            const eff = JSON.parse(root.effective.text());
            if (eff && eff.values) return eff.values;
        } catch (e) {}
        try {
            return root.defaultsFrom(JSON.parse(root.schemaFile.text()));
        } catch (e) {}
        return {};
    }
    function defaultsFrom(s: var): var {
        const v = {};
        for (const k in s.keys) {
            const d = s.keys[k].default;
            v[k] = s.keys[k].type === "path" && typeof d === "string" && d.startsWith("~") ? root.home + d.slice(1) : d;
        }
        return v;
    }
    function isModified(key: string): bool {
        return root.modified.indexOf(key) >= 0;
    }
    // Metadatos del esquema (etiqueta, rango, apply...), para el centro de configuracion.
    function meta(key: string): var {
        return root.schema && root.schema.keys ? root.schema.keys[key] : undefined;
    }

    // ---- Escritura (siempre por el motor) -----------------------------------------------------
    // Cambios seguidos de la misma clave (un deslizador) se agrupan 150 ms.
    // Las claves cuyo "apply" pide reiniciar algo quedan en pendingRestart.
    property var pendingRestart: []
    function set(key: string, v: var): void {
        const m = root.meta(key);
        if (!m) {
            console.warn("SettingsState: clave desconocida " + key);
            return;
        }
        const p = Object.assign({}, root.pending);
        p[key] = v;
        root.pending = p;
        root.outbox[key] = ["set", key, JSON.stringify(v)];
        flush.restart();
        if (["reload-shell", "relogin", "reboot"].indexOf(m.apply) >= 0 && root.pendingRestart.indexOf(key) < 0)
            root.pendingRestart = root.pendingRestart.concat([key]);
    }
    function reset(key: string): void {
        const p = Object.assign({}, root.pending);
        const m = root.meta(key);
        if (m) p[key] = m.default;
        root.pending = p;
        root.outbox[key] = ["reset", key];
        flush.restart();
    }
    function resetCategory(category: string): void {
        root.outbox["@" + category] = ["reset-category", category];
        flush.restart();
    }

    property var outbox: ({})
    property var queue: []
    property Timer flush: Timer {
        interval: 150
        onTriggered: {
            root.queue = root.queue.concat(Object.values(root.outbox));
            root.outbox = {};
            root.next();
        }
    }
    function next(): void {
        if (writer.running || !root.queue.length) return;
        const args = root.queue[0];
        root.queue = root.queue.slice(1);
        writer.command = [root.script].concat(args);
        writer.running = true;
    }
    property Process writer: Process {
        stderr: StdioCollector {
            onStreamFinished: if (this.text.trim()) console.warn("SettingsState: " + this.text.trim())
        }
        // Si el motor rechaza el valor, se descarta el cambio pendiente.
        onExited: (code) => {
            const args = writer.command.slice(1);
            if (code !== 0 && args[0] === "set") root.drop(args[1]);
            root.next();
        }
    }
    function drop(key: string): void {
        const p = Object.assign({}, root.pending);
        delete p[key];
        root.pending = p;
    }

    // Esquema (defaults, etiquetas): se lee una vez, de forma sincronica y
    // antes que la cache.
    property var schema: null
    property FileView schemaFile: FileView {
        path: root.schemaPath
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                root.schema = JSON.parse(root.schemaFile.text());
                // Sin cache todavia: los valores de fabrica ya, antes de que
                // ningun consumidor los lea (primera vez en un equipo).
                if (!root.ready) Qt.callLater(root.applyDefaults);
            } catch (e) {
                console.warn("SettingsState: esquema ilegible");
            }
        }
    }

    // ---- Cache efectiva y archivo del usuario ------------------------------------------------
    property FileView effective: FileView {
        path: root.effectivePath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        // Diferido: una carga pedida desde value() (bootValues) no debe
        // cambiar values/ready en medio de ese mismo enlace.
        onLoaded: Qt.callLater(() => root.apply(root.effective.text()))
        onLoadFailed: Qt.callLater(root.applyDefaults)
    }
    // Solo se vigila (nunca se lee): una edicion a mano se valida con el motor.
    property FileView userWatch: FileView {
        path: root.userPath
        preload: false
        watchChanges: true
        printErrors: false
        onFileChanged: regen.restart()
    }
    property Timer regen: Timer {
        interval: 100
        onTriggered: if (!dumper.running) dumper.running = true
    }
    property Process dumper: Process {
        command: [root.script, "dump"]
        stdout: StdioCollector {}
    }

    function apply(text: string): void {
        let eff = null;
        try {
            eff = JSON.parse(text);
        } catch (e) {
            return;
        }
        root.values = eff.values || {};
        root.modified = eff.modified || [];
        root.problems = eff.problems || [];
        // Lo confirmado deja de estar pendiente.
        const p = {};
        for (const k in root.pending)
            if (JSON.stringify(root.values[k]) !== JSON.stringify(root.pending[k])) p[k] = root.pending[k];
        if (Object.keys(p).length !== Object.keys(root.pending).length) root.pending = p;
        root.ready = true;
    }
    // Primera vez (sin cache): los valores de fabrica del esquema hasta que el
    // motor termine (~80 ms); las rutas con "~" se expanden aca solo por eso.
    function applyDefaults(): void {
        const s = root.schema;
        if (!s || !s.keys) return;
        root.values = root.defaultsFrom(s);
        root.ready = true;
    }

    Component.onCompleted: {
        if (!root.ready) root.applyDefaults();
        dumper.running = true;
    }
}
