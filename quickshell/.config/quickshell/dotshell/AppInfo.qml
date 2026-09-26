// Aplicaciones: nombre legible e icono a partir de lo que se tenga (clase de
// ventana, id de desktop entry, nombre de proceso). Un solo lugar para el
// selector de ventanas, las miniaturas de escritorios, las aplicaciones de
// Sistema, el reproductor, el lanzador y los avisos (Fase 4 B7).
//
// Orden: la desktop entry (por id o con la busqueda heuristica de Quickshell)
// y su icono; si no hay, el icono con el nombre normalizado; si no, el
// generico. "zen" -> Zen Browser / zen-browser (el icono "zen" no existe);
// "zen-bin" (proceso) -> se normaliza a "zen".
//
// Las desktop entries cargan de forma asincrona (KI-L20): al llegar o
// cambiar, "revision" sube y las ligaduras que usan icon() / name() se
// vuelven a evaluar solas.
pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    property int revision: 0
    property var cache: ({})
    property Connections entries: Connections {
        target: DesktopEntries.applications
        function onValuesChanged(): void {
            root.cache = {};
            root.revision++;
        }
    }

    // "zen-bin" -> "zen", "Code" -> "code", "firefox-wrapped" -> "firefox".
    function normalize(name: string): string {
        return (name || "").trim().toLowerCase().replace(/(-bin|\.bin|-wrapped|_wrapper|-launcher)$/, "");
    }
    function entry(name: string): var {
        void root.revision;
        const key = (name || "").trim();
        if (!key) return null;
        if (key in root.cache) return root.cache[key];
        const n = root.normalize(key);
        const e = DesktopEntries.byId(key) || DesktopEntries.heuristicLookup(key)
            || (n !== key ? DesktopEntries.byId(n) || DesktopEntries.heuristicLookup(n) : null) || null;
        root.cache[key] = e;
        return e;
    }
    // Ruta del icono (nunca vacia: al final, el generico).
    function icon(name: string): string {
        const e = root.entry(name);
        const byEntry = e && e.icon ? Quickshell.iconPath(e.icon, true) : "";
        if (byEntry) return byEntry;
        const n = root.normalize(name);
        return (n ? Quickshell.iconPath(n, true) : "") || Quickshell.iconPath("application-x-executable");
    }
    // Icono de una desktop entry que ya se tiene (lanzador).
    function entryIcon(e: var): string {
        return (e && e.icon ? Quickshell.iconPath(e.icon, true) : "") || Quickshell.iconPath("application-x-executable");
    }
    // Procesos sin desktop entry con un nombre conocido (la propia shell).
    readonly property var aliases: ({ qs: "Quickshell", quickshell: "Quickshell", hyprland: "Hyprland" })
    // Nombre legible: el de la entry, sin sufijos entre parentesis
    // ("Spotify (Launcher)" -> "Spotify"); si no hay, un alias conocido o el
    // nombre con mayuscula.
    function name(name: string): string {
        const e = root.entry(name);
        if (e && e.name) return e.name.replace(/\s*\([^)]*\)\s*$/, "");
        const n = root.normalize(name);
        if (root.aliases[n]) return root.aliases[n];
        return n ? n.charAt(0).toUpperCase() + n.slice(1) : "";
    }
}
