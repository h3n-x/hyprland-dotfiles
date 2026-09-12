// Singleton chico para el bind SUPER+SHIFT+B (mostrar/ocultar la barra),
// reemplaza a "killall -SIGUSR1 waybar". Bar.qml (todas las instancias,
// una por pantalla) bindea su propio "visible" a "!BarVisibility.hidden" --
// el toggle de mas abajo (via IpcHandler en shell.qml) afecta a todas las
// pantallas a la vez, mismo alcance que la señal de waybar.
pragma Singleton
import QtQuick

QtObject {
    property bool hidden: false
}
