// Colores de las apps (P5.6; contrato LocalPalette de P8.7 §3.4): el acento de
// cada app sale de su icono (el del tema en uso) armonizado con el fondo de
// pantalla, con la misma derivacion que la portada (scripts/local-palette
// --icon). Solo para lo que P8.7 permite: anillos de foco, indicadores, el
// fondito de un icono del tamano de un chip, y el respaldo del reproductor.
//
// Perezoso: accent(app) y compania devuelven el color de la app si ya esta, o
// el del fondo (Colors) mientras tanto, si el icono no sirve (gris, poco
// contraste, se confunde con un estado) o con appearance.appColors apagado.
// Preguntar anota la app; las que faltan van a una cola, de a un proceso. Nada
// corre si nada en pantalla pregunta. Al cambiar el tema se olvida todo y solo
// se recalcula lo que se vuelva a pedir (el script tiene su propia cache).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property bool enabled: SettingsState.value("appearance.appColors") !== false
    readonly property string script: Quickshell.env("LOCAL_PALETTE") || (Quickshell.env("HOME") + "/.config/hypr/scripts/local-palette")
    // Otro fondo, modo o contraste mueven el acento y su texto: se vuelve a derivar.
    // La paleta se cruza animada (motion.theme): se espera a que quede quieta un
    // segundo (stableTheme) antes de olvidar, si no cada cuadro del cruce empezaria de nuevo.
    readonly property string theme: [Colors.accent, Colors.textOnAccent].join("|")
    property string stableTheme: ""
    onThemeChanged: themeSettle.restart()
    property Timer themeSettle: Timer {
        interval: 1000
        onTriggered: {
            if (root.theme === root.stableTheme) return;
            const first = root.stableTheme === "";
            root.stableTheme = root.theme;
            if (!first) root.forget();
        }
    }


    // icono -> paleta (o {valid: false}); rev avisa a los enlaces cuando llega una.
    property var palettes: ({})
    property int rev: 0
    // Cola de iconos por calcular: un arreglo que se cambia en el lugar, sin avisar
    // a nadie (se toca desde los enlaces que preguntan: si avisara, seria un bucle).
    readonly property var queue: []

    function iconOf(app: string): string {
        const e = AppInfo.entry(app);
        return (e && e.icon) || AppInfo.normalize(app);
    }
    function paletteOf(app: string): var {
        void root.rev;
        if (!root.enabled || !app) return null;
        const icon = root.iconOf(app);
        const p = root.palettes[icon];
        if (p === undefined) root.ask(icon);
        return p && p.valid ? p : null;
    }
    function accent(app: string): color {
        const p = root.paletteOf(app);
        return p ? p.accent : Colors.accent;
    }
    function onAccent(app: string): color {
        const p = root.paletteOf(app);
        return p ? p.onAccent : Colors.textOnAccent;
    }
    function container(app: string): color {
        const p = root.paletteOf(app);
        return p ? p.container : Colors.accentContainer;
    }
    function onContainer(app: string): color {
        const p = root.paletteOf(app);
        return p ? p.onContainer : Colors.textOnAccentContainer;
    }
    function has(app: string): bool {
        return !!root.paletteOf(app);
    }

    function ask(icon: string): void {
        // Anotada como pendiente (null, sin avisar): nadie la vuelve a encolar mientras espera o corre.
        root.palettes[icon] = null;
        root.queue.push(icon);
        Qt.callLater(root.next);
    }
    function next(): void {
        if (root.proc.running || root.queue.length === 0) return;
        const icon = root.queue.shift();
        root.proc.icon = icon;
        root.proc.theme = root.stableTheme;
        root.proc.command = [root.script, "--icon", icon];
        root.proc.running = true;
    }
    function forget(): void {
        root.queue.length = 0;
        root.palettes = ({});
        root.rev++;
    }

    property Process proc: Process {
        property string icon: ""
        property string theme: ""
        stdout: StdioCollector { id: out }
        onExited: (code) => {
            // Calculada con un tema anterior: no vale (si se vuelve a pedir, se recalcula).
            // Antes del primer tema quieto ("") vale: el script lee el tema real.
            if (root.proc.theme !== "" && root.proc.theme !== root.stableTheme) { Qt.callLater(root.next); return; }
            let d = null;
            try { d = JSON.parse(out.text); } catch (e) {}
            const p = Object.assign({}, root.palettes);
            p[root.proc.icon] = code === 0 && d ? d : { valid: false };
            root.palettes = p;
            root.rev++;
            Qt.callLater(root.next);
        }
    }
}
