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
        if (!root.adapter || !root.adapter.enabled) return "bluetooth_disabled";
        if (root.anyConnected) return "bluetooth_connected";
        return "bluetooth";
    }

    Icon {
        id: label
        name: root.icon
        filled: root.anyConnected
    }

    BluetoothDropdown {
        id: dropdown
        anchorItem: root
        panelWindow: root.panelWindow
    }

    // Hover por control (P2.4, Q2 = A).
    HoverHalo { hovered: hoverArea.containsMouse; pressed: hoverArea.pressed }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: dropdown.toggle()
    }
}
