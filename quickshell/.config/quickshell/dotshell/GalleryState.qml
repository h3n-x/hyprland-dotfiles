// Visibilidad de la galeria de wallpapers (Fase 3 B3) -- mismo patron que
// LauncherState.qml. El IpcHandler "gallery" de shell.qml (bind SUPER+SHIFT+W)
// escribe aca, WallpaperGallery.qml (una instancia por pantalla) lee de aca.
pragma Singleton
import QtQuick

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
    // La ventana todavia se ve (incluye la animacion de salida). La barra de la
    // vista previa (B7) toma el teclado recien cuando es false: si no, al
    // soltar su foco la galeria le devuelve el teclado a la ventana anterior.
    property bool windowShown: false
}
