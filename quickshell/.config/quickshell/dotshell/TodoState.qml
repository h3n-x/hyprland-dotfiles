// Las tareas de Inicio (Fase 11 B5, P11.6): una lista simple en
// ~/.local/state/dotfiles/todo.json (version 1: items, cada una con id, text,
// done, created y doneAt), sin fechas ni prioridades (D-B5-2). La zona Tareas la
// pide mientras se ve; cada cambio se guarda 500 ms despues.
pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property int maxItems: 200

    property Demand demand: Demand {
        name: "todo"
        idleRelease: 60000
        onReleased: root.file.forget()
    }
    property StateFile file: StateFile {
        name: "todo.json"
        enabled: root.demand.holding
    }

    readonly property bool loaded: root.file.loaded
    readonly property var items: root.file.data && Array.isArray(root.file.data.items) ? root.file.data.items.filter(i => i && typeof i.text === "string") : []
    readonly property var open: root.items.filter(i => !i.done)
    readonly property var done: root.items.filter(i => i.done).sort((a, b) => (b.doneAt || 0) - (a.doneAt || 0))
    readonly property string problem: root.file.problem
    readonly property bool readOnly: root.file.readOnly

    function put(items: var): void {
        if (root.file.loaded) root.file.save({ version: 1, items: items });
    }
    function add(text: string): bool {
        const t = text.trim();
        if (!t || root.items.length >= root.maxItems) return false;
        const id = Date.now().toString(36) + Math.floor(Math.random() * 1296).toString(36);
        root.put(root.items.concat([{ id: id, text: t, done: false, created: Date.now(), doneAt: 0 }]));
        return true;
    }
    function toggle(id: string): void {
        root.put(root.items.map(i => i.id === id ? Object.assign({}, i, { done: !i.done, doneAt: i.done ? 0 : Date.now() }) : i));
    }
    function remove(id: string): void {
        root.put(root.items.filter(i => i.id !== id));
    }
    function clearDone(): void {
        root.put(root.items.filter(i => !i.done));
    }
}
