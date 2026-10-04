// Avisos del sistema en el OSD (Fase 10 B4), cada uno apagado de fabrica y
// encendido desde el centro de configuracion (notifications.system.*):
//   Bloq Mayus     el atajo no-consumidor de Caps_Lock (binds.lua, al soltar)
//                  llama a capsLock() por IPC; el estado se lee una vez de
//                  hyprctl devices (no hay evento, nunca se consulta solo)
//   distribucion   el evento "activelayout" de Hyprland
//   cargador       BatteryState (UPower) al conectar o desconectar
// Por el OSD (transitorio, no va al historial de avisos). Quieto no hace nada.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: root

    function on(key: string): bool {
        return SettingsState.value("notifications.system." + key) === true;
    }

    function capsLock(): void {
        if (root.on("capsLock") && !caps.running) caps.running = true;
    }
    property Process caps: Process {
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kb = JSON.parse(this.text).keyboards || [];
                    const onNow = kb.some(k => k.capsLock);
                    OsdState.show("keyboard_capslock", -1, onNow ? "Bloq Mayús activado" : "Bloq Mayús desactivado");
                } catch (e) {}
            }
        }
    }

    property Connections layout: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout" || !root.on("layout")) return;
            // "teclado,Spanish (Latin American)": el nombre va despues de la primera coma.
            const name = event.data.slice(event.data.indexOf(",") + 1);
            if (name) OsdState.show("keyboard", -1, name);
        }
    }

    // El primer valor (al arrancar) no es un cambio.
    property bool lastAc: BatteryState.onAc
    property bool started: false
    property Connections charger: Connections {
        target: BatteryState
        function onOnAcChanged() {
            if (root.started && BatteryState.present && BatteryState.onAc !== root.lastAc && root.on("charger"))
                OsdState.show(BatteryState.onAc ? "power" : "battery_android_full", -1,
                    BatteryState.onAc ? "Cargador conectado" : "Funcionando con batería");
            root.lastAc = BatteryState.onAc;
        }
    }
    Component.onCompleted: Qt.callLater(() => root.started = true)
}
