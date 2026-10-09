// Estado compartido de la barra: SUPER+SHIFT+B la muestra/oculta en todas las
// pantallas a la vez (IpcHandler "bar" en shell.qml), en que pantallas va
// (bar.screens) y que modulo marca el editor del centro de configuracion.
pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool hidden: false
    // Super mantenido (bar.peek, Fase 11 B3b): lo pone el GlobalShortcut de shell.qml.
    // La barra se ve (peekShown) recien si se mantiene bar.peekDelay ms: un atajo
    // rapido con Super no la hace aparecer; al soltar se va enseguida.
    property bool peekHeld: false
    property bool peekShown: false
    onPeekHeldChanged: {
        if (root.peekHeld) peekTimer.restart();
        else { peekTimer.stop(); root.peekShown = false; }
    }
    property Timer peekTimer: Timer {
        interval: Math.max(0, SettingsState.value("bar.peekDelay") ?? 250)
        onTriggered: root.peekShown = root.peekHeld
    }
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

    // ---- Marco (Fase 13): un solo lugar para "cuanto mide cada borde" -------------------
    // La barra se ve de verdad (oculta o asomando con bar.peek, su lado es un lado fino).
    readonly property bool barSeen: !root.hidden && SettingsState.value("bar.peek") !== true
    function edgeSize(side: string): int {
        return side === Tokens.bar.edge && root.barSeen ? Tokens.bar.height : Tokens.frame.thickness;
    }
    // Esa pantalla tiene el marco ahora: estilo Marco, con barra, y sin una ventana a
    // pantalla completa (ahi Hyprland no muestra el marco: lo que aparece encima,
    // como el OSD o un aviso, vuelve a flotar).
    function framed(s: var): bool {
        return Tokens.frame.on && !!s && root.onScreen(s) && !FullscreenState.isFullscreen(s.name);
    }
}
