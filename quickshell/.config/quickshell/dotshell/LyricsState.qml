// Letras de la cancion que suena (Fase 12 B1, P12.1): el unico dueno. Trabaja
// solo mientras la vista de letras se ve (Demand lyrics); oculta, en pausa o
// cerrada, nada.
//
// Donde busca, en orden (D-B1-1):
//   1 el .lrc junto al archivo, si el reproductor da xesam:url file://
//   2 la carpeta media.lyrics.dir: "Artista - Titulo.lrc" y, si no, una
//     busqueda por nombre en sus subcarpetas
//   3 la cache de lyrics-fetch (~/.cache/dotfiles/lyrics), incluida la marca
//     de "no hay" de 7 dias
//   4 LRCLIB por lyrics-fetch, solo con media.lyrics.enabled
// Lo elegido a mano ("no es esta cancion") y el desfase se recuerdan por
// cancion en ~/.local/state/dotfiles/lyrics.json (StateFile).
//
// Sincronia (D-B1-2): sin sondeo. Con la vista a la vista y sonando, lee la
// posicion y arma UN temporizador hasta la linea siguiente; se rearma en cada
// linea, al buscar, pausar o cambiar de cancion. Si la posicion salta (busqueda
// desde otro lado), el refresco de progreso del reproductor lo delata.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property bool online: SettingsState.value("media.lyrics.enabled") === true
    readonly property string dir: SettingsState.value("media.lyrics.dir") || ""
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/lyrics-fetch"
    readonly property string cacheDir: Quickshell.env("LYRICS_CACHE") || (Quickshell.env("HOME") + "/.cache/dotfiles/lyrics")

    // La letra abierta en el reproductor (tecla L o "Letra"); dura mientras corre la shell.
    property bool viewOpen: false
    property Demand demand: Demand {
        name: "lyrics"
        onActiveChanged: root.demandMoved()
    }

    // ---- La cancion --------------------------------------------------------------------
    // El reproductor (MediaState.active; las pruebas lo reemplazan por uno falso).
    property var player: MediaState.active
    readonly property string title: root.player ? (root.player.trackTitle || "") : ""
    readonly property string artist: root.player ? (root.player.trackArtist || "") : ""
    readonly property real length: root.player && root.player.lengthSupported ? Math.round(root.player.length) : 0
    readonly property string fileUrl: {
        const m = root.player ? root.player.metadata : null;
        const u = m ? (m["xesam:url"] || "") : "";
        return String(u).startsWith("file://") ? decodeURIComponent(String(u).slice(7)) : "";
    }
    // Para buscar: sin "(feat. ...)", "- Remastered 2011", "(Live)", "[Official Video]".
    function clean(t: string): string {
        return t.replace(/\s*[\(\[](feat\.?|ft\.?|with|live|remaster(ed)?|official|video|audio|lyrics?|en vivo)[^\)\]]*[\)\]]/gi, "")
            .replace(/\s+-\s+(\d{4}\s+)?remaster(ed)?(\s+\d{4})?.*$/i, "")
            .replace(/\s+-\s+(live|en vivo|radio edit|single version).*$/i, "")
            .trim();
    }
    readonly property string qTitle: root.clean(root.title)
    readonly property string qArtist: root.artist.split(/\s*[,&;]\s*|\s+feat\.?\s+/i)[0].trim()
    // La misma clave que lyrics-fetch --key (artista\ttitulo\tduracion).
    readonly property string key: root.qTitle ? Qt.md5(root.qArtist + "\t" + root.qTitle + "\t" + root.length) : ""

    // ---- Lo encontrado -------------------------------------------------------------------
    // lines: [{ t (s), text }] ordenadas; plain: texto sin tiempos.
    property var lines: []
    property string plain: ""
    property bool instrumental: false
    // "file" | "folder" | "cache" | "lrclib" | ""
    property string source: ""
    // "idle" | "searching" | "found" | "none" | "offline" | "off"
    property string status: "idle"
    property string loadedKey: ""
    readonly property bool synced: root.lines.length > 0

    // ---- Recuerdos por cancion -------------------------------------------------------------
    property StateFile prefs: StateFile {
        name: "lyrics.json"
        enabled: root.demand.holding
    }
    readonly property var pref: root.prefs.data && root.prefs.data.tracks ? (root.prefs.data.tracks[root.key] || null) : null
    readonly property real offset: root.pref && root.pref.offset ? root.pref.offset : 0
    function remember(patch: var): void {
        if (!root.prefs.loaded || !root.key) return;
        const tracks = Object.assign({}, (root.prefs.data && root.prefs.data.tracks) || {});
        tracks[root.key] = Object.assign({}, tracks[root.key] || {}, patch);
        root.prefs.save({ version: 1, tracks: tracks });
    }
    function nudge(seconds: real): void {
        root.remember({ offset: Math.round((root.offset + seconds) * 10) / 10 });
        root.resync();
    }

    // ---- Busqueda ------------------------------------------------------------------------
    function demandMoved(): void {
        if (root.demand.active) {
            if (root.loadedKey !== root.key) root.load();
            root.resync();
        } else {
            lineTimer.stop();
        }
    }
    onKeyChanged: if (root.demand.active) root.load()
    // Al cargar los recuerdos (la eleccion a mano manda sobre la busqueda).
    property Connections prefsLoaded: Connections {
        target: root.prefs
        function onLoadedChanged() { if (root.prefs.loaded && root.demand.active && root.pref && root.pref.id) root.load(); }
    }
    function reset(): void {
        lineTimer.stop();
        root.lines = [];
        root.plain = "";
        root.instrumental = false;
        root.source = "";
        root.current = -1;
    }
    // Cada busqueda lleva su numero: lo que llega de una anterior (otra cancion) se ignora.
    property int req: 0
    function load(): void {
        root.reset();
        root.req++;
        root.loadedKey = root.key;
        if (!root.key) {
            root.status = "idle";
            return;
        }
        root.status = "searching";
        root.step = 0;
        root.next();
    }
    // Paso de la cadena: 0 archivo, 1 carpeta, 2 carpeta (subcarpetas), 3 cache, 4 red.
    property int step: 0
    function next(): void {
        const k = root.loadedKey;
        // Lo elegido a mano para esta cancion.
        if (root.step === 0 && root.pref && root.pref.id) {
            root.step = 5;
            idCache.req = root.req;
            idCache.path = root.cacheDir + "/id-" + root.pref.id + ".json";
            return;
        }
        if (root.step === 0) {
            root.step = 1;
            if (root.fileUrl) { lrcFile.req = root.req; lrcFile.source = "file"; lrcFile.path = root.fileUrl.replace(/\.[^.\/]+$/, "") + ".lrc"; return; }
        }
        if (root.step === 1) {
            root.step = 2;
            if (root.dir) { lrcFile.req = root.req; lrcFile.source = "folder"; lrcFile.path = root.dir.replace(/\/$/, "") + "/" + root.qArtist + " - " + root.qTitle + ".lrc"; return; }
        }
        if (root.step === 2) {
            root.step = 3;
            if (root.dir) { finder.req = root.req; finder.running = true; return; }
        }
        if (root.step === 3) {
            root.step = 4;
            cacheFile.req = root.req;
            cacheFile.path = root.cacheDir + "/" + k + ".json";
            return;
        }
        if (root.step === 4) {
            root.step = 6;
            if (!root.online) { root.status = "off"; return; }
            fetcher.req = root.req;
            fetcher.command = [root.script, "--get", root.qTitle, root.qArtist, String(root.length)];
            fetcher.running = true;
        }
    }
    // Un .lrc (junto al archivo o en la carpeta).
    property FileView lrcFile: FileView {
        property string source: ""
        property int req: 0
        printErrors: false
        onLoaded: {
            if (lrcFile.req !== root.req) { lrcFile.path = ""; return; }
            if (!root.useLrc(this.text(), lrcFile.source)) root.next();
            lrcFile.path = "";
        }
        onLoadFailed: {
            lrcFile.path = "";
            if (lrcFile.req === root.req) root.next();
        }
    }
    // Subcarpetas: el primer .lrc cuyo nombre tenga el titulo (y el artista, si hay varios).
    property Process finder: Process {
        property int req: 0
        command: ["find", root.dir, "-maxdepth", "4", "-type", "f", "-iname", "*" + root.qTitle.replace(/[\[\]*?]/g, "") + "*.lrc"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (finder.req !== root.req) return;
                const found = this.text.split("\n").filter(x => x);
                const a = root.qArtist.toLowerCase();
                const pick = found.find(f => f.toLowerCase().indexOf(a) >= 0) || found[0];
                if (pick) {
                    lrcFile.req = root.req;
                    lrcFile.source = "folder";
                    lrcFile.path = pick;
                } else root.next();
            }
        }
    }
    property FileView cacheFile: FileView {
        property int req: 0
        printErrors: false
        onLoaded: {
            if (cacheFile.req !== root.req) { cacheFile.path = ""; return; }
            let d = null;
            try { d = JSON.parse(this.text()); } catch (e) {}
            cacheFile.path = "";
            if (d && d.none) {
                // "No hay" anotado: vale hasta su fecha; despues se pregunta de nuevo.
                if (d.until * 1000 > Date.now()) { root.status = "none"; return; }
                root.next();
                return;
            }
            if (d && root.useResult(d, "cache")) return;
            root.next();
        }
        onLoadFailed: {
            cacheFile.path = "";
            if (cacheFile.req === root.req) root.next();
        }
    }
    property FileView idCache: FileView {
        property int req: 0
        printErrors: false
        onLoaded: {
            if (idCache.req !== root.req) { idCache.path = ""; return; }
            let d = null;
            try { d = JSON.parse(this.text()); } catch (e) {}
            idCache.path = "";
            if (!(d && root.useResult(d, "lrclib"))) { root.step = 0; root.next(); }
        }
        onLoadFailed: {
            idCache.path = "";
            if (idCache.req !== root.req) return;
            if (root.online && root.pref) {
                fetcher.req = root.req;
                fetcher.command = [root.script, "--id", String(root.pref.id)];
                fetcher.running = true;
            } else {
                root.step = 1;
                root.next();
            }
        }
    }
    property Process fetcher: Process {
        property int req: 0
        stdout: StdioCollector { id: fetchOut }
        onExited: (code) => {
            // Una respuesta de una cancion que ya no suena no pisa nada.
            if (fetcher.req !== root.req) return;
            if (code === 0) {
                let d = null;
                try { d = JSON.parse(fetchOut.text); } catch (e) {}
                if (d && root.useResult(d, "lrclib")) return;
            }
            root.status = code === 1 ? "none" : code === 2 ? "off" : "offline";
        }
    }
    function useLrc(text: string, source: string): bool {
        const parsed = root.parseLrc(text);
        if (!parsed.length && !text.trim()) return false;
        root.lines = parsed;
        root.plain = parsed.length ? "" : text.trim();
        root.source = source;
        root.status = "found";
        root.resync();
        return true;
    }
    function useResult(d: var, source: string): bool {
        if (d.instrumental) {
            root.instrumental = true;
            root.source = source;
            root.status = "found";
            return true;
        }
        if (d.synced) return root.useLrc(d.synced, source);
        if (d.plain) {
            root.plain = d.plain;
            root.source = source;
            root.status = "found";
            return true;
        }
        return false;
    }

    // ---- LRC -----------------------------------------------------------------------------
    // [mm:ss.xx] (varias marcas por linea), [offset:+/-ms], etiquetas de metadatos ignoradas.
    function parseLrc(text: string): var {
        const out = [];
        let shift = 0;
        for (const raw of text.replace(/\r/g, "").split("\n")) {
            const off = raw.match(/^\[offset:\s*([+-]?\d+)\s*\]/i);
            if (off) { shift = Number(off[1]) / 1000; continue; }
            const stamps = [];
            let rest = raw;
            let m;
            while ((m = rest.match(/^\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]/))) {
                const frac = m[3] ? Number(m[3]) / Math.pow(10, m[3].length) : 0;
                stamps.push(Number(m[1]) * 60 + Number(m[2]) + frac);
                rest = rest.slice(m[0].length);
            }
            if (!stamps.length) continue;
            for (const t of stamps) out.push({ t: Math.max(0, t - shift), text: rest.trim() });
        }
        out.sort((a, b) => a.t - b.t);
        return out;
    }

    // ---- Sincronia -----------------------------------------------------------------------
    property int current: -1
    readonly property bool running: root.demand.active && root.synced && !!root.player && root.player.isPlaying
    onRunningChanged: root.resync()
    function indexAt(pos: real): int {
        const l = root.lines;
        let lo = 0, hi = l.length - 1, ans = -1;
        while (lo <= hi) {
            const mid = (lo + hi) >> 1;
            if (l[mid].t <= pos) { ans = mid; lo = mid + 1; } else hi = mid - 1;
        }
        return ans;
    }
    // La posicion con el desfase de esta cancion (positivo = la letra va antes).
    function position(): real {
        return root.player ? root.player.position + root.offset : 0;
    }
    function resync(): void {
        lineTimer.stop();
        if (!root.synced || !root.player) return;
        const pos = root.position();
        root.current = root.indexAt(pos);
        if (!root.running) return;
        const nxt = root.lines[root.current + 1];
        if (!nxt) return;
        const rate = root.player.rate > 0 ? root.player.rate : 1;
        lineTimer.interval = Math.max(20, (nxt.t - pos) / rate * 1000);
        lineTimer.start();
    }
    property Timer lineTimer: Timer {
        repeat: false
        onTriggered: root.resync()
    }
    // El reproductor refresca su posicion mientras se ve (MediaHero): un salto
    // de mas de un segundo respecto de lo esperado es una busqueda.
    property Connections seeks: Connections {
        target: root.running ? root.player : null
        function onPositionChanged() {
            const pos = root.position();
            const i = root.indexAt(pos);
            if (i !== root.current) root.resync();
        }
    }
    function seekTo(index: int): void {
        const l = root.lines[index];
        if (!l) return;
        MediaState.seek(Math.max(0, l.t - root.offset + 0.05));
        Qt.callLater(root.resync);
    }

    // ---- "No es esta cancion" ------------------------------------------------------------
    property var candidates: []
    property bool searching: false
    function search(): void {
        if (!root.online || !root.key) return;
        root.candidates = [];
        root.searching = true;
        searcher.command = [root.script, "--search", root.qTitle, root.qArtist];
        searcher.running = true;
    }
    property Process searcher: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                let d = [];
                try { d = JSON.parse(this.text); } catch (e) {}
                root.candidates = Array.isArray(d) ? d : [];
                root.searching = false;
            }
        }
        onExited: (code) => { if (code !== 0) root.searching = false; }
    }
    function choose(id: string): void {
        root.remember({ id: id });
        root.candidates = [];
        Qt.callLater(root.load);
    }
}
