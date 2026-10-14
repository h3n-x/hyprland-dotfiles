// Perfil de energia (power-profiles-daemon), en un solo lugar (Fase 4 B7):
// el selector del centro de control, el clic central de la pill de bateria
// (pasa al siguiente) y la vista Sistema del dashboard. Se lee al pedirlo
// (refresh: al abrir cada panel), sin polling.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property var profiles: [
        { id: "power-saver", label: I18n.tr("Power saver"), icon: "eco" },
        { id: "balanced", label: I18n.tr("Balanced"), icon: "balance" },
        { id: "performance", label: I18n.tr("Performance"), icon: "rocket_launch" }
    ]
    property string current: "balanced"
    readonly property var info: root.profiles.find(p => p.id === root.current) || root.profiles[1]

    function refresh(): void {
        getProc.running = true;
    }
    function set(id: string): void {
        Quickshell.execDetached(["powerprofilesctl", "set", id]);
        root.current = id;
    }
    // Ahorro -> Normal -> Rendimiento -> Ahorro, con un aviso corto. Parte del
    // perfil real (otro programa, como el modo juego, puede haberlo cambiado).
    property bool cyclePending: false
    function cycle(): void {
        root.cyclePending = true;
        root.refresh();
    }
    function step(): void {
        const i = root.profiles.findIndex(p => p.id === root.current);
        const next = root.profiles[(i + 1) % root.profiles.length];
        root.set(next.id);
        Quickshell.execDetached(["notify-send", "-a", I18n.tr("Power"), I18n.tr("Power profile"), next.label,
            "-i", "power-profile-" + next.id, "-t", "2000"]);
    }

    property Process getProc: Process {
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                if (t) root.current = t;
                if (root.cyclePending) {
                    root.cyclePending = false;
                    root.step();
                }
            }
        }
    }
    Component.onCompleted: root.refresh()
}
