// Dashboard (Fase 4 B7): abierto o cerrado, en que pantalla y que pestana.
// Unica entrada: SUPER+A (binds.lua -> IpcHandler "dashboard" de shell.qml),
// siempre en el monitor enfocado; ningun modulo de la barra lo abre.
// Dashboard.qml (uno por barra) lee de aca.
//
// Pestanas (Fase 12 B2): Inicio siempre primera; despues las de
// dashboard.tabs en este orden (de fabrica Musica, Sistema, Escritorios; Hoy
// y Mantenimiento opcionales). Una que no esta en la lista se puede abrir
// igual (su zona, su letra) y aparece en la barra mientras se ve.
// dashboard.openOn: "home" (abrir siempre en Inicio) o "last" (la ultima,
// mientras corre la shell).
pragma Singleton
import QtQuick

QtObject {
    id: root
    // Abierto y en que pantalla: de PopupState (Fase 8 B5), donde vive todo
    // popup anclado (uno solo abierto en la shell).
    readonly property bool visible: PopupState.isOpen("dashboard", "")
    readonly property string screen: root.visible ? PopupState.openScreen : ""
    property string tab: "home"
    // Como se llego a la pestana actual: "zone" (desde su zona de Inicio: la
    // zona crece) o "tab" (barra, teclas: se desliza).
    property string via: "tab"
    // Editando las zonas de Inicio (Fase 11 B4): lapiz, Ctrl+E o "dashboard edit"
    // (el boton "Editar Inicio" del centro de configuracion). Abrir o ir a otra pestana lo termina.
    property bool editing: false

    // Todas, en su orden; nombre e icono de cada una.
    readonly property var all: ["home", "music", "today", "system", "workspaces", "maintenance"]
    readonly property var meta: ({
        home: { label: "Inicio", icon: "home" },
        music: { label: "Música", icon: "queue_music" },
        today: { label: "Hoy", icon: "today" },
        system: { label: "Sistema", icon: "monitor_heart" },
        workspaces: { label: "Escritorios", icon: "space_dashboard" },
        maintenance: { label: "Mantenimiento", icon: "build" }
    })
    readonly property var chosen: SettingsState.value("dashboard.tabs") || ["music", "system", "workspaces"]
    // Las de la barra: Inicio, las elegidas y la que se ve (si no esta elegida).
    readonly property var tabs: root.all.filter(t => t === "home" || root.chosen.indexOf(t) >= 0 || t === root.tab)

    function open(): void {
        FocusedScreen.request(name => {
            if (SettingsState.value("dashboard.openOn") !== "last") root.tab = "home";
            root.via = "tab";
            root.editing = false;
            PopupState.open("dashboard", name);
        });
    }
    // Abrir Inicio ya editando (o empezar a editar si esta abierto).
    function edit(): void {
        if (root.visible) {
            root.showTab("home", "tab");
            root.editing = true;
            return;
        }
        FocusedScreen.request(name => {
            root.tab = "home";
            root.editing = true;
            PopupState.open("dashboard", name);
        });
    }
    // Abrir (si hace falta) en una pestana: IPC "dashboard tab <id>".
    function openTab(tab: string): bool {
        if (root.all.indexOf(tab) < 0) return false;
        if (root.visible) {
            root.showTab(tab, "tab");
            return true;
        }
        FocusedScreen.request(name => {
            root.tab = tab;
            root.via = "tab";
            root.editing = false;
            PopupState.open("dashboard", name);
        });
        return true;
    }
    function showTab(tab: string, via: string): void {
        if (root.all.indexOf(tab) < 0) return;
        root.via = via || "tab";
        root.tab = tab;
        if (tab !== "home") root.editing = false;
    }
    // La siguiente o la anterior de la barra (da la vuelta).
    function step(delta: int): void {
        const t = root.tabs, i = t.indexOf(root.tab);
        root.showTab(t[(i + delta + t.length) % t.length], "tab");
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
