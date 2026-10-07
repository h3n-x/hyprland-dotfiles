// Frecuencia de la pantalla integrada segun el cargador (Fase 10 B5,
// display.highRefreshOnAC, apagado de fabrica): con bateria ~60 Hz, enchufado
// la mas alta (o la elegida en Pantallas). Lo decide y aplica
// scripts/settings-apply display-power; aca solo se lo pide al cambiar el
// cargador (BatteryState, que ya se vigila) y al arrancar, y se avisa por el
// OSD lo que cambio: nunca en silencio. Si la shell no esta, no cambia nada.
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property bool wanted: SettingsState.value("display.highRefreshOnAC") === true

    function check(): void {
        if (!root.wanted || !BatteryState.present || proc.running) return;
        proc.running = true;
    }

    property Process proc: Process {
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/settings-apply", "display-power"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    for (const c of JSON.parse(this.text) || [])
                        OsdState.show("monitor", -1, "Pantalla a " + c.hz + " Hz" + (c.battery ? " (batería)" : ""));
                } catch (e) {}
            }
        }
    }
    property Connections charger: Connections {
        target: BatteryState
        function onOnAcChanged() { root.check(); }
    }
    // Al activar la opcion, settings-apply ya la aplica (sin aviso); al arrancar, una vez.
    Component.onCompleted: Qt.callLater(root.check)
}
