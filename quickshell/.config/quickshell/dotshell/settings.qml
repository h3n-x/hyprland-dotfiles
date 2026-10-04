// Centro de configuracion (Fase 10 B1, P10.1-P10.2): una instancia de
// Quickshell aparte de la shell (`qs -p ~/.config/quickshell/dotshell/settings.qml`),
// como el bloqueo: cerrada no hay proceso, y reiniciar la shell (las opciones
// que lo piden) no la cierra. Vive en la carpeta de dotshell para compartir
// Tokens, Colors, SettingsState y los controles sin copiarlos; no vigila
// archivos (settings.watchFiles: false). No usa servicios que sondeen, vayan
// a la red o tomen un nombre de DBus (lo comprueba la prueba de la suite):
// solo SettingsState (lee la cache efectiva, escribe por scripts/settings).
//
// La lanza scripts/settings-ui (unica entrada: S+I, el engranaje del centro
// de control, `settings-ui open <pagina|clave>`): con la ventana abierta le
// pasa el destino por IPC (`settingsui open`), si no la arranca con
// SETTINGS_UI_OPEN. Cerrar la ventana (o Esc) termina el proceso.
import QtQuick
import Quickshell
import Quickshell.Io
import "settings"

ShellRoot {
    id: root
    settings.watchFiles: false

    // Reducir movimiento: la misma opcion que la shell.
    Binding {
        target: Tokens.motion
        property: "scale"
        value: SettingsState.value("accessibility.reduceMotion") ? 0 : 1
    }

    FloatingWindow {
        id: window
        title: "Configuración"
        implicitWidth: 1100
        implicitHeight: 720
        minimumSize: Qt.size(900, 560)
        visible: true
        color: Colors.surfaceLowest
        onClosed: Qt.quit()

        SettingsWindow {
            id: view
            anchors.fill: parent
            onCloseRequested: Qt.quit()
            Component.onCompleted: Qt.callLater(() => view.open(Quickshell.env("SETTINGS_UI_OPEN") || ""))
        }
    }

    IpcHandler {
        target: "settingsui"
        // Lleva a una pagina o a una opcion; "" = solo traer la ventana.
        function open(target: string): bool {
            return view.open(target);
        }
        function close(): void {
            Qt.quit();
        }
        // Para las pruebas: pagina actual y opcion iluminada.
        function status(): string {
            return JSON.stringify({ page: view.page, highlight: view.highlightKey });
        }
    }
}
