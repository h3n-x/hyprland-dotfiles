// Selector de ventanas (Fase 4 B4) -- mismo patron que PowerState.qml. Los
// binds SUPER+TAB / SUPER+SHIFT+TAB llaman al IpcHandler "switcher" de
// shell.qml (next / prev), que escribe aca; Switcher.qml (una instancia por
// pantalla) lee de aca.
//
// next()/prev() con el panel cerrado lo abren (en el monitor enfocado) con la
// ventana anterior elegida y en modo "hold": se supone Super apretado y
// soltarlo cambia de ventana. Con el panel abierto, mueven la seleccion (el
// bind de Hyprland atrapa SUPER+TAB aunque el panel tenga el teclado).
pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool visible: false
    property string screen: ""

    // Pasos pedidos (next = +1, prev = -1); Switcher.qml los aplica.
    signal step(int delta)

    function next(): void {
        if (root.visible) root.step(1);
        else root.open();
    }
    function prev(): void {
        if (root.visible) root.step(-1);
        else root.open();
    }
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
