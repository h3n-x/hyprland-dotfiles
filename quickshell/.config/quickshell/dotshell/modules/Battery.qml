// Pill de bateria, con las notificaciones de bateria baja, critica y llena.
// Porcentaje, carga y umbrales salen de SystemState (UPower, sin polling),
// los mismos que usa el estado general del dashboard.
import QtQuick
import Quickshell
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, ControlCenterState.qml, SystemState.qml, PowerProfileState.qml

Item {
    id: root
    visible: SystemState.hasBattery
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    readonly property real pct: SystemState.batteryPct
    readonly property bool charging: SystemState.charging
    readonly property bool isCritical: SystemState.batteryCritical
    readonly property bool isWarning: SystemState.batteryWarning
    readonly property bool isFull: SystemState.batteryFull

    // Material Symbols (D10): 7 niveles de barras + lleno, alerta en critico.
    readonly property string icon: {
        if (root.charging) return "battery_charging_full";
        if (root.isCritical) return "battery_alert";
        if (root.pct >= 0.95) return "battery_full";
        return "battery_" + Math.max(0, Math.min(6, Math.round(root.pct * 6))) + "_bar";
    }
    readonly property color fg: {
        // Estados con sus colores fijos (P8.7, principio 23): critico = danger,
        // aviso = warning, cargando = success.
        if (root.isCritical) return Colors.danger;
        if (root.isWarning) return Colors.warning;
        if (root.charging) return Colors.success;
        return Colors.text;
    }

    function notify(summary, urgency, icon) {
        Quickshell.execDetached(["notify-send", summary, "-u", urgency, "-i", icon,
            "-h", "string:x-canonical-private-synchronous:battery"]);
    }

    onIsCriticalChanged: if (root.isCritical) root.notify("Batería crítica (10 %)", "critical", "battery-010")
    onIsWarningChanged: if (root.isWarning) root.notify("Batería baja (20 %)", "critical", "battery-020")
    onIsFullChanged: if (root.isFull) root.notify("Batería cargada (100 %)", "normal", "battery-100-charged")

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
                PowerProfileState.cycle();
            } else {
                ControlCenterState.visible = !ControlCenterState.visible;
            }
        }
    }
}
