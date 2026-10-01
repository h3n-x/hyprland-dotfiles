// Visibilidad de la galeria de wallpapers (Fase 3 B3) -- mismo patron que
// LauncherState.qml. El IpcHandler "gallery" de shell.qml (bind SUPER+SHIFT+W)
// escribe aca, WallpaperGallery.qml (una instancia por pantalla) lee de aca.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property bool visible: false
    // Monitor donde se abre (Fase 4 B0, E12): el enfocado al abrir. Volver
    // desde la vista previa (Esc) reabre en el mismo.
    property string screen: ""

    function open(): void {
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
    // ---- Indice de la cache (Fase 8 B4, P8.3) -----------------------------------
    // palettes.json de wallpaper-cache.sh (nombre -> {mtime, size, thumb,
    // colors, ...}; ~450 KB con ~160 wallpapers). Se lee solo mientras la
    // galeria se ve y se suelta 2 min despues de cerrarla: antes se leia al
    // arrancar la shell y se releia con cada cambio de la cache aunque nadie
    // lo mirara. Una sola copia para todas las pantallas.
    readonly property string cacheDir: Quickshell.env("WALLPAPER_CACHE_DIR") || (Quickshell.env("HOME") + "/.cache/dotfiles/wallpapers")
    property var index: ({})
    property Demand indexDemand: Demand {
        name: "gallery.index"
        idleRelease: 2 * 60 * 1000
        onReleased: root.index = ({})
    }
    property FileView cacheFile: FileView {
        path: root.indexDemand.holding ? root.cacheDir + "/palettes.json" : ""
        watchChanges: true
        onFileChanged: reload()
        printErrors: false
        onLoaded: {
            try {
                root.index = JSON.parse(root.cacheFile.text());
            } catch (e) {
                root.index = ({});
            }
        }
    }

    // La ventana todavia se ve (incluye la animacion de salida). La barra de la
    // vista previa (B7) toma el teclado recien cuando es false: si no, al
    // soltar su foco la galeria le devuelve el teclado a la ventana anterior.
    property bool windowShown: false
}
