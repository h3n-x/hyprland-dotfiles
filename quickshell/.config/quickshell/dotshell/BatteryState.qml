// Bateria (Fase 9 B2: sacada de SystemState): UPower, por eventos, sin polling
// ni procesos. La usan la pill de la barra (Battery.qml), Inicio y Sistema del
// dashboard, el estado general (SystemState.status) y el bloqueo de pantalla
// (otro proceso: por eso no puede vivir en SystemState, que tiene muestreo).
// Umbrales: system.battery.criticalPct / warnPct (almacen de opciones).
pragma Singleton
import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: root.device.ready && root.device.isLaptopBattery
    readonly property real pct: root.present ? root.device.percentage : 0
    readonly property bool charging: root.device.state === UPowerDeviceState.Charging
    readonly property real criticalAt: SettingsState.value("system.battery.criticalPct") / 100
    readonly property real warnAt: SettingsState.value("system.battery.warnPct") / 100
    readonly property bool critical: root.present && !root.charging && root.pct > 0 && root.pct <= root.criticalAt
    readonly property bool warning: root.present && !root.charging && root.pct > root.criticalAt && root.pct <= root.warnAt
    readonly property bool full: root.present && root.charging && root.pct >= 0.999
    // Enchufado (cargando, cargada o en espera de cargar).
    readonly property bool onAc: root.present && [UPowerDeviceState.Discharging, UPowerDeviceState.PendingDischarge,
        UPowerDeviceState.Empty].indexOf(root.device.state) < 0
    // Segundos hasta vaciarse o llenarse (0 = UPower todavia no lo sabe).
    readonly property real secondsLeft: !root.present ? 0 : (root.charging ? root.device.timeToFull : root.device.timeToEmpty)
    // Potencia (W) que entra o sale de la bateria.
    readonly property real watts: root.present ? Math.abs(root.device.changeRate) : 0
    // Salud (Fase 14 B1, menu de la bateria): capacidad actual / de fabrica, de
    // la bateria real (el dispositivo combinado no la informa); -1 si no se sabe.
    readonly property var cell: UPower.devices.values.find(d => d.isLaptopBattery && d.healthSupported) || null
    readonly property real health: root.cell ? root.cell.healthPercentage / 100 : -1
}
