// Capturas y grabaciones (Fase 4 B8): la ultima captura que se muestra en la
// vista previa, el estado de la grabacion y todas las acciones sobre un
// archivo. Los scripts (screenshot, record) hacen el trabajo y avisan por IPC
// (target "capture" en shell.qml); la shell no captura nada.
//
// Las carpetas son la fuente de verdad y cada accion recibe una ruta, asi un
// historial futuro (en el dashboard) reutiliza esto y CaptureThumb.qml sin
// rehacer nada. CAPTURE_DRY=1 (solo pruebas) registra los comandos en vez de
// ejecutarlos.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: root.home + "/.config/hypr/scripts"
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || root.home + "/.cache") + "/dotfiles/captures"
    readonly property string stateFile: (Quickshell.env("CAPTURE_STATE") || Quickshell.env("XDG_RUNTIME_DIR") + "/dotfiles/recording.json")

    // ---- Vista previa ----------------------------------------------------------
    // current: { path, kind ("region" | "window" | "full" | "recording"), video,
    //   x, y, w, h (zona capturada, coordenadas globales logicas), bytes, time
    //   (ms), duration (ms, videos), thumb (imagen a mostrar) }
    property var current: null
    // Sube con cada captura: la tarjeta reinicia su entrada aunque sea la misma ruta.
    property int serial: 0
    property string screen: ""
    property bool shown: false
    // Estado de la tarjeta tras una accion: "" | "trashed".
    property string status: ""

    function show(path: string, kind: string, region: string, bytes: string, extra: string): void {
        const video = kind === "recording";
        const m = /^(-?\d+),(-?\d+) (\d+)x(\d+)$/.exec(region || "");
        const c = {
            path: path,
            kind: kind,
            video: video,
            x: m ? parseInt(m[1]) : 0,
            y: m ? parseInt(m[2]) : 0,
            w: m ? parseInt(m[3]) : 0,
            h: m ? parseInt(m[4]) : 0,
            hasRegion: !!m,
            bytes: parseInt(bytes) || 0,
            time: Date.now(),
            duration: video ? (parseInt(extra) || 0) : 0,
            thumb: video ? root.thumbFor(path) : path
        };
        // En la pantalla que contiene la zona; si no se sabe, en la enfocada.
        const apply = name => {
            root.status = "";
            root.screen = name;
            root.current = c;
            root.shown = true;
            root.serial++;
        };
        const s = c.hasRegion ? root.screenAt(c.x + c.w / 2, c.y + c.h / 2) : "";
        if (s) apply(s);
        else FocusedScreen.request(apply);
    }
    function dismiss(): void {
        root.shown = false;
    }

    function screenAt(x: real, y: real): string {
        for (const s of Quickshell.screens)
            if (x >= s.x && x < s.x + s.width && y >= s.y && y < s.y + s.height) return s.name;
        return "";
    }
    function thumbFor(path: string): string {
        const base = path.substring(path.lastIndexOf("/") + 1).replace(/\.[^.]*$/, "");
        return root.thumbDir + "/" + base + ".jpg";
    }
    function folderOf(path: string): string {
        return path.substring(0, path.lastIndexOf("/"));
    }
    function isVideo(path: string): bool {
        return /\.(mp4|mkv|webm)$/i.test(path);
    }

    // ---- Acciones (por ruta) ---------------------------------------------------
    readonly property bool dry: Quickshell.env("CAPTURE_DRY") === "1"
    property var lastCommand: []
    function run(cmd: var): void {
        root.lastCommand = cmd;
        if (root.dry) console.log("CAPTURE_DRY " + JSON.stringify(cmd));
        else Quickshell.execDetached(cmd);
    }
    function sh(script: string, path: string): void {
        root.run(["sh", "-c", script, "sh", path]);
    }

    // Accion principal: imagen -> Anotar, video -> Reproducir.
    function primary(path: string): void {
        if (root.isVideo(path)) root.open(path);
        else root.annotate(path);
    }
    // satty sobre el mismo archivo (B8-c): guardar lo sobrescribe, Enter copia.
    function annotate(path: string): void {
        root.run(["satty", "--filename", path, "--output-filename", path]);
    }
    function open(path: string): void {
        root.run(["xdg-open", path]);
    }
    // yazi (en kitty, la terminal de binds.lua) abre la carpeta con el archivo
    // seleccionado.
    function showInFolder(path: string): void {
        root.run(["kitty", "-e", "yazi", path]);
    }
    // Copiar otra vez: la imagen; un video, como archivo (text/uri-list, se
    // pega en chats y gestores de archivos).
    function copy(path: string): void {
        if (root.isVideo(path)) root.copyFile(path);
        else root.sh('wl-copy -t image/png < "$1"', path);
    }
    function copyFile(path: string): void {
        root.sh('printf "file://%s\\r\\n" "$1" | wl-copy -t text/uri-list', path);
    }
    function copyPath(path: string): void {
        root.run(["wl-copy", "--", path]);
    }
    // A la papelera (B8-d); restore() la devuelve a su lugar (el ultimo
    // elemento de la papelera con esa ruta original).
    function trash(path: string): void {
        root.run(["gio", "trash", "--", path]);
        if (root.current && root.current.path === path) root.status = "trashed";
    }
    function restore(path: string): void {
        root.sh('u=$(gio trash --list | awk -F "\\t" -v p="$1" \'$2 == p { u = $1 } END { print u }\'); [ -n "$u" ] && gio trash --restore "$u"', path);
        if (root.current && root.current.path === path) root.status = "";
    }

    // ---- Grabacion -------------------------------------------------------------
    // recording: { pid, file, started, mode, region, monitor } mientras
    // wf-recorder corre (el script escribe el archivo y avisa con refresh).
    property var recording: null
    readonly property bool isRecording: root.recording !== null
    // "" | "stopping" | "saved" | "error": el final, 1,5 s en la pill.
    property string recordResult: ""
    property int recordedMs: 0
    // Segundos desde que empezo; solo corre el timer mientras se graba.
    property int elapsed: 0
    // Zona grabada en coordenadas globales (sin marcas en pantalla completa).
    readonly property var recordRegion: {
        const r = root.recording;
        if (!r || r.mode === "full") return null;
        const m = /^(-?\d+),(-?\d+) (\d+)x(\d+)$/.exec(r.region || "");
        return m ? { x: parseInt(m[1]), y: parseInt(m[2]), w: parseInt(m[3]), h: parseInt(m[4]) } : null;
    }

    function stopRecording(): void {
        if (!root.isRecording) return;
        root.recordResult = "stopping";
        root.run([root.scripts + "/record", "stop"]);
    }
    function refresh(): void {
        stateView.reload();
    }
    function recorded(result: string, ms: string): void {
        root.recording = null;
        root.recordedMs = parseInt(ms) || root.elapsed * 1000;
        root.recordResult = result === "ok" ? "saved" : "error";
        resultTimer.restart();
    }

    function tick(): void {
        root.elapsed = root.recording ? Math.max(0, Math.floor((Date.now() - root.recording.started) / 1000)) : 0;
    }

    FileView {
        id: stateView
        path: root.stateFile
        printErrors: false
        onLoaded: {
            let r = null;
            try {
                r = JSON.parse(stateView.text());
            } catch (e) {}
            root.recording = r && r.pid ? r : null;
        }
        onLoadFailed: root.recording = null
    }
    onIsRecordingChanged: {
        if (root.isRecording) {
            resultTimer.stop();
            root.recordResult = "";
        }
        root.tick();
    }
    Timer {
        running: root.isRecording
        interval: 1000
        repeat: true
        onTriggered: root.tick()
    }
    Timer {
        id: resultTimer
        interval: root.recordResult === "error" ? 3000 : 1500
        onTriggered: root.recordResult = ""
    }
}
