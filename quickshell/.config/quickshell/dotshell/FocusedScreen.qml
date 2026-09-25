// Monitor con el foco (Fase 4 B0, decision E12, KI-S5): los paneles de
// pantalla completa se abren solo ahi, no en todos los monitores.
//
// Hyprland.focusedMonitor llega por eventos: recien arrancada la shell puede
// valer null hasta el primer cambio de foco. En ese caso se pregunta una vez a
// hyprctl (~10 ms) al abrir; si eso tambien falla, la primera pantalla. Nunca
// se abre en "ninguna".
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    readonly property string known: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    property var pending: []

    // Llama a apply(nombre) con el monitor enfocado, al instante si ya se conoce.
    function request(apply: var): void {
        if (root.known !== "") {
            apply(root.known);
            return;
        }
        root.pending.push(apply);
        if (!query.running) query.running = true;
    }

    function finish(name: string): void {
        const n = name || (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        const cbs = root.pending;
        root.pending = [];
        for (const cb of cbs) cb(n);
    }

    Process {
        id: query
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = "";
                try {
                    const m = JSON.parse(this.text).find(x => x.focused);
                    if (m) name = m.name;
                } catch (e) {}
                root.finish(name);
            }
        }
        onExited: (code) => { if (code !== 0) root.finish(""); }
    }
}
