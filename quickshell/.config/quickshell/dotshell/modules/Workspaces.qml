// Reemplaza a waybar/modules/hyprland/workspaces.jsonc. Quickshell.Hyprland
// expone los workspaces por el socket de eventos de Hyprland (reactivo, sin
// polling). El scroll usa la misma sintaxis de dispatcher Lua que ya usaba
// el on-scroll-up/down de waybar ("hl.dsp.focus(...)"). Los iconos son los
// mismos 4 glyphs de format-icons en ese mismo archivo (active/default/
// empty/urgent).
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
import ".." // Colors.qml

Row {
    id: root
    spacing: 12

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

        Text {
            id: label
            required property var modelData
            readonly property bool isPlaceholder: !!modelData.placeholder
            readonly property bool isFocused: !label.isPlaceholder && Hyprland.focusedWorkspace === modelData
            readonly property bool isEmpty: label.isPlaceholder || modelData.toplevels.values.length === 0
            readonly property bool isUrgent: !label.isPlaceholder && modelData.urgent

            font.pixelSize: 16
            text: {
                if (label.isUrgent) return "";
                if (label.isFocused) return "󰮯";
                if (label.isEmpty) return "󱙝";
                return "󰊠";
            }
            color: {
                if (label.isUrgent) return Colors.critical;
                if (label.isFocused) return Colors.accent;
                return Colors.br;
            }

            MouseArea {
                anchors.fill: parent
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
