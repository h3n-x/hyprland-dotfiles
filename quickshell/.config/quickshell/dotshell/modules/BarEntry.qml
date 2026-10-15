// Un modulo de la barra por su id (Fase 11 B1): la disposicion (bar.layout)
// solo nombra ids; aca se elige el componente de siempre. Expone `shown` (lo
// que el propio modulo dice; sin esa propiedad, siempre) para que la pildora
// sepa si queda vacia, y el hover de pildora entera de los modulos de accion
// unica (wholePill, la musica). Mientras el centro de configuracion lo senala
// (BarVisibility.highlight), un contorno neutro lo marca.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, BarVisibility.qml

Loader {
    id: entry

    required property string mid
    property var panelWindow

    readonly property bool shown: !!entry.item && entry.item.shown !== false
    readonly property bool wholePill: !!entry.item && entry.item.wholePill === true
    readonly property bool hovered: entry.wholePill && entry.item.hovered
    readonly property bool pressed: entry.wholePill && entry.item.pressed

    Layout.alignment: Qt.AlignVCenter
    visible: entry.shown
    sourceComponent: ({
        "workspaces": workspacesC, "media": mediaC, "clock": clockC, "recording": recordingC, "updates": updatesC,
        "network": networkC, "bluetooth": bluetoothC, "tray": trayC, "microphone": microphoneC, "battery": batteryC,
        "idle": idleC, "ports": portsC, "power": powerC,
        // Fase 11 B2
        "keyboard": keyboardC, "lockKeys": lockKeysC, "activeWindow": activeWindowC, "notifications": notificationsC,
        "privacy": privacyC, "launcher": launcherC,
        // Fase 11 B2b
        "resources": resourcesC, "netspeed": netspeedC,
        // Fase 11 B5b
        "timer": timerC
    })[entry.mid] || null

    // Informacion al pasar el raton (bar.tooltips, Fase 11 B2b): el texto del
    // modulo (tooltip) o su nombre; la barra la muestra debajo.
    HoverHandler {
        id: hover
        enabled: SettingsState.value("bar.tooltips") === true
        onHoveredChanged: if (entry.panelWindow && entry.panelWindow.tip)
            entry.panelWindow.tip(hover.hovered ? entry : null)
    }
    // Sin rotulo propio, el nombre del modulo (del esquema en ingles, contexto "settings").
    readonly property string tooltip: (entry.item && entry.item.tooltip) || I18n.trc("settings", ((SettingsState.meta("bar.layout") || {}).modules || {})[entry.mid]?.label || "")

    Rectangle {
        visible: BarVisibility.highlight !== "" && BarVisibility.highlight === entry.mid
        anchors.fill: parent
        anchors.margins: -Tokens.space.xs
        radius: Tokens.radius.sm
        color: "transparent"
        border.width: 2
        border.color: Colors.text
        z: 10
    }

    Component { id: workspacesC; Workspaces { screenName: entry.panelWindow && entry.panelWindow.screen ? entry.panelWindow.screen.name : "" } }
    Component { id: mediaC; Mpris { squeeze: entry.panelWindow && entry.panelWindow.squeeze || 0 } }
    Component { id: clockC; Clock {} }
    Component { id: recordingC; RecordingPill {} }
    Component { id: updatesC; Update {} }
    Component { id: networkC; Network { panelWindow: entry.panelWindow } }
    Component { id: bluetoothC; Bluetooth { panelWindow: entry.panelWindow } }
    Component { id: trayC; Tray { panelWindow: entry.panelWindow } }
    Component { id: microphoneC; Microphone { panelWindow: entry.panelWindow } }
    Component { id: batteryC; Battery { panelWindow: entry.panelWindow } }
    Component { id: idleC; IdleToggle { panelWindow: entry.panelWindow } }
    Component { id: portsC; Ports { panelWindow: entry.panelWindow } }
    Component { id: powerC; Power {} }
    Component { id: keyboardC; KeyboardLayout {} }
    Component { id: lockKeysC; LockKeys {} }
    Component { id: activeWindowC; ActiveWindow { squeeze: entry.panelWindow && entry.panelWindow.squeeze || 0 } }
    Component { id: notificationsC; NotificationBell {} }
    Component { id: privacyC; Privacy {} }
    Component { id: launcherC; LauncherButton {} }
    Component { id: resourcesC; Resources {} }
    Component { id: netspeedC; NetSpeed {} }
    Component { id: timerC; TimerModule {} }
}
