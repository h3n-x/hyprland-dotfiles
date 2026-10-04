// Reemplaza a waybar/modules/hyprland/workspaces.jsonc. Quickshell.Hyprland
// expone los workspaces por el socket de eventos de Hyprland (reactivo, sin
// polling). El scroll usa la misma sintaxis de dispatcher Lua que ya usaba
// el on-scroll-up/down de waybar ("hl.dsp.focus(...)"). Los iconos son los
// Material Symbols (circulos, decision I1 del design system).
//
// Slots (1..N, al menos 5, huecos como marcadores que se crean al
// enfocarlos): DesktopState.slots, los mismos que muestra el dashboard.
//
// Indicador de foco (P2.8, decision Q3 = A): un unico radio_button_checked
// que se desliza entre los slots con el spring calibrado. Los circulos de
// I1 no cambian; cada slot se desvanece segun lo cerca que pasa el
// indicador, asi no se superponen a mitad de camino.
import QtQuick
import Quickshell.Hyprland
import ".." // Colors.qml, Tokens.qml, DesktopState.qml

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    readonly property var slots: DesktopState.slots

    readonly property int pitch: Tokens.icon.md + Tokens.space.md
    readonly property int focusedIndex: root.slots.findIndex(w => !w.placeholder && Hyprland.focusedWorkspace === w)

    // La primera posicion (los workspaces llegan por el socket un instante
    // despues del arranque) no se anima: el spring se habilita despues.
    property bool settled: false
    Timer { interval: 500; running: true; onTriggered: root.settled = true }

    Row {
        id: row
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
        visible: root.focusedIndex >= 0
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
