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
    // true tras la primera lectura correcta (la carga es asincrona: al primer
    // uso los valores son los por defecto durante ~150 ms).
    property bool loaded: false

    // Rutas absolutas, igual que las guarda theme-apply.sh.
    function isFavorite(path: string): bool {
        return (root.favorites || []).indexOf(path) >= 0;
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
        onLoaded: root.loaded = true
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
        }
    }
}
