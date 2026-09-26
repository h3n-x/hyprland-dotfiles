// Dashboard (Fase 4 B7): abierto o cerrado, en que pantalla y que vista.
// Unica entrada: SUPER+A (binds.lua -> IpcHandler "dashboard" de shell.qml),
// siempre en el monitor enfocado; ningun modulo de la barra lo abre.
// Dashboard.qml (uno por barra) lee de aca.
//
// view: "home" (Inicio) o una vista de detalle ("today", "system",
// "workspaces", "maintenance" -- Fase 4 B9); abrir siempre empieza en Inicio.
pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool visible: false
    property string screen: ""
    property string view: "home"
    // En el orden de Inicio (de arriba abajo): los puntos de la cabecera.
    readonly property var views: ["home", "today", "system", "workspaces", "maintenance"]

    function open(): void {
        FocusedScreen.request(name => {
            root.screen = name;
            root.view = "home";
            root.visible = true;
        });
    }
    function showView(view: string): void {
        if (root.views.indexOf(view) >= 0) root.view = view;
    }
    function close(): void {
        root.visible = false;
    }
    function toggle(): void {
        if (root.visible) root.close();
        else root.open();
    }
}
