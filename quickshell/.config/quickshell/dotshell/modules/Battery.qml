// Reemplaza a waybar/modules/battery.jsonc, incluidas las notificaciones de
// los eventos on-discharging-warning/critical y on-charging-100. UPower.
// displayDevice es reactivo (DBus), sin polling.
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import ".." // Colors.qml, ControlCenterState.qml

Item {
    id: root
    visible: device.ready && device.isLaptopBattery
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    readonly property var device: UPower.displayDevice
    readonly property real pct: device.ready ? device.percentage : 0
    readonly property bool charging: device.state === UPowerDeviceState.Charging
    readonly property bool isCritical: !root.charging && root.pct > 0 && root.pct <= 0.10
    readonly property bool isWarning: !root.charging && root.pct > 0.10 && root.pct <= 0.20
    readonly property bool isFull: root.charging && root.pct >= 0.999

    readonly property var icons: ["󰂎", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property string icon: root.charging ? "󰉁" : root.icons[Math.min(root.icons.length - 1, Math.floor(root.pct * 10))]
    readonly property color fg: {
        if (root.isCritical) return Colors.critical;
        if (root.isWarning) return Colors.warning;
        if (root.charging) return Colors.charging;
        return Colors.fg;
    }

    function notify(summary, urgency, icon) {
        Quickshell.execDetached(["notify-send", summary, "-u", urgency, "-i", icon,
            "-h", "string:x-canonical-private-synchronous:battery"]);
    }

    onIsCriticalChanged: if (root.isCritical) root.notify("Battery Critical (10%)", "critical", "battery-010")
    onIsWarningChanged: if (root.isWarning) root.notify("Battery Low (20%)", "critical", "battery-020")
    onIsFullChanged: if (root.isFull) root.notify("Battery Full (100%)", "normal", "battery-100-charged")

    Text {
        id: label
        color: root.fg
        font.pixelSize: 13
        text: root.icon + " " + Math.round(root.pct * 100) + "%"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                Quickshell.execDetached(["sh", "-c", "cur=$(powerprofilesctl get 2>/dev/null || echo balanced); case \"$cur\" in power-saver) next=balanced ;; balanced) next=performance ;; *) next=power-saver ;; esac; powerprofilesctl set \"$next\"; notify-send -a 'Energía' 'Perfil cambiado' \"$next\" -i power-profile-$next -t 2000"]);
            } else {
                ControlCenterState.visible = !ControlCenterState.visible;
            }
        }
    }
}
