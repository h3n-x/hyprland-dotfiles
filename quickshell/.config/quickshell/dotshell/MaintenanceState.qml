// Mantenimiento del sistema (Fase 4 B9): la unica fuente de actualizaciones y
// de salud del sistema. La barra informa (pill de actualizaciones), el
// dashboard explica (vista Mantenimiento) y las acciones reales ocurren en una
// terminal visible (hypr/scripts/maintenance run ..., decision E7: nada
// privilegiado desde la shell).
//
// Datos: "maintenance data quick|updates|sizes" (solo lectura) al arrancar,
// cada hora, al abrir la vista (tamanos solo si tienen mas de 10 min) y
// despues de cada operacion de pacman o de cada terminal de mantenimiento
// (vigilancia de /var/log/pacman.log sin leerlo). Cerrado no corre nada mas.
//
// Cada elemento tiene un id estable y metricas numericas aparte de su frase:
// un historial futuro (mejoro, empeoro, cuanto se libero, desde cuando) se
// apoya en eso sin cambiar este archivo. MAINT_DRY=1 (solo pruebas) registra
// las acciones en vez de abrir la terminal; MAINT_SCRIPT, MAINT_STATE y
// MAINT_PACMAN_LOG cambian las rutas del script, del estado y del registro de pacman.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string script: Quickshell.env("MAINT_SCRIPT") || (root.home + "/.config/hypr/scripts/maintenance")
    readonly property string stateFile: Quickshell.env("MAINT_STATE") || (root.home + "/.local/state/dotfiles/maintenance.json")
    readonly property bool dry: Quickshell.env("MAINT_DRY") === "1"

    // ---- Datos crudos (JSON del script) ---------------------------------------------
    property var quick: null
    property var updates: null
    property var sizes: null
    property bool checking: quickProc.running || updatesProc.running || sizesProc.running
    readonly property real checkedAt: root.quick ? root.quick.checkedAt * 1000 : 0

    // Revisa lo rapido siempre; actualizaciones (red) y tamanos solo si lo
    // guardado tiene mas de 10 min, salvo force (cada hora, Revisar, pacman).
    function refresh(force: bool): void {
        const stale = v => force || !v || Date.now() - v.checkedAt * 1000 > 600000;
        if (!quickProc.running) quickProc.running = true;
        if (!updatesProc.running && stale(root.updates)) updatesProc.running = true;
        if (!sizesProc.running && stale(root.sizes)) sizesProc.running = true;
        SystemState.refreshStorage();
    }

    component JsonProc: Process {
        id: jp
        signal parsed(var value)
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    jp.parsed(JSON.parse(this.text));
                } catch (e) {}
            }
        }
    }
    JsonProc {
        id: quickProc
        command: [root.script, "data", "quick"]
        onParsed: v => root.quick = v
    }
    JsonProc {
        id: updatesProc
        command: [root.script, "data", "updates"]
        onParsed: v => root.updates = v
    }
    // Que explica y que ejecuta cada accion (la misma tabla que "run"); una vez.
    property var plan: ({})
    JsonProc {
        command: [root.script, "data", "plan"]
        running: true
        onParsed: v => root.plan = v
    }
    JsonProc {
        id: sizesProc
        command: [root.script, "data", "sizes"]
        onParsed: v => root.sizes = v
    }

    // Al arrancar y cada hora (el mismo chequeo que tenia la pill).
    Timer {
        // system.maintenance.checkIntervalMinutes (settings store)
        interval: SettingsState.value("system.maintenance.checkIntervalMinutes") * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh(true)
    }
    // Despues de cada operacion de pacman: el registro cambia; no se lee
    // (preload false), solo se espera a que termine la escritura.
    FileView {
        path: Quickshell.env("MAINT_PACMAN_LOG") || "/var/log/pacman.log"
        preload: false
        watchChanges: true
        printErrors: false
        onFileChanged: pacmanSettle.restart()
    }
    Timer {
        id: pacmanSettle
        interval: 3000
        onTriggered: {
            if (!quickProc.running) quickProc.running = true;
            if (!updatesProc.running) updatesProc.running = true;
            if (!sizesProc.running) sizesProc.running = true;
        }
    }

    // ---- Servicios ocultos (estado persistente, B9-e) ----------------------------------
    // { version: 1, ignoredUnits: [...], firstSeen: {} } -- firstSeen queda
    // reservado para el historial.
    property var ignoredUnits: []
    FileView {
        id: stateView
        path: root.stateFile
        printErrors: false
        onLoaded: {
            try {
                const s = JSON.parse(stateView.text());
                root.ignoredUnits = s.ignoredUnits || [];
            } catch (e) {}
        }
    }
    function saveState(): void {
        stateView.setText(JSON.stringify({ version: 1, ignoredUnits: root.ignoredUnits, firstSeen: {} }, null, 2) + "\n");
    }
    function ignoreUnit(name: string): void {
        if (root.ignoredUnits.indexOf(name) >= 0) return;
        root.ignoredUnits = root.ignoredUnits.concat([name]);
        root.saveState();
    }
    function restoreUnit(name: string): void {
        root.ignoredUnits = root.ignoredUnits.filter(n => n !== name);
        root.saveState();
    }

    // ---- Acciones: siempre en una terminal visible --------------------------------------
    property var lastCommand: []
    function act(action: string, arg: string, scope: string): void {
        // Reiniciar pasa por la confirmacion del menu de energia; las capturas
        // se abren como en la vista previa (CaptureState, la misma accion).
        if (action === "reboot") {
            root.lastCommand = ["power", "confirm", "reboot"];
            if (!root.dry) PowerState.openConfirm("reboot");
            else console.log("MAINT_DRY " + JSON.stringify(root.lastCommand));
            return;
        }
        if (action === "captures") {
            root.lastCommand = ["captures", root.sizes ? root.sizes.captures.screenshots.dir : ""];
            if (!root.dry) CaptureState.showInFolder(root.lastCommand[1]);
            else console.log("MAINT_DRY " + JSON.stringify(root.lastCommand));
            return;
        }
        const cmd = ["kitty", "--class", "dotfiles-maintenance", "-e", root.script, "run", action];
        if (arg) cmd.push(arg);
        if (scope) cmd.push(scope);
        root.lastCommand = cmd;
        if (root.dry) {
            console.log("MAINT_DRY " + JSON.stringify(cmd));
            return;
        }
        if (terminal.running) return; // una a la vez
        terminal.command = cmd;
        terminal.running = true;
    }
    // Al cerrar la terminal se revisa de nuevo (papelera, volcados, diario no
    // pasan por pacman).
    Process {
        id: terminal
        onExited: root.refresh(true)
    }

    // ---- Pill de la barra (informa) ------------------------------------------------------
    readonly property int updateCount: root.updates ? root.updates.repo.length + root.updates.aur.length : 0
    readonly property bool rebootPending: !!(root.quick && root.quick.reboot)
    readonly property string pillIcon: !root.updates ? "schedule"
        : root.rebootPending ? "restart_alt"
        : root.updates.error && root.updateCount === 0 ? "sync_problem"
        : root.updateCount > 0 ? "download" : "check"

    // ---- Elementos: severidad y frases ---------------------------------------------------
    // sev: 0 Informacion, 1 Recomendacion, 2 Advertencia, 3 Accion importante.
    readonly property var sevNames: ["Información", "Recomendación", "Advertencia", "Acción importante"]
    // Servicios cuya caida se nota enseguida.
    readonly property var essentialUnits: ["NetworkManager.service", "systemd-networkd.service", "systemd-resolved.service", "sddm.service",
        "display-manager.service", "systemd-logind.service", "dbus.service", "dbus-broker.service", "polkit.service", "bluetooth.service",
        "pipewire.service", "wireplumber.service", "pipewire-pulse.service", "power-profiles-daemon.service", "upower.service"]

    function gb(bytes: real): string {
        return I18n.bytes(bytes);
    }
    function plural(n: int, one: string, many: string): string {
        return n + " " + (n === 1 ? one : many);
    }
    function ago(epochSec: real): string {
        if (!epochSec) return "";
        const days = Math.floor((Date.now() / 1000 - epochSec) / 86400);
        if (days <= 0) return "hoy";
        if (days === 1) return "ayer";
        return "hace " + days + " días";
    }

    readonly property var items: {
        const out = [];
        const q = root.quick, u = root.updates, s = root.sizes;
        const GiB = 1073741824;
        // Umbrales: system.maintenance.* (settings store).
        const opt = k => SettingsState.value("system.maintenance." + k);

        if (q && q.reboot) {
            out.push({ id: "reboot", sev: 3, metrics: { count: 1 },
                sentence: "Hay que reiniciar para terminar la actualización.",
                why: q.reboot.reason === "kernel"
                    ? "El kernel en uso (" + q.reboot.running + ") ya no está instalado; hasta reiniciar pueden fallar dispositivos y módulos."
                    : "El driver NVIDIA cargado (" + q.reboot.running + ") no coincide con el instalado (" + q.reboot.installed + ").",
                advice: "reiniciar", action: "reboot", actionLabel: "Reiniciar…" });
        }

        const disk = SystemState.storage.length ? SystemState.storage[0] : null;
        const diskFrac = disk && disk.size > 0 ? disk.used / disk.size : 0;
        if (diskFrac > opt("diskWarnPct") / 100) {
            out.push({ id: "disk", sev: diskFrac > opt("diskCriticalPct") / 100 ? 3 : 2, metrics: { bytes: disk.avail },
                sentence: "El disco está al " + Math.round(diskFrac * 100) + " %.",
                why: "Quedan " + root.gb(disk.avail) + " libres; revisa la papelera y las cachés.",
                advice: "liberar espacio en disco", action: "", actionLabel: "" });
        }

        if (q) {
            const units = q.units.filter(x => root.ignoredUnits.indexOf(x.name) < 0);
            const tpm = x => /^systemd-(pcr|tpm2)/.test(x.name) && q.tpmUsed !== true;
            const essential = units.filter(x => root.essentialUnits.indexOf(x.name) >= 0);
            const harmless = units.filter(x => essential.indexOf(x) < 0 && tpm(x));
            const other = units.filter(x => essential.indexOf(x) < 0 && harmless.indexOf(x) < 0);
            if (essential.length)
                out.push({ id: "units-essential", sev: 3, metrics: { count: essential.length }, units: essential,
                    sentence: essential.length === 1 ? "Un servicio esencial no está funcionando: " + (essential[0].description || essential[0].name) + "."
                                                     : essential.length + " servicios esenciales no están funcionando.",
                    why: "Revisa su registro; suele arreglarse reiniciando el servicio o el equipo.",
                    advice: "revisar los servicios caídos", action: "unit-log", actionLabel: "Ver registro" });
            if (other.length)
                out.push({ id: "units", sev: 2, metrics: { count: other.length }, units: other,
                    sentence: other.length === 1 ? "Un servicio falló al iniciar: " + (other[0].description || other[0].name) + "."
                                                 : other.length + " servicios fallaron al iniciar.",
                    why: "No son esenciales, pero conviene saber por qué fallan.",
                    advice: "revisar los servicios que fallan", action: "unit-log", actionLabel: "Ver registro" });
            if (harmless.length)
                out.push({ id: "units-tpm", sev: 0, metrics: { count: harmless.length }, units: harmless,
                    sentence: root.plural(harmless.length, "servicio del TPM falla", "servicios del TPM fallan") + " al iniciar; hoy no afectan al uso diario.",
                    why: "Solo importarían si guardaras claves en el TPM (cifrado de disco, credenciales).",
                    advice: "", action: "unit-log", actionLabel: "Ver registro" });
        }

        if (s && s.trash.bytes > opt("trashRecommendGiB") * GiB)
            out.push({ id: "trash", sev: s.trash.bytes > opt("trashWarnGiB") * GiB ? 2 : 1, metrics: { bytes: s.trash.bytes, count: s.trash.items },
                sentence: "La papelera ocupa " + root.gb(s.trash.bytes) + ".",
                why: "Vaciarla libera ese espacio; no se puede deshacer.",
                advice: "vaciar la papelera", action: "trash", actionLabel: "Vaciar…" });

        if (q && q.coredumps.bytes > opt("coredumpRecommendMiB") * 1048576) {
            const src = q.coredumps.sources.filter(x => x.stored > 0);
            const stored = src.reduce((a, x) => a + x.stored, 0);
            const top = src.slice(0, 2).map(x => x.exe === "xdg-desktop-portal-hyprland" ? "el portal de escritorio falló " + x.count + " veces"
                                                                                           : x.exe + " (" + x.stored + ")");
            out.push({ id: "coredumps", sev: q.coredumps.bytes > opt("coredumpWarnGiB") * GiB ? 2 : 1, metrics: { bytes: q.coredumps.bytes, count: stored }, sources: src,
                sentence: "Se detectaron " + root.plural(stored, "volcado de error", "volcados de error") + " que ocupan " + root.gb(q.coredumps.bytes) + ".",
                why: top.length ? "Casi todos son de " + top.join("; ") + "." : "",
                advice: "limpiar los volcados de error", action: "coredumps", actionLabel: "Limpiar…" });
        }

        if (u && root.updateCount > 0) {
            const stale = q && q.lastUpgrade && (Date.now() / 1000 - q.lastUpgrade) > opt("staleUpgradeDays") * 86400;
            const parts = [];
            if (u.repo.length) parts.push(u.aur.length ? u.repo.length + " del repositorio" : "Todas del repositorio");
            if (u.aur.length) parts.push(u.repo.length ? u.aur.length + " de AUR" : "Todas de AUR");
            out.push({ id: "updates", sev: stale ? 2 : 1, metrics: { count: root.updateCount }, packages: u.repo.concat(u.aur),
                sentence: root.updateCount === 1 ? "Hay 1 actualización disponible." : "Hay " + root.updateCount + " actualizaciones disponibles.",
                why: parts.join(" y ") + (q && q.lastUpgrade ? "; la última actualización completa fue " + root.ago(q.lastUpgrade) + "." : "."),
                advice: "actualizar el sistema (" + root.plural(root.updateCount, "paquete", "paquetes") + ")", action: "update", actionLabel: "Actualizar" });
        }
        if (u && u.error)
            out.push({ id: "updates-error", sev: 0, metrics: {},
                sentence: "No se pudo comprobar si hay actualizaciones" + (u.error === "aur" ? " de AUR." : "."),
                why: "Puede ser la conexión; se vuelve a intentar en la próxima revisión.", advice: "", action: "", actionLabel: "" });

        if (s) {
            const cache = s.pkgCache.reclaimBytes + s.helperCacheBytes;
            if (cache > opt("packageCacheGiB") * GiB)
                out.push({ id: "pkgcache", sev: 1, metrics: { bytes: cache },
                    sentence: "Se pueden liberar " + root.gb(cache) + " en cachés de paquetes.",
                    why: root.gb(s.pkgCache.reclaimBytes) + " de pacman" + (s.helper ? " y " + root.gb(s.helperCacheBytes) + " de " + s.helper : "") + "; quedan las dos últimas versiones.",
                    advice: "liberar " + root.gb(cache) + " de cachés", action: "pkgcache", actionLabel: "Limpiar…" });
        }
        if (q && q.orphans.length)
            out.push({ id: "orphans", sev: 1, metrics: { count: q.orphans.length }, packages: q.orphans.map(n => ({ name: n })),
                sentence: "Hay " + root.plural(q.orphans.length, "paquete que ya nada usa", "paquetes que ya nada usa") + ".",
                why: "Revisa la lista antes: algunas herramientas de compilación aparecen aunque las uses a mano.",
                advice: "quitar " + root.plural(q.orphans.length, "paquete sin uso", "paquetes sin uso"), action: "orphans", actionLabel: "Revisar…" });
        if (q && q.journalBytes > opt("journalGiB") * GiB)
            out.push({ id: "journal", sev: 1, metrics: { bytes: q.journalBytes },
                sentence: "El diario del sistema ocupa " + root.gb(q.journalBytes) + ".",
                why: "Se puede reducir a 200 MB; se borran los registros más viejos.",
                advice: "reducir el diario", action: "journal", actionLabel: "Reducir…" });
        if (q && q.pacnew.length)
            out.push({ id: "pacnew", sev: 1, metrics: { count: q.pacnew.length }, files: q.pacnew,
                sentence: "Hay " + root.plural(q.pacnew.length, "archivo de configuración nuevo", "archivos de configuración nuevos") + " por revisar.",
                why: "pacman dejó versiones .pacnew/.pacsave junto a las tuyas; hay que compararlas a mano (pacdiff).",
                advice: "revisar los .pacnew", action: "", actionLabel: "" });
        if (s) {
            const cap = s.captures.screenshots.bytes + s.captures.recordings.bytes;
            if (cap > opt("capturesGiB") * GiB)
                out.push({ id: "captures", sev: 1, metrics: { bytes: cap },
                    sentence: "Tus capturas ocupan " + root.gb(cap) + ".",
                    why: s.captures.screenshots.count + " imágenes y " + s.captures.recordings.count + " grabaciones; revisa las antiguas.",
                    advice: "revisar capturas antiguas", action: "captures", actionLabel: "Abrir carpeta" });
        }
        // Mas grave primero; a igual severidad, un orden fijo (lo que mas pesa
        // en el dia a dia antes): el sort de JS no garantiza el orden de entrada.
        return out.sort((a, b) => b.sev - a.sev || root.order.indexOf(a.id) - root.order.indexOf(b.id));
    }
    readonly property var order: ["reboot", "disk", "units-essential", "units", "updates", "trash", "coredumps", "pkgcache", "orphans",
        "journal", "pacnew", "captures", "units-tpm", "updates-error"]

    readonly property var attention: root.items.filter(x => x.sev >= 2)
    readonly property var recommended: root.items.filter(x => x.sev === 1)
    readonly property var info: root.items.filter(x => x.sev === 0)
    readonly property int worst: root.items.reduce((m, x) => Math.max(m, x.sev), -1)

    // ¿Esta bien el sistema? ¿Que requiere atencion?
    readonly property string verdict: {
        if (!root.quick) return "Revisando el sistema…";
        const urgent = root.items.filter(x => x.sev === 3).length;
        if (urgent) return urgent === 1 ? "Hay 1 elemento que requiere atención inmediata." : "Hay " + urgent + " elementos que requieren atención inmediata.";
        const n = root.attention.length;
        if (n) return "El sistema funciona correctamente, pero " + (n === 1 ? "hay 1 elemento que requiere atención." : "hay " + n + " elementos que requieren atención.");
        return "El sistema funciona correctamente.";
    }
    // Resumen corto (fila de Sistema): lo mas grave que hay.
    readonly property string shortStatus: {
        if (!root.quick) return "revisando…";
        const urgent = root.items.filter(x => x.sev === 3).length;
        if (urgent) return urgent === 1 ? "1 elemento requiere atención inmediata" : urgent + " elementos requieren atención inmediata";
        const n = root.attention.length;
        if (n) return n === 1 ? "1 elemento requiere atención" : n + " elementos requieren atención";
        const r = root.recommended.length;
        if (r) return r === 1 ? "1 recomendación" : r + " recomendaciones";
        return "todo al día";
    }
    // ¿Que es recomendable hacer?
    readonly property string recommendation: {
        if (!root.quick) return "";
        const adv = root.items.filter(x => x.sev >= 1 && x.advice).slice(0, 3).map(x => x.advice);
        if (!adv.length) return "No hace falta hacer nada.";
        const text = adv.length === 1 ? adv[0] : adv.slice(0, -1).join(", ") + " y " + adv[adv.length - 1];
        return "Lo recomendable: " + text + ".";
    }
    // Lo que esta bien, en una sola linea.
    readonly property string okLine: {
        if (!root.quick) return "";
        const ids = root.items.map(x => x.id);
        const parts = [];
        const disk = SystemState.storage.length ? SystemState.storage[0] : null;
        if (disk && ids.indexOf("disk") < 0) parts.push("Disco al " + Math.round(disk.used / disk.size * 100) + " % (" + root.gb(disk.avail) + " libres)");
        if (!root.rebootPending) parts.push("sin reinicio pendiente");
        if (ids.indexOf("units-essential") < 0 && ids.indexOf("units") < 0) parts.push(ids.indexOf("units-tpm") >= 0 ? "servicios esenciales en orden" : "servicios en orden");
        if (root.updates && root.updateCount === 0 && !root.updates.error) parts.push("sistema actualizado");
        if (ids.indexOf("pacnew") < 0) parts.push("configuración al día");
        if (!parts.length) return "";
        const line = parts.join(" · ");
        return line.charAt(0).toUpperCase() + line.slice(1);
    }
}
