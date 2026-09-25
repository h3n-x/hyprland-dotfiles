// Visibilidad del launcher -- mismo patron que BarVisibility.qml/
// ControlCenterState.qml. El IpcHandler de shell.qml (bind SUPER+D)
// escribe aca, Launcher.qml (una instancia por pantalla) lee de aca.
//
// screen (Fase 4 B0, E12): monitor donde se abre, el enfocado al abrir; solo
// la instancia de esa pantalla se muestra (KI-S5).
pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool visible: false
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
}
