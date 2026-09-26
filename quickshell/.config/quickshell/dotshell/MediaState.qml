// Media hub (Fase 4 B5, P4.8): un solo lugar para "que reproductor" y sus
// acciones. Lo usan la pill de la barra (Mpris.qml), la tarjeta completa
// (MediaCard.qml, en el desplegable y luego en el dashboard) y el IpcHandler
// "media" de shell.qml (teclas multimedia): todos actuan sobre el MISMO
// reproductor.
//
// Reproductor activo: el que eligio el usuario (se mantiene mientras exista);
// si no, el que esta sonando; si no, el primero. Presentacion neutra: nombre
// del reproductor (nombre de su desktop entry, si no identity), sin iconos de
// la app (regla P1.10).
//
// Se ignoran los reproductores "proxy" (playerctld reexpone al reproductor
// activo con otro nombre): mostrarlo duplicaria el mismo reproductor.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

QtObject {
    id: root

    readonly property var players: Mpris.players.values.filter(p => !(p.dbusName || "").endsWith(".playerctld"))
    // dbusName del reproductor elegido a mano ("" = automatico).
    property string selectedId: ""
    readonly property var active: {
        const ps = root.players;
        if (!ps || ps.length === 0) return null;
        const chosen = ps.find(p => p.dbusName === root.selectedId);
        if (chosen) return chosen;
        return ps.find(p => p.isPlaying) || ps[0];
    }

    // Nombre legible: el de la aplicacion ("Zen Browser", "Spotify"), no el
    // identity crudo ("Mozilla zen").
    function nameOf(player: var): string {
        if (!player) return "";
        const entry = player.desktopEntry ? DesktopEntries.byId(player.desktopEntry) : null;
        if (entry && entry.name) return entry.name;
        const id = player.identity || "Reproductor";
        return id.charAt(0).toUpperCase() + id.slice(1);
    }

    function select(player: var): void {
        root.selectedId = player ? player.dbusName : "";
    }

    function togglePlaying(): void {
        const p = root.active;
        if (p && p.canTogglePlaying) p.togglePlaying();
    }
    function next(): void {
        const p = root.active;
        if (p && p.canGoNext) p.next();
    }
    function previous(): void {
        const p = root.active;
        if (p && p.canGoPrevious) p.previous();
    }
    // Segundos desde el inicio; solo si el reproductor lo permite y da duracion.
    function seek(seconds: real): void {
        const p = root.active;
        if (p && p.canSeek && p.positionSupported && p.lengthSupported && p.length > 0)
            p.position = Math.max(0, Math.min(p.length, seconds));
    }
    function toggleShuffle(): void {
        const p = root.active;
        if (p && p.shuffleSupported) p.shuffle = !p.shuffle;
    }
    // Sin repetir -> lista -> pista -> sin repetir.
    function cycleLoop(): void {
        const p = root.active;
        if (!p || !p.loopSupported) return;
        p.loopState = p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
            : p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
    }

    // Desplegable del hub: uno por barra; se abre en la pantalla pedida (la
    // de la pill clickeada o, por IPC, la enfocada).
    property bool hubOpen: false
    property string hubScreen: ""
    function openHub(screenName: string): void {
        if (screenName) {
            root.hubScreen = screenName;
            root.hubOpen = true;
            return;
        }
        FocusedScreen.request(name => {
            root.hubScreen = name;
            root.hubOpen = true;
        });
    }
    function closeHub(): void {
        root.hubOpen = false;
    }
    function toggleHub(screenName: string): void {
        if (root.hubOpen && (!screenName || root.hubScreen === screenName)) root.closeHub();
        else root.openHub(screenName);
    }
}
