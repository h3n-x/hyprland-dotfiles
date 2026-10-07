// Reemplaza a waybar/modules/hyprland/workspaces.jsonc. Quickshell.Hyprland
// expone los workspaces por el socket de eventos de Hyprland (reactivo, sin
// polling). El scroll usa la misma sintaxis de dispatcher Lua que ya usaba
// el on-scroll-up/down de waybar ("hl.dsp.focus(...)"). Los iconos son los
// Material Symbols (circulos, decision I1 del design system).
//
// Slots (1..N, al menos 5, huecos como marcadores que se crean al
// enfocarlos): DesktopState.slots, los mismos que muestra el dashboard.
//
// Opciones (Fase 11 B2b): solo los de esta pantalla (bar.workspaces.perMonitor),
// sin los vacios (bar.workspaces.showEmpty) e iconos de las ventanas en vez de
// circulos (bar.workspaces.windowIcons, hasta bar.workspaces.maxIcons por
// escritorio; el enfocado lleva un contorno en el acento, como el indicador).
//
// Indicador de foco (P2.8, decision Q3 = A): un unico radio_button_checked
// que se desliza entre los slots con el spring calibrado. Los circulos de
// I1 no cambian; cada slot se desvanece segun lo cerca que pasa el
// indicador, asi no se superponen a mitad de camino.
import QtQuick
import Quickshell.Hyprland
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml, DesktopState.qml, AppInfo.qml

Item {
    id: root
    // Pantalla de esta barra (BarEntry), para "solo los de esta pantalla".
    property string screenName: ""
    readonly property bool perMonitor: SettingsState.value("bar.workspaces.perMonitor") === true
    readonly property bool showEmpty: SettingsState.value("bar.workspaces.showEmpty") !== false
    readonly property bool icons: SettingsState.value("bar.workspaces.windowIcons") === true
    readonly property int maxIcons: SettingsState.value("bar.workspaces.maxIcons") || 3

    implicitWidth: root.icons ? iconRow.implicitWidth : row.implicitWidth
    implicitHeight: row.implicitHeight

    readonly property var slots: DesktopState.slots.filter(w => {
        const real = !w.placeholder;
        if (root.perMonitor && (!real || !w.monitor || w.monitor.name !== root.screenName)) return false;
        if (!root.showEmpty && (!real || w.toplevels.values.length === 0) && Hyprland.focusedWorkspace !== w) return false;
        return true;
    })
    function appOf(t: var): string {
        return (t.wayland && t.wayland.appId) || (t.lastIpcObject && t.lastIpcObject.class) || "";
    }

    readonly property int pitch: Tokens.icon.md + Tokens.space.md
    readonly property int focusedIndex: root.slots.findIndex(w => !w.placeholder && Hyprland.focusedWorkspace === w)

    // La primera posicion (los workspaces llegan por el socket un instante
    // despues del arranque) no se anima: el spring se habilita despues.
    property bool settled: false
    Timer { interval: 500; running: true; onTriggered: root.settled = true }

    Row {
        id: row
        visible: !root.icons
        spacing: Tokens.space.md

        Repeater {
            model: root.slots

            Icon {
                id: label
                required property var modelData
                readonly property bool isPlaceholder: !!modelData.placeholder
                readonly property bool isFocused: !label.isPlaceholder && Hyprland.focusedWorkspace === modelData
                readonly property bool isEmpty: label.isPlaceholder || modelData.toplevels.values.length === 0
                readonly property bool isUrgent: !label.isPlaceholder && modelData.urgent

                // Circulos de Material Symbols (decision I1): ocupado = circulo
                // lleno chico, vacio = anillo, urgente = "error" en el rol de
                // error. El enfocado (anillo con punto en el acento) lo dibuja el
                // indicador deslizante de abajo: cada slot se oculta en proporcion
                // a lo cerca que esta el indicador (0 justo debajo, 1 a un icono
                // de distancia) para no verse a traves del anillo ni mezclarse con
                // el mientras pasa.
                name: label.isUrgent ? "error"
                    : label.isEmpty ? "radio_button_unchecked"
                    : "circle"
                opacity: label.isUrgent || !indicator.visible ? 1
                    : Math.min(1, Math.abs(indicator.x - label.x) / Tokens.icon.md)
                filled: !label.isEmpty
                size: label.isEmpty || label.isUrgent ? Tokens.icon.md : Tokens.icon.sm
                width: Tokens.icon.md
                height: Tokens.icon.md
                color: label.isUrgent ? Colors.danger
                    : Colors.textMuted

                // Cada workspace es un boton propio (Q2 = A).
                HoverHalo { hovered: slotMouse.containsMouse; pressed: slotMouse.pressed }

                MouseArea {
                    id: slotMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (label.isPlaceholder) DesktopState.focusWorkspace(label.modelData.id);
                        else label.modelData.activate();
                    }
                }
            }
        }
    }

    // Indicador de foco: se desliza con el spring calibrado (guia 3.6.1).
    Icon {
        id: indicator
        visible: !root.icons && root.focusedIndex >= 0
        name: "radio_button_checked"
        filled: true
        color: Colors.accent
        width: Tokens.icon.md
        height: Tokens.icon.md
        x: Math.max(0, root.focusedIndex) * root.pitch
        Behavior on x {
            enabled: root.settled && Tokens.motion.scale > 0
            SpringAnimation {
                spring: Tokens.motion.spring.qmlSpring
                damping: Tokens.motion.spring.qmlDamping
            }
        }
    }

    // Con iconos: cada escritorio muestra sus ventanas (hasta maxIcons, +n el resto).
    Row {
        id: iconRow
        visible: root.icons
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.space.sm
        Repeater {
            model: root.icons ? root.slots : []
            Rectangle {
                id: ws
                required property var modelData
                readonly property bool real: !ws.modelData.placeholder
                readonly property var wins: ws.real ? ws.modelData.toplevels.values : []
                readonly property bool focused: ws.real && Hyprland.focusedWorkspace === ws.modelData
                implicitWidth: Math.max(Tokens.icon.md, inner.implicitWidth) + 2 * Tokens.space.xs
                implicitHeight: Tokens.icon.md + 2 * Tokens.space.hair
                radius: height / 2
                color: ws.focused ? Colors.tint(Colors.accent, Tokens.tint.track) : "transparent"
                border.width: ws.focused ? 1 : 0
                border.color: Colors.accent
                Row {
                    id: inner
                    anchors.centerIn: parent
                    spacing: Tokens.space.hair
                    Icon {
                        visible: ws.wins.length === 0
                        name: ws.modelData.urgent ? "error" : "radio_button_unchecked"
                        color: ws.modelData.urgent ? Colors.danger : Colors.textMuted
                    }
                    Repeater {
                        model: ws.wins.slice(0, root.maxIcons)
                        IconImage {
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: Tokens.icon.sm
                            source: AppInfo.icon(root.appOf(modelData))
                        }
                    }
                    Text {
                        visible: ws.wins.length > root.maxIcons
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+" + (ws.wins.length - root.maxIcons)
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                    }
                }
                HoverHalo { hovered: wsMouse.containsMouse; pressed: wsMouse.pressed }
                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ws.real ? ws.modelData.activate() : DesktopState.focusWorkspace(ws.modelData.id)
                }
            }
        }
    }

    WheelHandler {
        target: root
        // bar.workspaces.scroll (Fase 10 B4).
        enabled: SettingsState.value("bar.workspaces.scroll") !== false
        onWheel: (event) => {
            const direction = event.angleDelta.y > 0 ? "r+1" : "r-1";
            Hyprland.dispatch("hl.dsp.focus({ workspace = '" + direction + "' })");
        }
    }
}
