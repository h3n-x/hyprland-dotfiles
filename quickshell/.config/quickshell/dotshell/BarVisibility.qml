// Estado compartido de la barra: SUPER+SHIFT+B la muestra/oculta en todas las
// pantallas a la vez (IpcHandler "bar" en shell.qml), en que pantallas va
// (bar.screens) y que modulo marca el editor del centro de configuracion.
pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool hidden: false
    // Modulo marcado en la barra mientras el centro de configuracion lo senala
    // (editor de la disposicion, Fase 11 B1; IPC bar highlight). "" = ninguno.
    property string highlight: ""
    // Pantallas con barra (bar.screens, Fase 11 B1): vacio = todas; si no, el
    // nombre del conector o "desc:<fabricante> <modelo>".
    readonly property var screens: SettingsState.value("bar.screens") || []
    function screenKey(s: var): string {
        const d = [s.manufacturer, s.model].filter(x => x).join(" ");
        return d ? "desc:" + d : s.name;
    }
    // Si un modulo esta en la disposicion (algo que solo el lo necesita no se lee si no esta).
    readonly property var layout: SettingsState.value("bar.layout") || ({})
    function placed(id: string): bool {
        for (const sec of ["start", "center", "end"])
            for (const it of root.layout[sec] || [])
                if (it === id || (it && it.pill && it.pill.indexOf(id) >= 0)) return true;
        return false;
    }
    function onScreen(s: var): bool {
        if (!s || root.screens.length === 0) return true;
        return root.screens.indexOf(s.name) >= 0 || root.screens.indexOf(root.screenKey(s)) >= 0;
    }
}
