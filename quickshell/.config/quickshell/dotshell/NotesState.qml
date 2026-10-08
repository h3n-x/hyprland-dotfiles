// La nota de Inicio (Fase 11 B5, P11.6): una sola nota de texto plano en
// ~/.local/state/dotfiles/notes.json (version 1: text, updated). La zona
// Notas la pide mientras se ve; se guarda 500 ms despues de dejar de
// escribir y, 1 minuto despues de cerrar el dashboard, se suelta.
pragma Singleton
import QtQuick

QtObject {
    id: root

    property Demand demand: Demand {
        name: "notes"
        idleRelease: 60000
        onReleased: root.file.forget()
    }
    property StateFile file: StateFile {
        name: "notes.json"
        enabled: root.demand.holding
    }

    readonly property bool loaded: root.file.loaded
    readonly property string text: root.file.data && typeof root.file.data.text === "string" ? root.file.data.text : ""
    readonly property real updated: root.file.data && root.file.data.updated ? root.file.data.updated : 0
    readonly property bool saving: root.file.pending
    readonly property string problem: root.file.problem
    readonly property bool readOnly: root.file.readOnly

    function setText(t: string): void {
        if (!root.file.loaded || t === root.text) return;
        root.file.save({ version: 1, text: t, updated: Date.now() });
    }
}
