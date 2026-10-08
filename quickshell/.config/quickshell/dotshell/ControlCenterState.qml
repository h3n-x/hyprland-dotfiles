// Visibilidad del Control Center -- reemplaza a "swaync-client -t -sw".
// Singleton chico, mismo patron que BarVisibility.qml: el IpcHandler de
// shell.qml (bind SUPER+N) escribe aca, ControlCenter.qml (una instancia
// por pantalla) lee de aca. editing (Fase 11 B6): editando los ajustes
// rapidos (TileGrid); se termina al cerrar.
pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool visible: false
    property bool editing: false
    // Abrir ya editando (lapiz, "controlcenter edit", Configuracion).
    function edit(): void {
        root.visible = true;
        root.editing = true;
    }
    onVisibleChanged: if (!root.visible) root.editing = false
}
