// Avisos del sistema en el OSD (Fase 10 B4), cada uno apagado de fabrica y
// encendido desde el centro de configuracion (notifications.system.*):
//   Bloq Mayus     los atajos no-consumidores de Caps_Lock / Num_Lock
//                  (binds.lua, al soltar) llaman a keys() por IPC; el estado lo
//                  lee KeyboardState (Fase 11 B2), solo si alguien lo usa: este
//                  aviso o el modulo de la barra "lockKeys"
//   distribucion   KeyboardState.layoutChanged (evento "activelayout")
//   cargador       BatteryState (UPower) al conectar o desconectar
// Por el OSD (transitorio, no va al historial de avisos). Quieto no hace nada.
import QtQuick
import Quickshell

QtObject {
    id: root

    function on(key: string): bool {
        return SettingsState.value("notifications.system." + key) === true;
    }

    // Una tecla de bloqueo cambio: se relee solo si el aviso o la barra lo muestran.
    function keys(): void {
        if (root.on("capsLock") || BarVisibility.placed("lockKeys")) KeyboardState.refresh();
    }
    property Connections keyboard: Connections {
        target: KeyboardState
        function onCapsLockChanged() {
            if (KeyboardState.ready && root.on("capsLock"))
                OsdState.show("keyboard_capslock", -1, KeyboardState.capsLock ? I18n.tr("Caps Lock on") : I18n.tr("Caps Lock off"));
        }
        function onLayoutChanged(name) {
            if (root.on("layout") && name) OsdState.show("keyboard", -1, name);
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
                    BatteryState.onAc ? I18n.tr("Charger connected") : I18n.tr("Running on battery"));
            root.lastAc = BatteryState.onAc;
        }
    }
    Component.onCompleted: Qt.callLater(() => root.started = true)
}
