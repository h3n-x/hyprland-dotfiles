// Reemplaza a waybar/modules/hyprland/workspaces.jsonc. Quickshell.Hyprland
// expone los workspaces por el socket de eventos de Hyprland (reactivo, sin
// polling). El scroll usa la misma sintaxis de dispatcher Lua que ya usaba
// el on-scroll-up/down de waybar ("hl.dsp.focus(...)"). Los iconos son los
// Material Symbols (circulos, decision I1 del design system).
//
// "persistent-workspaces": {"*": 5} de waybar fuerza que se vean siempre
// 5 slots aunque esten vacios -- Hyprland.workspaces de Quickshell solo
// lista los que existen de verdad, asi que "slots" rellena con objetos
// placeholder livianos {id, placeholder:true} los numeros 1..N que no
// tienen workspace real todavia (N = 5 o el id mas alto que exista, lo
// que sea mayor). Clickear un placeholder crea+enfoca ese workspace via
// dispatch (Hyprland lo crea solo al enfocarlo).
import QtQuick
import Quickshell.Hyprland
import ".." // Colors.qml, Tokens.qml

Row {
    id: root
    spacing: Tokens.space.md

    readonly property int minWorkspaces: 5
    readonly property var slots: {
        const real = Hyprland.workspaces.values;
        const maxId = real.reduce((m, w) => Math.max(m, w.id), 0);
        const count = Math.max(root.minWorkspaces, maxId);
        const result = [];
        for (let i = 1; i <= count; i++) {
            result.push(real.find(w => w.id === i) || { id: i, placeholder: true });
        }
        return result;
    }

    Repeater {
        model: root.slots

        Icon {
            id: label
            required property var modelData
            readonly property bool isPlaceholder: !!modelData.placeholder
            readonly property bool isFocused: !label.isPlaceholder && Hyprland.focusedWorkspace === modelData
            readonly property bool isEmpty: label.isPlaceholder || modelData.toplevels.values.length === 0
            readonly property bool isUrgent: !label.isPlaceholder && modelData.urgent

            // Circulos de Material Symbols (decision I1): enfocado = anillo con
            // punto en el acento, ocupado = circulo lleno chico, vacio = anillo.
            // Urgente antes devolvia "" (el glyph se habia perdido): ahora
            // "error" en el rol de error.
            name: label.isUrgent ? "error"
                : label.isFocused ? "radio_button_checked"
                : label.isEmpty ? "radio_button_unchecked"
                : "circle"
            filled: !label.isEmpty || label.isFocused
            size: label.isEmpty || label.isFocused || label.isUrgent ? Tokens.icon.md : Tokens.icon.sm
            width: Tokens.icon.md
            height: Tokens.icon.md
            color: label.isUrgent ? Colors.m3error
                : label.isFocused ? Colors.m3primary
                : Colors.m3onSurfaceVariant

            // Cada workspace es un boton propio (Q2 = A).
            HoverHalo { hovered: slotMouse.containsMouse; pressed: slotMouse.pressed }

            MouseArea {
                id: slotMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (label.isPlaceholder) {
                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + label.modelData.id + " })");
                    } else {
                        label.modelData.activate();
                    }
                }
            }
        }
    }

    WheelHandler {
        target: root
        onWheel: (event) => {
            const direction = event.angleDelta.y > 0 ? "r+1" : "r-1";
            Hyprland.dispatch("hl.dsp.focus({ workspace = '" + direction + "' })");
        }
    }
}
