// Vuelve a existir con icono propio en la barra (se habia sacado por
// duplicar el de la bandeja -- ver Tray.qml, que ahora filtra "nm-applet"
// a proposito). Razon real esta vez: abrir NetworkDropdown.qml, un panel
// propio en QML en vez de mandar a un menu fzf en una terminal.
import QtQuick
import Quickshell
import Quickshell.Networking
import ".." // Colors.qml

Item {
    id: root
    required property var panelWindow

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    function findDevice(type) {
        for (const d of Networking.devices.values) {
            if (d.type === type) return d;
        }
        return null;
    }

    readonly property var wifiDevice: root.findDevice(DeviceType.Wifi)
    readonly property var wiredDevice: root.findDevice(DeviceType.Wired)

    readonly property var activeWifiNetwork: {
        if (!root.wifiDevice) return null;
        for (const n of root.wifiDevice.networks.values) {
            if (n.connected) return n;
        }
        return null;
    }

    readonly property string icon: {
        if (root.wiredDevice && root.wiredDevice.connected) return "󰈀";
        if (!Networking.wifiEnabled) return "󰤮";
        if (!root.activeWifiNetwork) return "󰤯";
        const s = root.activeWifiNetwork.signalStrength;
        if (s > 0.75) return "󰤨";
        if (s > 0.5) return "󰤥";
        if (s > 0.25) return "󰤢";
        return "󰤟";
    }

    Text {
        id: label
        text: root.icon
        color: Colors.fg
        font.pixelSize: 15
    }

    NetworkDropdown {
        id: dropdown
        anchorItem: root
        panelWindow: root.panelWindow
        wifiDevice: root.wifiDevice
        wiredDevice: root.wiredDevice
    }

    MouseArea {
        anchors.fill: parent
        onClicked: dropdown.toggle()
    }
}
