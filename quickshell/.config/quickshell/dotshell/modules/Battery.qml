// Reemplaza a waybar/modules/battery.jsonc, incluidas las notificaciones de
// los eventos on-discharging-warning/critical y on-charging-100. UPower.
// displayDevice es reactivo (DBus), sin polling.
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, ControlCenterState.qml

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

    // Material Symbols (D10): 7 niveles de barras + lleno, alerta en critico.
    readonly property string icon: {
        if (root.charging) return "battery_charging_full";
        if (root.isCritical) return "battery_alert";
        if (root.pct >= 0.95) return "battery_full";
        return "battery_" + Math.max(0, Math.min(6, Math.round(root.pct * 6))) + "_bar";
    }
    readonly property color fg: {
        // Critico = error, aviso = tertiary, cargando = acento (decision P3:
        // antes cargando y aviso compartian tertiary).
        if (root.isCritical) return Colors.m3error;
        if (root.isWarning) return Colors.m3tertiary;
        if (root.charging) return Colors.m3primary;
        return Colors.m3onSurface;
    }

    function notify(summary, urgency, icon) {
        Quickshell.execDetached(["notify-send", summary, "-u", urgency, "-i", icon,
            "-h", "string:x-canonical-private-synchronous:battery"]);
    }

    onIsCriticalChanged: if (root.isCritical) root.notify("Battery Critical (10%)", "critical", "battery-010")
    onIsWarningChanged: if (root.isWarning) root.notify("Battery Low (20%)", "critical", "battery-020")
    onIsFullChanged: if (root.isFull) root.notify("Battery Full (100%)", "normal", "battery-100-charged")

    RowLayout {
        id: label
        spacing: Tokens.space.xs
        Icon {
            Layout.alignment: Qt.AlignVCenter
            name: root.icon
            filled: true
            color: root.fg
        }
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: Math.round(root.pct * 100) + "%"
            color: root.fg
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
            font.weight: Tokens.weight.medium
            font.features: Tokens.tabularNumbers
        }
    }

    // Hover por control (P2.4, Q2 = A).
    HoverHalo { hovered: hoverArea.containsMouse; pressed: hoverArea.pressed }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
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
