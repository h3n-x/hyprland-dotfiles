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
    // Abierto y en que pantalla: de PopupState (Fase 8 B5), donde vive todo
    // popup anclado (uno solo abierto en la shell).
    readonly property bool visible: PopupState.isOpen("dashboard", "")
    readonly property string screen: root.visible ? PopupState.openScreen : ""
    property string view: "home"
    // Editando las zonas de Inicio (Fase 11 B4): lapiz, Ctrl+E o "dashboard edit"
    // (el boton "Editar Inicio" del centro de configuracion). Abrir o ir a otra vista lo termina.
    property bool editing: false
    // En el orden de Inicio (de arriba abajo): los puntos de la cabecera.
    readonly property var views: ["home", "today", "system", "workspaces", "maintenance"]

    function open(): void {
        FocusedScreen.request(name => {
            root.view = "home";
            root.editing = false;
            PopupState.open("dashboard", name);
        });
    }
    // Abrir Inicio ya editando (o empezar a editar si esta abierto).
    function edit(): void {
        if (root.visible) {
            root.view = "home";
            root.editing = true;
            return;
        }
        FocusedScreen.request(name => {
            root.view = "home";
            root.editing = true;
            PopupState.open("dashboard", name);
        });
    }
    function showView(view: string): void {
        if (root.views.indexOf(view) < 0) return;
        root.view = view;
        if (view !== "home") root.editing = false;
    }
    function close(): void {
        root.editing = false;
        PopupState.close("dashboard");
    }
    function toggle(): void {
        if (root.visible) root.close();
        else root.open();
    }
}
