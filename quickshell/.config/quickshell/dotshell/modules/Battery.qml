// Pill de bateria, con las notificaciones de bateria baja, critica y llena.
// Porcentaje, carga y umbrales salen de BatteryState (UPower, sin polling),
// los mismos que usa el estado general del dashboard. Clic: su propio menu
// (BatteryDropdown, Fase 14 B1; antes abria el centro de control); clic del
// medio: el siguiente perfil de energia.
import QtQuick
import Quickshell
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, BatteryState.qml, PowerProfileState.qml

Item {
    id: root
    required property var panelWindow
    // Si se muestra, segun su propio estado (que este en la barra lo decide bar.layout, Fase 11 B1).
    // La barra lee shown, no visible: visible depende del padre y una pill
    // oculta nunca volveria a mostrarse.
    readonly property bool shown: BatteryState.present
    // Texto de la informacion al pasar el raton (bar.tooltips, Fase 11 B2b).
    readonly property string tooltip: I18n.tr("%1 %", Math.round(BatteryState.pct * 100)) + (BatteryState.charging ? " · " + I18n.tr("charging") : "")
        + (BatteryState.secondsLeft > 0 ? " · " + (BatteryState.charging ? I18n.tr("%1 to full", I18n.duration(BatteryState.secondsLeft))
                                                                       : I18n.tr("%1 left", I18n.duration(BatteryState.secondsLeft))) : "")
    visible: shown
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    readonly property real pct: BatteryState.pct
    readonly property bool charging: BatteryState.charging
    readonly property bool isCritical: BatteryState.critical
    readonly property bool isWarning: BatteryState.warning
    readonly property bool isFull: BatteryState.full

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

    // priority: nunca se retiene en pantalla completa ni en una captura
    // (x-dotfiles-priority, FullscreenState.isPriority).
    function notify(summary, urgency, icon, priority) {
        Quickshell.execDetached(["notify-send", summary, "-u", urgency, "-i", icon,
            "-h", "string:x-canonical-private-synchronous:battery"]
            .concat(priority ? ["-h", "string:x-dotfiles-priority:1"] : []));
    }

    onIsCriticalChanged: if (root.isCritical) root.notify(I18n.tr("Battery critical (%1 %)", Math.round(BatteryState.criticalAt * 100)), "critical", "battery-010", true)
    onIsWarningChanged: if (root.isWarning) root.notify(I18n.tr("Battery low (%1 %)", Math.round(BatteryState.warnAt * 100)), "critical", "battery-020", true)
    onIsFullChanged: if (root.isFull) root.notify(I18n.tr("Battery charged (100 %)"), "normal", "battery-100-charged")

    GridLayout {
        id: label
        // Fila o columna segun la barra (Fase 11 B3).
        flow: Tokens.bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: Tokens.bar.vertical ? -1 : 1
        columns: Tokens.bar.vertical ? 1 : -1
        rowSpacing: Tokens.space.xs
        columnSpacing: Tokens.space.xs
        Icon {
            Layout.alignment: Qt.AlignCenter
            name: root.icon
            filled: true
            color: root.fg
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            // A un costado (Fase 11 B3): el numero solo, mas chico.
            text: Math.round(root.pct * 100) + (Tokens.bar.vertical ? "" : "%")
            color: root.fg
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.bar.vertical ? Tokens.type.caption : Tokens.type.body
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
                menu.toggle();
            }
        }
    }

    BatteryDropdown {
        id: menu
        anchorItem: root
        panelWindow: root.panelWindow
    }
}
