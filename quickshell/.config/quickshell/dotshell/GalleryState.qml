// Visibilidad de la galeria de wallpapers (Fase 3 B3) -- mismo patron que
// LauncherState.qml. El IpcHandler "gallery" de shell.qml (bind SUPER+SHIFT+W)
// escribe aca, WallpaperGallery.qml (una instancia por pantalla) lee de aca.
pragma Singleton
import QtQuick

QtObject {
    property bool visible: false
}
