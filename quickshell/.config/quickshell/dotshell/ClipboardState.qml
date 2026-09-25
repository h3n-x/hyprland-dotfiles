// Historial del portapapeles (Fase 4 B2) -- mismo patron que PowerState.qml.
// El IpcHandler "clipboard" de shell.qml (SUPER+SHIFT+V) escribe aca,
// Clipboard.qml (una instancia por pantalla) lee de aca.
//
// paused: la pausa del historial (mientras dure, lo copiado no se guarda).
// La guarda scripts/clipboard-store en $XDG_RUNTIME_DIR (en RAM: reiniciar
// siempre la quita); aca solo se refleja, y se relee al abrir.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property bool visible: false
    property string screen: ""
    property bool paused: false

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/clipboard-store"

    function open(): void {
        root.refreshPaused();
        FocusedScreen.request(name => {
            root.screen = name;
            root.visible = true;
        });
    }
    function close(): void {
        root.visible = false;
    }
    function toggle(): void {
        if (root.visible) root.close();
        else root.open();
    }

    function setPaused(on: bool): void {
        root.paused = on;
        Quickshell.execDetached([root.script, on ? "--pause" : "--resume"]);
    }
    function refreshPaused(): void {
        statusProc.running = true;
    }

    property Process statusProc: Process {
        command: [root.script, "--status"]
        stdout: StdioCollector {
            onStreamFinished: root.paused = this.text.trim() === "paused"
        }
    }

    // Vistas previas de una sesion anterior (cierre abrupto): fuera al iniciar.
    Component.onCompleted: {
        Quickshell.execDetached([root.script, "--clean-previews"]);
        root.refreshPaused();
    }
}
