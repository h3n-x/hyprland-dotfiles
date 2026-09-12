// Vuelve a existir con icono propio (se habia sacado por duplicar el de
// la bandeja -- ver Tray.qml, que ahora filtra "blueman" a proposito).
// Razon real esta vez: abrir BluetoothDropdown.qml en vez de mandar a un
// menu fzf en una terminal.
import QtQuick
import Quickshell.Bluetooth
import ".." // Colors.qml

Item {
    id: root
    required property var panelWindow

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool anyConnected: Bluetooth.devices.values.some(d => d.connected)

    readonly property string icon: {
        if (!root.adapter || !root.adapter.enabled) return "󰂲";
        if (root.anyConnected) return "󰂱";
        return "󰂯";
    }

    Text {
        id: label
        text: root.icon
        color: Colors.fg
        font.pixelSize: 15
    }

    BluetoothDropdown {
        id: dropdown
        anchorItem: root
        panelWindow: root.panelWindow
    }

    MouseArea {
        anchors.fill: parent
        onClicked: dropdown.toggle()
    }
}
