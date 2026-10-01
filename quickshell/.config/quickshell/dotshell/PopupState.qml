// Popups anclados abiertos (Fase 8 B5, P8.4): la unica fuente de verdad de
// que AnchoredPanel esta abierto y en que pantalla. Como mucho UNO en toda la
// shell: abrir uno cierra el anterior (en cualquier pantalla).
//
// Cada AnchoredPanel tiene un popupId ("dashboard", "audio", "bluetooth",
// "network", "ports", "tray") y se abre solo en la pantalla de su ancla. Los
// modulos llaman a toggle() del panel; los estados como DashboardState leen de
// aca.
//
// API que reutiliza P8.6 (pantalla completa) sin tocar esta arquitectura:
// closeAll(pantalla) cierra lo que este abierto en ese monitor; openScreen dice
// donde esta. IPC "popups": status() y close() (sondas y diagnostico).
pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    property string openId: ""
    property string openScreen: ""

    function isOpen(id: string, screen: string): bool {
        return root.openId === id && id !== "" && (screen === "" || root.openScreen === screen);
    }
    function open(id: string, screen: string): void {
        root.openScreen = screen;
        root.openId = id;
    }
    // Sin id: cierra el que este abierto.
    function close(id: string): void {
        if (id && root.openId !== id) return;
        root.openId = "";
        root.openScreen = "";
    }
    function toggle(id: string, screen: string): void {
        if (root.isOpen(id, screen)) root.close(id);
        else root.open(id, screen);
    }
    // Sin pantalla: todos.
    function closeAll(screen: string): void {
        if (!screen || root.openScreen === screen) root.close("");
    }

    // Se desconecto el monitor del popup abierto: se cierra.
    property Connections screens: Connections {
        target: Quickshell
        function onScreensChanged(): void {
            if (!root.openScreen) return;
            if (!Quickshell.screens.some(s => s.name === root.openScreen)) root.close("");
        }
    }
}
