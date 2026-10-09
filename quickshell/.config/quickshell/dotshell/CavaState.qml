// Visualizador de audio (Fase 12 B3, P12.3, D-B3-3): cava como proceso, salida
// cruda en texto (una linea por cuadro, valores separados por ;), mono, 20
// cuadros por segundo (30 costaba mas de 1 % de un nucleo en vivo, D-B3-5),
// media.visualizer.bars barras. Un cuadro igual al anterior (silencio) no se
// vuelve a dibujar. Corre solo mientras
// alguien lo pide (Demand "cava": la pestana Musica visible, sonando, la
// opcion encendida y sin "reducir movimiento"); al soltarlo se detiene y los
// valores vuelven a cero. La configuracion se escribe en XDG_RUNTIME_DIR al
// arrancar (no es un archivo del repo).
// Sin cava instalado no corre nada (available, para que la vista lo diga).
// Pruebas: CAVA_CMD (otro ejecutable), CAVA_CONF (otra ruta).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property int bars: Math.max(32, Math.min(96, SettingsState.value("media.visualizer.bars") || 64))   // barras, no pixeles (px-ok)
    readonly property string cmd: Quickshell.env("CAVA_CMD") || "cava"
    readonly property string conf: Quickshell.env("CAVA_CONF") || ((Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/dotshell-cava.conf")
    // 0..1 por barra; vacio sin proceso.
    property var values: []
    property string last: ""
    // null = sin saber todavia; false = no esta instalado.
    property var available: null
    readonly property bool running: root.proc.running

    property Demand demand: Demand {
        name: "cava"
        onActiveChanged: root.sync()
    }
    onBarsChanged: if (root.proc.running) { root.proc.running = false; root.sync(); }

    function config(): string {
        return ["[general]", "framerate = 20", "bars = " + root.bars, "autosens = 1",
                "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii", "ascii_max_range = 1000",
                "channels = mono", "mono_option = average", "bar_delimiter = 59", "frame_delimiter = 10",
                "[smoothing]", "monstercat = 1", "noise_reduction = 77", ""].join("\n");
    }
    function sync(): void {
        if (!root.demand.active) {
            root.proc.running = false;
            root.values = [];
            return;
        }
        if (root.available === null) {
            root.probe.running = true;
            return;
        }
        if (!root.available || root.proc.running) return;
        root.proc.running = true;
    }

    property Process probe: Process {
        command: ["sh", "-c", "command -v \"$1\" >/dev/null", "sh", root.cmd]
        onExited: (code) => {
            root.available = code === 0;
            root.sync();
        }
    }
    property Process proc: Process {
        // La configuracion se escribe y cava la lee en el mismo arranque (sin carreras).
        command: ["sh", "-c", "printf '%s' \"$1\" > \"$2\" && exec \"$3\" -p \"$2\"", "sh", root.config(), root.conf, root.cmd]
        stdout: SplitParser {
            onRead: (line) => {
                if (line === root.last) return;
                root.last = line;
                const parts = line.split(";");
                const out = [];
                for (const p of parts) {
                    if (p === "") continue;
                    const v = parseInt(p, 10);
                    if (!isNaN(v)) out.push(Math.max(0, Math.min(1, v / 1000)));
                }
                if (out.length) root.values = out;
            }
        }
        onRunningChanged: if (!root.proc.running) { root.values = []; root.last = ""; }
    }
}
