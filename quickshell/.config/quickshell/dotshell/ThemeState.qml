// Estado de temas (Fase 3): wallpaper aplicado, historial, favoritos,
// etiquetas y preferencias. Lo escribe hypr/.config/hypr/scripts/theme-apply.sh
// en ~/.local/state/dotfiles/wallpapers.json (fuera del repo, decision W6);
// aca solo se lee. Se relee solo cuando el archivo cambia.
//
// Solo lectura en B0: ningun modulo lo usa todavia (la galeria llega en B3).
// Los singletons se cargan al primer uso, asi que hasta entonces no hace nada.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // THEME_STATE_DIR permite apuntar a un estado de prueba (mismo nombre de
    // variable que usa theme-apply.sh).
    readonly property string path: (Quickshell.env("THEME_STATE_DIR") || (Quickshell.env("HOME") + "/.local/state/dotfiles")) + "/wallpapers.json"

    readonly property var current: adapter.current
    readonly property var history: adapter.history
    readonly property var favorites: adapter.favorites
    readonly property var tags: adapter.tags
    readonly property var prefs: adapter.prefs
    // Excepciones por wallpaper (Fase 3 B8b): ruta -> {seed, scheme}.
    readonly property var overrides: adapter.overrides
    // true tras la primera lectura correcta (la carga es asincrona: al primer
    // uso los valores son los por defecto durante ~150 ms).
    property bool loaded: false
    // true en cuanto se sabe algo del archivo: leido, o que no existe (primer
    // arranque). Wallpaper.qml espera esto para no dibujar sobre hyprpaper.
    property bool settled: false

    // Rutas absolutas, igual que las guarda theme-apply.sh.
    function isFavorite(path: string): bool {
        return (root.favorites || []).indexOf(path) >= 0;
    }

    // Quien dibuja el wallpaper (Fase 3 B6): "quickshell" (defecto, capa de
    // Wallpaper.qml con transicion) o "hyprpaper" (vuelta atras). Lo cambia
    // theme-apply.sh --backend.
    readonly property string wallpaperBackend: (root.prefs && root.prefs.wallpaper_backend) || "quickshell"

    // ---- Historial (Fase 3 B5) ----
    // Wallpapers del historial sin repetir, del mas reciente al mas viejo:
    // [{wallpaper, applied_at}, ...]. El historial ya viene ordenado (el mas
    // nuevo primero), asi que se queda la primera aparicion de cada uno.
    readonly property var recent: {
        const seen = {};
        const out = [];
        for (const e of (root.history || [])) {
            if (!e || !e.wallpaper || seen[e.wallpaper]) continue;
            seen[e.wallpaper] = true;
            out.push({ wallpaper: e.wallpaper, applied_at: e.applied_at });
        }
        return out;
    }
    // Destino de "deshacer": la entrada debajo de la actual.
    readonly property var previous: (root.history && root.history.length > 1) ? root.history[1] : null
    readonly property bool canUndo: root.previous !== null

    // Ultima vez que se aplico un wallpaper (ISO-8601) o "" si no esta en el historial.
    function lastAppliedOf(path: string): string {
        for (const e of (root.history || []))
            if (e && e.wallpaper === path) return e.applied_at || "";
        return "";
    }

    // Etiquetas de un wallpaper (Fase 3 B4).
    function tagsOf(path: string): var {
        return (root.tags && root.tags[path]) || [];
    }

    // Etiquetas en uso con su cantidad, de la mas usada a la menos (y por
    // nombre a igual cantidad): [{tag, count}, ...].
    readonly property var allTags: {
        const counts = {};
        const t = root.tags || {};
        for (const path in t)
            for (const tag of t[path])
                counts[tag] = (counts[tag] || 0) + 1;
        return Object.keys(counts)
            .map(tag => ({ tag: tag, count: counts[tag] }))
            .sort((a, b) => b.count - a.count || a.tag.localeCompare(b.tag));
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { root.loaded = true; root.settled = true; }
        onLoadFailed: root.settled = true
        // Sin archivo todavia (nunca se aplico un tema con theme-apply.sh).
        printErrors: false

        JsonAdapter {
            id: adapter
            property int version: 0
            property var current: null
            property var history: []
            property var favorites: []
            property var tags: ({})
            property var prefs: ({})
            property var overrides: ({})
        }
    }
}
