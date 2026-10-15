// Red (Fase 4 B7): que dispositivo y que red estan activos, en un solo lugar
// para la pill de la barra (icono), su desplegable (dispositivos) y la vista
// Sistema del dashboard (nombre de la conexion e interfaz para medir el
// trafico). Quickshell.Networking (NetworkManager por DBus): reactivo, sin
// polling.
pragma Singleton
import QtQuick
import Quickshell.Networking

QtObject {
    id: root

    function findDevice(type: var): var {
        for (const d of Networking.devices.values) {
            if (d.type === type) return d;
        }
        return null;
    }

    readonly property var wifiDevice: root.findDevice(DeviceType.Wifi)
    readonly property var wiredDevice: root.findDevice(DeviceType.Wired)
    readonly property bool wired: !!root.wiredDevice && root.wiredDevice.connected

    readonly property var activeWifiNetwork: {
        if (!root.wifiDevice) return null;
        for (const n of root.wifiDevice.networks.values) {
            if (n.connected) return n;
        }
        return null;
    }
    readonly property bool connected: root.wired || !!root.activeWifiNetwork

    // Icono de Material Symbols (el de la pill).
    readonly property string icon: {
        if (root.wired) return "lan";
        if (!Networking.wifiEnabled) return "wifi_off";
        if (!root.activeWifiNetwork) return "signal_wifi_0_bar";
        const s = root.activeWifiNetwork.signalStrength;
        if (s > 0.75) return "signal_wifi_4_bar";
        if (s > 0.5) return "network_wifi_3_bar";
        if (s > 0.25) return "network_wifi_2_bar";
        return "network_wifi_1_bar";
    }
    // "CasaNet", "Cable", "Sin conexión".
    readonly property string label: root.wired ? I18n.tr("Wired")
        : root.activeWifiNetwork ? root.activeWifiNetwork.name
        : !Networking.wifiEnabled ? I18n.tr("Wi-Fi off") : I18n.tr("Not connected")
    // Interfaz en uso (para /proc/net/dev): la del cable si esta conectado.
    readonly property string interfaceName: root.wired ? root.wiredDevice.name
        : root.activeWifiNetwork && root.wifiDevice ? root.wifiDevice.name : ""
}
