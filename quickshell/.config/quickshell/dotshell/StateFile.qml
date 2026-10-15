// Un archivo de estado de la shell (Fase 11 B5): JSON versionado en
// ~/.local/state/dotfiles/ (nunca en el repo ni en el almacen de opciones).
// Lo usan los duenos de los datos de Inicio (NotesState, TodoState), uno por
// archivo.
//
// - Se abre cuando `enabled` pasa a verdadero (el dueno lo liga a su Demand)
//   y se cierra con forget(), que antes guarda lo pendiente.
// - save(obj) guarda 500 ms despues del ultimo cambio (escritura atomica de
//   FileView); flush() guarda ya lo pendiente (al soltar y al destruirse).
// - Un archivo que no se puede leer no se pisa: se copia al lado como
//   <nombre>.bad, se empieza vacio y `problem` lo dice (la zona lo muestra).
// - Una version mas nueva que la que se entiende: solo lectura.
//
// DOTFILES_STATE_DIR cambia la carpeta (pruebas).
//
//   StateFile { id: f; name: "notes.json"; version: 1; enabled: demand.holding }
//   f.data (null = sin archivo todavia), f.save({ version: 1, ... })
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: sf

    property string name: ""
    property int version: 1
    property bool enabled: false
    readonly property string dir: Quickshell.env("DOTFILES_STATE_DIR") || (Quickshell.env("HOME") + "/.local/state/dotfiles")
    readonly property string path: sf.dir + "/" + sf.name

    // Lo leido (o lo ultimo guardado). null = no hay archivo.
    property var data: null
    property bool loaded: false
    property string problem: ""
    property bool readOnly: false
    readonly property bool pending: saveTimer.running

    function save(obj: var): void {
        if (sf.readOnly) return;
        sf.data = obj;
        saveTimer.restart();
    }
    function flush(): void {
        if (!saveTimer.running) return;
        saveTimer.stop();
        sf.write();
    }
    // Al soltar: lo pendiente se guarda y se olvida lo leido.
    function forget(): void {
        sf.flush();
        sf.readOnly = false;
        sf.data = null;
        sf.loaded = false;
        // El archivo se cierra una vuelta despues: cerrarlo en el mismo instante que la
        // escritura de flush() podia perderla (Fase 12 B1; un archivo nuevo, sobre todo).
        Qt.callLater(() => { if (!sf.enabled) sf.opened = false; });
    }
    // Abierto: desde que se pide hasta forget() (no al soltar la Demand, que
    // apaga `enabled` antes de avisar: se perderia lo pendiente).
    property bool opened: false
    onEnabledChanged: if (sf.enabled) sf.opened = true
    Component.onCompleted: if (sf.enabled) sf.opened = true
    function write(): void {
        if (!sf.loaded || sf.readOnly) return;
        sf.file.setText(JSON.stringify(sf.data, null, 1) + "\n");
    }

    property Timer saveTimer: Timer {
        interval: 500
        onTriggered: sf.write()
    }

    property FileView file: FileView {
        path: sf.opened && sf.name ? sf.path : ""
        printErrors: false
        atomicWrites: true
        onLoaded: {
            // Lo propio recien escrito vuelve a cargarse: no pisa lo que se esta editando.
            if (sf.loaded) return;
            let d = null;
            try {
                d = JSON.parse(sf.file.text());
            } catch (e) {
                d = undefined;
            }
            if (!d || typeof d !== "object" || typeof d.version !== "number") {
                Quickshell.execDetached(["cp", "-f", sf.path, sf.path + ".bad"]);
                sf.problem = I18n.tr("Couldn't read %1; it was saved as %1.bad.", sf.name);
                sf.data = null;
            } else if (d.version > sf.version) {
                sf.problem = I18n.tr("%1 is from a newer version: read only.", sf.name);
                sf.readOnly = true;
                sf.data = d;
            } else {
                sf.problem = "";
                sf.data = d;
            }
            sf.loaded = true;
        }
        onLoadFailed: (error) => {
            // Sin archivo todavia: se crea al primer cambio.
            sf.data = null;
            sf.problem = error === FileViewError.FileNotFound ? "" : I18n.tr("Couldn't read %1.", sf.name);
            sf.readOnly = error !== FileViewError.FileNotFound;
            sf.loaded = true;
        }
    }

    Component.onDestruction: sf.flush()
}
