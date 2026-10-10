// Vista previa del tema antes de aplicar (Fase 3 B7, P3.3; decision W4):
// la shell entera (Colors) y el wallpaper (Wallpaper.qml) muestran un tema
// candidato desde memoria, sin escribir ningun archivo. Solo Aplicar pasa por
// theme-apply.sh. Bordes de Hyprland y apps no se previsualizan.
//
// La galeria abre la sesion con su lista filtrada (<- / -> la recorren). Cada
// paso primero decodifica la imagen (la capa del wallpaper avisa con
// imageReady) y recien ahi cambia la paleta: colores y wallpaper se mueven
// juntos (mismo criterio que B6a). Con el backend hyprpaper solo se
// previsualizan los colores.
//
// Aplicar deja la vista previa puesta hasta que llega el JSON de matugen con
// ese wallpaper: la paleta de la cache es la misma, asi que la shell no cambia
// una segunda vez.
pragma Singleton
import QtQuick
import Quickshell

Item {
    id: root

    // Sesion abierta (barra de la vista previa visible, galeria cerrada).
    property bool active: false
    // Lista de la galeria (nombres) y posicion actual.
    property var names: []
    property int index: -1
    readonly property string name: root.index >= 0 && root.index < root.names.length ? root.names[root.index] : ""
    // Pedido a la capa del wallpaper (ruta absoluta) y lo que se muestra.
    property string requested: ""
    property string wallpaper: ""
    // Rol -> color (en el modo que tendra al aplicarse, mas "mode" y su familia
    // de estado "status") mientras se muestra un candidato; null = el JSON.
    property var candidate: null
    // Transiciones de la sesion (pasos y cancelar) en dur.medium (decision B7c).
    property bool fast: false

    property string dir: ""
    property string scriptsDir: ""
    property var cache: ({})
    // Aplicado desde la vista previa: se suelta al llegar el JSON con esta imagen.
    property string applying: ""

    // Esc: volver a la galeria sobre este nombre (decision B7b).
    signal returned(string name)

    function open(names: var, index: int, dir: string, cache: var, scriptsDir: string): void {
        releaseTimer.stop();
        root.applying = "";
        root.names = names;
        root.dir = dir;
        root.cache = cache;
        root.scriptsDir = scriptsDir;
        root.fast = true;
        fastTimer.stop();
        root.active = true;
        root.show(index);
    }

    function show(i: int): void {
        if (!root.active || i < 0 || i >= root.names.length) return;
        root.index = i;
        root.requested = root.dir + "/" + root.names[i];
        // Sin capa de Quickshell (backend hyprpaper): no hay imagen que esperar.
        if (ThemeState.wallpaperBackend !== "quickshell")
            root.imageReady(root.requested);
    }
    function step(delta: int): void {
        root.show(Math.max(0, Math.min(root.names.length - 1, root.index + delta)));
    }

    // Modo con el que se aplicaria (P5.5), resuelto como theme-apply.sh:
    // appearance.colorMode; "auto" con la luminancia de la cache y la banda
    // muerta del esquema (entre los umbrales, el modo del tema actual).
    function modeOf(entry: var): string {
        const m = SettingsState.value("appearance.colorMode");
        if (m === "light" || m === "dark") return m;
        if (m !== "auto") return "dark";
        const meta = SettingsState.meta("appearance.colorMode") || {};
        const cur = (ThemeState.current && ThemeState.current.mode) || "dark";
        const l = entry ? entry.luma : undefined;
        if (typeof l !== "number") return cur;
        return l > meta.autoLight ? "light" : l < meta.autoDark ? "dark" : cur;
    }

    // La capa del wallpaper decodifico (o no pudo leer) la imagen pedida.
    function imageReady(path: string): void {
        if (!root.active || path !== root.requested) return;
        const entry = root.cache[path.split("/").pop()];
        const mode = root.modeOf(entry);
        const pal = { mode: mode, status: Colors.familyOf(mode) };
        if (entry && entry.colors)
            for (const role in entry.colors)
                pal[role] = entry.colors[role][mode];
        root.wallpaper = path;
        root.candidate = (entry && entry.colors) ? pal : null;
    }

    // back: Esc (volver a la galeria) o false (clic afuera, otro cambio de tema).
    function cancel(back: bool): void {
        if (!root.active) return;
        const name = root.name;
        root.active = false;
        root.requested = "";
        root.wallpaper = "";
        root.candidate = null;
        fastTimer.restart();
        if (back) root.returned(name);
    }

    function apply(): void {
        if (!root.active || !root.wallpaper) return;
        const path = root.wallpaper;
        root.applying = path;
        root.active = false;
        root.requested = "";
        Quickshell.execDetached([root.scriptsDir + "/theme-apply.sh", path, "--source", "gallery"]);
        // El mismo que ya esta aplicado: el JSON no cambia de imagen (y la
        // paleta es la misma), se suelta ya.
        if (path === Colors.image)
            root.release();
        else
            releaseTimer.restart();
    }

    function release(): void {
        releaseTimer.stop();
        root.applying = "";
        root.wallpaper = "";
        root.candidate = null;
        fastTimer.restart();
    }

    Connections {
        target: Colors
        function onImageChanged(): void {
            // Diferido: si se suelta dentro de este mismo aviso, la capa del
            // wallpaper todavia ve la imagen vieja y la muestra un instante.
            if (root.applying && Colors.image === root.applying)
                Qt.callLater(root.release);
            else if (root.active)
                // Otro cambio de tema (deshacer, terminal) mientras se previsualiza.
                root.cancel(false);
        }
    }
    // Por si matugen falla: no dejar la vista previa puesta para siempre.
    Timer {
        id: releaseTimer
        interval: 10000
        onTriggered: root.release()
    }
    // fast sigue un rato tras cerrar la sesion: la vuelta tambien es de 300 ms.
    Timer {
        id: fastTimer
        interval: Tokens.motion.medium + 50
        onTriggered: root.fast = false
    }
}
