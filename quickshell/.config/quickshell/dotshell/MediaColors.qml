// Acento de la portada (Fase 12 B4, P12.5): la paleta local (contrato
// LocalPalette de P8.7) de la portada de lo que suena, armonizada con el fondo
// de pantalla (scripts/local-palette). La piden la pestana Musica y la tarjeta
// de Inicio mientras se ven (Demand "mediacolors"); una vez por portada, con
// numero de pedido (lo que llega de una portada anterior se ignora).
// Mientras no hay una valida (llegando, portada gris, poco contraste, se
// confunde con un estado, media.colors.fromCover apagado), cada alias da el de
// siempre (Colors.accent...), asi que quien la usa no pregunta nada.
// Solo para los elementos que P8.7 §3.4 permite: progreso, reproducir/pausa,
// las barras de audio (palette check, PC-Q5). Nunca superficies ni texto.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property bool enabled: SettingsState.value("media.colors.fromCover") !== false
    readonly property string art: MediaState.active ? (MediaState.active.trackArtUrl || "") : ""
    readonly property string script: Quickshell.env("LOCAL_PALETTE") || (Quickshell.env("HOME") + "/.config/hypr/scripts/local-palette")
    // Cambia con el tema (otro fondo, modo o contraste mueven el acento y su texto):
    // la paleta se vuelve a derivar.
    readonly property string theme: [Colors.accent, Colors.textOnAccent].join("|")

    property var palette: null
    readonly property bool valid: root.enabled && !!root.palette && root.palette.valid === true
    // Sin una de la portada (sin portada, gris...): la de la app del reproductor
    // (AppColors, P5.6), y si tampoco, la del fondo.
    readonly property string app: MediaState.active ? (MediaState.active.desktopEntry || MediaState.active.identity || "") : ""
    readonly property bool appValid: root.enabled && !root.valid && !!root.app && AppColors.has(root.app)
    readonly property color accent: root.valid ? root.palette.accent : root.appValid ? AppColors.accent(root.app) : Colors.accent
    readonly property color onAccent: root.valid ? root.palette.onAccent : root.appValid ? AppColors.onAccent(root.app) : Colors.textOnAccent
    readonly property color container: root.valid ? root.palette.container : root.appValid ? AppColors.container(root.app) : Colors.accentContainer
    readonly property color onContainer: root.valid ? root.palette.onContainer : root.appValid ? AppColors.onContainer(root.app) : Colors.textOnAccentContainer

    property Demand demand: Demand {
        name: "mediacolors"
        onActiveChanged: root.update()
    }
    onArtChanged: root.update()
    onThemeChanged: root.update()
    onEnabledChanged: root.update()

    property int req: 0
    property string asked: ""
    function update(): void {
        if (!root.demand.active || !root.enabled) return;
        const want = root.art + "\n" + root.theme;
        if (want === root.asked) return;
        root.asked = want;
        root.req++;
        if (!root.art) {
            root.palette = null;
            return;
        }
        // La anterior queda hasta que llega la nueva (sin un salto al acento del fondo en el medio).
        // Si corre otra, al terminar ve que el pedido cambio y pregunta de nuevo.
        if (proc.running) return;
        proc.req = root.req;
        proc.command = [root.script, root.art];
        proc.running = true;
    }
    property Process proc: Process {
        property int req: 0
        stdout: StdioCollector { id: out }
        onExited: (code) => {
            if (proc.req !== root.req) {
                // Lo pidieron de nuevo mientras corria: la ultima pregunta.
                if (root.demand.active) { root.asked = ""; root.update(); }
                return;
            }
            let d = null;
            try { d = JSON.parse(out.text); } catch (e) {}
            root.palette = code === 0 && d ? d : null;
        }
    }
}
