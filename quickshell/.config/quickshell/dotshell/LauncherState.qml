// Visibilidad del launcher -- mismo patron que BarVisibility.qml/
// ControlCenterState.qml. El IpcHandler de shell.qml (bind SUPER+D)
// escribe aca, Launcher.qml (una instancia por pantalla) lee de aca.
pragma Singleton
import QtQuick

QtObject {
    property bool visible: false
}
