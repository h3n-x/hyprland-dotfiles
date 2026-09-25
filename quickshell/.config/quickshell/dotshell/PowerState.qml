// Menu de energia y sesion (Fase 4 B1) -- mismo patron que LauncherState.qml.
// El IpcHandler "power" de shell.qml (SUPER+M, SUPER+SHIFT+M) y el boton de la
// barra escriben aca; PowerMenu.qml (una instancia por pantalla) lee de aca.
//
// confirming: "" (menu) o la accion que espera confirmacion: logout, reboot o
// poweroff. screen: monitor enfocado al abrir (E12).
pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool visible: false
    property string screen: ""
    property string confirming: ""

    function open(): void {
        FocusedScreen.request(name => {
            root.confirming = "";
            root.screen = name;
            root.visible = true;
        });
    }
    // Abre directo en la confirmacion (SUPER+SHIFT+M: cerrar sesion).
    function openConfirm(action: string): void {
        FocusedScreen.request(name => {
            root.confirming = action;
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
