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
    readonly property var sevNames: [I18n.tr("Information"), I18n.tr("Recommendation"), I18n.tr("Warning"), I18n.tr("Important action")]
    // Servicios cuya caida se nota enseguida.
    readonly property var essentialUnits: ["NetworkManager.service", "systemd-networkd.service", "systemd-resolved.service", "sddm.service",
        "display-manager.service", "systemd-logind.service", "dbus.service", "dbus-broker.service", "polkit.service", "bluetooth.service",
        "pipewire.service", "wireplumber.service", "pipewire-pulse.service", "power-profiles-daemon.service", "upower.service"]

    function gb(bytes: real): string {
        return I18n.bytes(bytes);
    }

    readonly property var items: {
        const out = [];
        const q = root.quick, u = root.updates, s = root.sizes;
        const GiB = 1073741824;
        // Umbrales: system.maintenance.* (settings store).
        const opt = k => SettingsState.value("system.maintenance." + k);

        if (q && q.reboot) {
            out.push({ id: "reboot", sev: 3, metrics: { count: 1 },
                sentence: I18n.tr("A restart is needed to finish the update."),
                why: q.reboot.reason === "kernel"
                    ? I18n.tr("The running kernel (%1) is no longer installed; devices and modules may fail until you restart.", q.reboot.running)
                    : I18n.tr("The loaded NVIDIA driver (%1) doesn't match the installed one (%2).", q.reboot.running, q.reboot.installed),
                advice: I18n.tr("restart"), action: "reboot", actionLabel: I18n.tr("Restart…") });
        }

        const disk = SystemState.storage.length ? SystemState.storage[0] : null;
        const diskFrac = disk && disk.size > 0 ? disk.used / disk.size : 0;
        if (diskFrac > opt("diskWarnPct") / 100) {
            out.push({ id: "disk", sev: diskFrac > opt("diskCriticalPct") / 100 ? 3 : 2, metrics: { bytes: disk.avail },
                sentence: I18n.tr("The disk is %1 % full.", Math.round(diskFrac * 100)),
                why: I18n.tr("%1 free; check the trash and the caches.", root.gb(disk.avail)),
                advice: I18n.tr("free up disk space"), action: "", actionLabel: "" });
        }

        if (q) {
            const units = q.units.filter(x => root.ignoredUnits.indexOf(x.name) < 0);
            const tpm = x => /^systemd-(pcr|tpm2)/.test(x.name) && q.tpmUsed !== true;
            const essential = units.filter(x => root.essentialUnits.indexOf(x.name) >= 0);
            const harmless = units.filter(x => essential.indexOf(x) < 0 && tpm(x));
            const other = units.filter(x => essential.indexOf(x) < 0 && harmless.indexOf(x) < 0);
            if (essential.length)
                out.push({ id: "units-essential", sev: 3, metrics: { count: essential.length }, units: essential,
                    sentence: essential.length === 1 ? I18n.tr("An essential service isn't running: %1.", essential[0].description || essential[0].name)
                                                     : I18n.trn("%n essential service isn't running.", "%n essential services aren't running.", essential.length),
                    why: I18n.tr("Check its log; restarting the service or the computer usually fixes it."),
                    advice: I18n.tr("check the services that are down"), action: "unit-log", actionLabel: I18n.tr("View log") });
            if (other.length)
                out.push({ id: "units", sev: 2, metrics: { count: other.length }, units: other,
                    sentence: other.length === 1 ? I18n.tr("A service failed to start: %1.", other[0].description || other[0].name)
                                                 : I18n.trn("%n service failed to start.", "%n services failed to start.", other.length),
                    why: I18n.tr("They aren't essential, but it's worth knowing why they fail."),
                    advice: I18n.tr("check the failing services"), action: "unit-log", actionLabel: I18n.tr("View log") });
            if (harmless.length)
                out.push({ id: "units-tpm", sev: 0, metrics: { count: harmless.length }, units: harmless,
                    sentence: I18n.trn("%n TPM service fails at startup; it doesn't affect daily use today.", "%n TPM services fail at startup; they don't affect daily use today.", harmless.length),
                    why: I18n.tr("They would only matter if you stored keys in the TPM (disk encryption, credentials)."),
                    advice: "", action: "unit-log", actionLabel: I18n.tr("View log") });
        }

        if (s && s.trash.bytes > opt("trashRecommendGiB") * GiB)
            out.push({ id: "trash", sev: s.trash.bytes > opt("trashWarnGiB") * GiB ? 2 : 1, metrics: { bytes: s.trash.bytes, count: s.trash.items },
                sentence: I18n.tr("The trash takes up %1.", root.gb(s.trash.bytes)),
                why: I18n.tr("Emptying it frees that space; it can't be undone."),
                advice: I18n.tr("empty the trash"), action: "trash", actionLabel: I18n.tr("Empty…") });

        if (q && q.coredumps.bytes > opt("coredumpRecommendMiB") * 1048576) {
            const src = q.coredumps.sources.filter(x => x.stored > 0);
            const stored = src.reduce((a, x) => a + x.stored, 0);
            const top = src.slice(0, 2).map(x => x.exe === "xdg-desktop-portal-hyprland" ? I18n.trn("the desktop portal failed %n time", "the desktop portal failed %n times", x.count)
                                                                                           : x.exe + " (" + x.stored + ")");
            out.push({ id: "coredumps", sev: q.coredumps.bytes > opt("coredumpWarnGiB") * GiB ? 2 : 1, metrics: { bytes: q.coredumps.bytes, count: stored }, sources: src,
                sentence: I18n.trn("%n crash dump was found, taking up %1.", "%n crash dumps were found, taking up %1.", stored, root.gb(q.coredumps.bytes)),
                why: top.length ? I18n.tr("Almost all come from %1.", top.join("; ")) : "",
                advice: I18n.tr("clean up the crash dumps"), action: "coredumps", actionLabel: I18n.tr("Clean up…") });
        }

        if (u && root.updateCount > 0) {
            const stale = q && q.lastUpgrade && (Date.now() / 1000 - q.lastUpgrade) > opt("staleUpgradeDays") * 86400;
            const parts = [];
            if (u.repo.length) parts.push(u.aur.length ? I18n.tr("%1 from the repositories", u.repo.length) : I18n.tr("All from the repositories"));
            if (u.aur.length) parts.push(u.repo.length ? I18n.tr("%1 from the AUR", u.aur.length) : I18n.tr("All from the AUR"));
            out.push({ id: "updates", sev: stale ? 2 : 1, metrics: { count: root.updateCount }, packages: u.repo.concat(u.aur),
                sentence: I18n.trn("%n update is available.", "%n updates are available.", root.updateCount),
                why: q && q.lastUpgrade ? I18n.tr("%1; the last full upgrade was %2.", I18n.join(parts), I18n.daysAgo(q.lastUpgrade)) : I18n.tr("%1.", I18n.join(parts)),
                advice: I18n.trn("update the system (%n package)", "update the system (%n packages)", root.updateCount), action: "update", actionLabel: I18n.tr("Update") });
        }
        if (u && u.error)
            out.push({ id: "updates-error", sev: 0, metrics: {},
                sentence: u.error === "aur" ? I18n.tr("Couldn't check for AUR updates.") : I18n.tr("Couldn't check for updates."),
                why: I18n.tr("It may be the connection; it will try again at the next check."), advice: "", action: "", actionLabel: "" });

        if (s) {
            const cache = s.pkgCache.reclaimBytes + s.helperCacheBytes;
            if (cache > opt("packageCacheGiB") * GiB)
                out.push({ id: "pkgcache", sev: 1, metrics: { bytes: cache },
                    sentence: I18n.tr("%1 can be freed from package caches.", root.gb(cache)),
                    why: s.helper ? I18n.tr("%1 from pacman and %2 from %3; the last two versions are kept.", root.gb(s.pkgCache.reclaimBytes), root.gb(s.helperCacheBytes), s.helper)
                                  : I18n.tr("%1 from pacman; the last two versions are kept.", root.gb(s.pkgCache.reclaimBytes)),
                    advice: I18n.tr("free %1 of caches", root.gb(cache)), action: "pkgcache", actionLabel: I18n.tr("Clean up…") });
        }
        if (q && q.orphans.length)
            out.push({ id: "orphans", sev: 1, metrics: { count: q.orphans.length }, packages: q.orphans.map(n => ({ name: n })),
                sentence: I18n.trn("%n package is no longer needed by anything.", "%n packages are no longer needed by anything.", q.orphans.length),
                why: I18n.tr("Check the list first: some build tools show up even if you use them by hand."),
                advice: I18n.trn("remove %n unused package", "remove %n unused packages", q.orphans.length), action: "orphans", actionLabel: I18n.tr("Review…") });
        if (q && q.journalBytes > opt("journalGiB") * GiB)
            out.push({ id: "journal", sev: 1, metrics: { bytes: q.journalBytes },
                sentence: I18n.tr("The system journal takes up %1.", root.gb(q.journalBytes)),
                why: I18n.tr("It can be reduced to 200 MB; the oldest logs are deleted."),
                advice: I18n.tr("shrink the journal"), action: "journal", actionLabel: I18n.tr("Shrink…") });
        if (q && q.pacnew.length)
            out.push({ id: "pacnew", sev: 1, metrics: { count: q.pacnew.length }, files: q.pacnew,
                sentence: I18n.trn("%n new configuration file to review.", "%n new configuration files to review.", q.pacnew.length),
                why: I18n.tr("pacman left .pacnew/.pacsave versions next to yours; they have to be compared by hand (pacdiff)."),
                advice: I18n.tr("review the .pacnew files"), action: "", actionLabel: "" });
        if (s) {
            const cap = s.captures.screenshots.bytes + s.captures.recordings.bytes;
            if (cap > opt("capturesGiB") * GiB)
                out.push({ id: "captures", sev: 1, metrics: { bytes: cap },
                    sentence: I18n.tr("Your captures take up %1.", root.gb(cap)),
                    why: I18n.tr("%1 images and %2 recordings; check the old ones.", s.captures.screenshots.count, s.captures.recordings.count),
                    advice: I18n.tr("review old captures"), action: "captures", actionLabel: I18n.tr("Open folder") });
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
        if (!root.quick) return I18n.tr("Checking the system…");
        const urgent = root.items.filter(x => x.sev === 3).length;
        if (urgent) return I18n.trn("%n item needs immediate attention.", "%n items need immediate attention.", urgent);
        const n = root.attention.length;
        if (n) return I18n.trn("The system works correctly, but %n item needs attention.", "The system works correctly, but %n items need attention.", n);
        return I18n.tr("The system works correctly.");
    }
    // Resumen corto (fila de Sistema): lo mas grave que hay.
    readonly property string shortStatus: {
        if (!root.quick) return I18n.tr("checking…");
        const urgent = root.items.filter(x => x.sev === 3).length;
        if (urgent) return I18n.trn("%n item needs immediate attention", "%n items need immediate attention", urgent);
        const n = root.attention.length;
        if (n) return I18n.trn("%n item needs attention", "%n items need attention", n);
        const r = root.recommended.length;
        if (r) return I18n.trn("%n recommendation", "%n recommendations", r);
        return I18n.tr("all up to date");
    }
    // ¿Que es recomendable hacer?
    readonly property string recommendation: {
        if (!root.quick) return "";
        const adv = root.items.filter(x => x.sev >= 1 && x.advice).slice(0, 3).map(x => x.advice);
        if (!adv.length) return I18n.tr("Nothing needs to be done.");
        return I18n.tr("Recommended: %1.", I18n.join(adv));
    }
    // Lo que esta bien, en una sola linea.
    readonly property string okLine: {
        if (!root.quick) return "";
        const ids = root.items.map(x => x.id);
        const parts = [];
        const disk = SystemState.storage.length ? SystemState.storage[0] : null;
        if (disk && ids.indexOf("disk") < 0) parts.push(I18n.tr("disk at %1 % (%2 free)", Math.round(disk.used / disk.size * 100), root.gb(disk.avail)));
        if (!root.rebootPending) parts.push(I18n.tr("no restart pending"));
        if (ids.indexOf("units-essential") < 0 && ids.indexOf("units") < 0) parts.push(ids.indexOf("units-tpm") >= 0 ? I18n.tr("essential services fine") : I18n.tr("services fine"));
        if (root.updates && root.updateCount === 0 && !root.updates.error) parts.push(I18n.tr("system up to date"));
        if (ids.indexOf("pacnew") < 0) parts.push(I18n.tr("configuration up to date"));
        if (!parts.length) return "";
        const line = parts.join(" · ");
        return line.charAt(0).toUpperCase() + line.slice(1);
    }
}
