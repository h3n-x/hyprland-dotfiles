// Selector de emoji (Fase 4 B3) -- mismo patron que PowerState.qml. El
// IpcHandler "emoji" de shell.qml (SUPER+.) escribe aca, Emoji.qml (una
// instancia por pantalla) lee de aca.
//
// Recuerda en ~/.local/state/dotfiles/emoji.json los ultimos 30 emojis usados
// (sin tono: el tono se aplica al mostrarlos) y el tono de piel global (0 =
// amarillo, 1-5 = claro a oscuro). Solo emojis, nada del contexto donde se
// escribieron. EMOJI_STATE_FILE cambia el archivo (pruebas).
//
// Los datos (data/emoji.json, generado por scripts/emoji-data: 1914 emojis
// con nombre y claves en espanol e ingles) se leen la primera vez que se abre
// el panel y quedan en memoria (una sola vez aunque haya varias pantallas).
//
// Imagenes (decision B3-g, medido): la rejilla dibuja cada emoji como PNG de
// ~/.cache/dotfiles/emoji/72 (≈ 6 MB y ≈ 4 ms por tecla, contra ≈ 38 MB y
// ≈ 30 ms con la fuente de color). "emoji-data --ensure-images" corre al
// iniciar el shell: al dia sale en ≈ 50 ms; si faltan o cambiaron datos o
// fuente las crea (≈ 20 s, con nice) y hasta entonces se dibuja texto.
// EMOJI_IMAGE_DIR (pruebas).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property bool visible: false
    property string screen: ""

    readonly property int maxRecent: 30
    readonly property var recent: adapter.recent
    readonly property int tone: adapter.tone

    // Datos: [{ e, n, en, g, k, s, w, t }] + byE (emoji -> entrada).
    property var all: []
    property var byE: ({})
    property bool wanted: false
    readonly property bool ready: root.all.length > 0
    readonly property string imageDir: Quickshell.env("EMOJI_IMAGE_DIR") || (Quickshell.env("HOME") + "/.cache/dotfiles/emoji/72")
    property bool imagesReady: false

    // Nombre del PNG: puntos de codigo en hex sin U+FE0F (igual que emoji-data).
    function fileOf(g: string): string {
        const out = [];
        for (let i = 0; i < g.length;) {
            const cp = g.codePointAt(i);
            i += cp > 0xFFFF ? 2 : 1;
            if (cp !== 0xFE0F) out.push(cp.toString(16));
        }
        return "file://" + root.imageDir + "/" + out.join("-") + ".png";
    }
    // Imagen de un emoji con el tono actual ("" si todavia no hay imagenes).
    function imageOf(x: var): string {
        if (!root.imagesReady) return "";
        return root.tone > 0 && x.tf ? x.tf[root.tone - 1] : x.f;
    }

    property Process images: Process {
        command: ["nice", "-n", "10", Quickshell.env("HOME") + "/.config/hypr/scripts/emoji-data", "--ensure-images",
            "--images-dir", root.imageDir]
        onExited: (code) => root.imagesReady = code === 0
    }

    property FileView data: FileView {
        path: root.wanted ? Quickshell.shellDir + "/data/emoji.json" : ""
        onLoaded: {
            const list = JSON.parse(this.text());
            const by = {};
            for (const x of list) {
                // Palabras de busqueda ya sin tildes (las arma el generador),
                // con espacios alrededor: " gato " contiene " gat" y " gato ".
                x.hn = " " + x.s + " ";
                x.hk = " " + x.w + " ";
                x.nw = x.s.split(" ").length;
                x.f = root.fileOf(x.e);
                if (x.t) x.tf = x.t.map(v => root.fileOf(v));
                by[x.e] = x;
            }
            root.byE = by;
            root.all = list;
        }
    }

    Component.onCompleted: root.images.running = true

    function open(): void {
        root.wanted = true;
        FocusedScreen.request(name => {
            root.screen = name;
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

    // Emoji usado (el de base, sin tono): primero de Recientes.
    function use(e: string): void {
        adapter.recent = [e].concat(adapter.recent.filter(x => x !== e)).slice(0, root.maxRecent);
        file.writeAdapter();
    }
    function clearRecent(): void {
        adapter.recent = [];
        file.writeAdapter();
    }
    function setTone(t: int): void {
        adapter.tone = Math.max(0, Math.min(5, t));
        file.writeAdapter();
    }

    property FileView file: FileView {
        id: file
        path: Quickshell.env("EMOJI_STATE_FILE") || (Quickshell.env("HOME") + "/.local/state/dotfiles/emoji.json")
        // Sin archivo todavia: se crea al primer uso.
        printErrors: false

        JsonAdapter {
            id: adapter
            property var recent: []
            property int tone: 0
        }
    }
}
