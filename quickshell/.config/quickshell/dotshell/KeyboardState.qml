// Teclado principal (Fase 11 B2): distribuciones, la activa, Bloq Mayus y
// Bloq Num. Una sola lectura de `hyprctl devices -j` (el teclado "main") al
// arrancar, con el evento "activelayout" de Hyprland y cuando el atajo de
// Bloq Mayus / Bloq Num (no consumidores, binds.lua) llama por IPC (`osd
// keys`): no hay evento de esas teclas y nunca se consulta solo. La usan los
// modulos de la barra (KeyboardLayout, LockKeys) y los avisos del OSD
// (SystemNotices). KEYBOARD_STATE_HYPRCTL: otro hyprctl (pruebas).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
    id: root

    property string device: ""
    property var layouts: []
    property int index: 0
    property string keymap: ""
    property bool capsLock: false
    property bool numLock: false
    property bool ready: false
    // Codigo corto de la activa: "us" -> "US", "latam" -> "LATAM".
    readonly property string code: (root.layouts[root.index] || "").toUpperCase()

    // Cambios de Bloq Mayus / Bloq Num vistos en la ultima lectura (para los avisos).
    signal locksChanged(bool caps, bool num)
    signal layoutChanged(string name)

    readonly property var hyprctl: (Quickshell.env("KEYBOARD_STATE_HYPRCTL") || "hyprctl").split(" ")

    function refresh(): void {
        if (!reader.running) reader.running = true;
    }
    // A la siguiente distribucion (clic en el modulo de la barra).
    function next(): void {
        if (!root.device || root.layouts.length < 2) return;
        Quickshell.execDetached(root.hyprctl.concat(["switchxkblayout", root.device, "next"]));
    }

    property Process reader: Process {
        command: root.hyprctl.concat(["devices", "-j"])
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(this.text).keyboards || [];
                    const kb = kbs.find(k => k.main) || kbs[0];
                    if (!kb) return;
                    const caps = !!kb.capsLock, num = !!kb.numLock;
                    const lockChange = root.ready && (caps !== root.capsLock || num !== root.numLock);
                    const layoutChange = root.ready && kb.active_keymap !== root.keymap;
                    root.device = kb.name;
                    root.layouts = String(kb.layout || "").split(",").filter(x => x);
                    root.index = kb.active_layout_index || 0;
                    root.keymap = kb.active_keymap || "";
                    root.capsLock = caps;
                    root.numLock = num;
                    root.ready = true;
                    if (lockChange) root.locksChanged(caps, num);
                    if (layoutChange) root.layoutChanged(root.keymap);
                } catch (e) {}
            }
        }
    }
    property Connections hypr: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") root.refresh();
        }
    }
    Component.onCompleted: root.refresh()
}
