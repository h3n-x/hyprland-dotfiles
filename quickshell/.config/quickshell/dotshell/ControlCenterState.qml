// Visibilidad del Control Center -- reemplaza a "swaync-client -t -sw".
// Singleton chico, mismo patron que BarVisibility.qml: el IpcHandler de
// shell.qml (bind SUPER+N) escribe aca, ControlCenter.qml (una instancia
// por pantalla) lee de aca.
pragma Singleton
import QtQuick

QtObject {
    property bool visible: false
}
