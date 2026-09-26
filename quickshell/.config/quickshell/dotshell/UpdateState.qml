// Actualizaciones del sistema (Fase 4 B7): un solo chequeo para la pill de la
// barra (Update.qml) y el aviso del dashboard. hypr/scripts/update.sh "data"
// devuelve un JSON con icon (download / check / sync_problem) y tooltip (lista
// "Repo: N" y "AUR: N"); sin argumentos abre el update interactivo. Chequeo
// al arrancar y cada hora; check() fuerza uno ya.
// Sin llaves antes de "pragma Singleton": Quickshell deja de verlo como
// singleton sin avisar (KI-L21).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/update.sh"
    // "schedule" hasta el primer chequeo.
    property string icon: "schedule"
    // Paquetes pendientes (suma de los numeros del tooltip; 0 si esta al dia).
    property int count: 0

    function check(): void {
        proc.running = true;
    }
    function run(): void {
        Quickshell.execDetached(["kitty", "-e", root.script]);
    }

    property Process proc: Process {
        command: [root.script, "data"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    root.icon = data.icon || "sync_problem";
                    const nums = (data.tooltip || "").match(/\d+/g) || [];
                    root.count = root.icon === "download" ? nums.reduce((a, n) => a + Number(n), 0) : 0;
                } catch (e) {
                    root.icon = "sync_problem";
                    root.count = 0;
                }
            }
        }
    }
    property Timer hourly: Timer {
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }
}
