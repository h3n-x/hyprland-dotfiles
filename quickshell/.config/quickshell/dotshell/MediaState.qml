// Reproductor (Fase 4 B5, P4.8): un solo lugar para "que reproductor" y sus
// acciones. Lo usan la pill de la barra (Mpris.qml), el reproductor del
// dashboard (MediaHero.qml, Fase 4 B7) y el IpcHandler "media" de shell.qml
// (teclas multimedia): todos actuan sobre el MISMO reproductor.
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
import Quickshell.Services.Mpris

QtObject {
    id: root

    // Opciones (Fase 10 B4): ignorar los navegadores (media.ignoreBrowsers) y
    // el reproductor preferido (media.preferredPlayer: su desktop entry o su
    // identity, asi sigue valiendo cuando se reabre).
    readonly property bool ignoreBrowsers: SettingsState.value("media.ignoreBrowsers") === true
    readonly property string preferred: SettingsState.value("media.preferredPlayer") || ""
    function isBrowser(p: var): bool {
        return /firefox|chromium|chrome|zen|brave|vivaldi|edge|opera|librewolf|epiphany/i
            .test([p.dbusName, p.desktopEntry, p.identity].join(" "));
    }
    function keyOf(p: var): string {
        return p ? (p.desktopEntry || p.identity || "") : "";
    }
    readonly property var players: Mpris.players.values.filter(p => !(p.dbusName || "").endsWith(".playerctld")
        && !(root.ignoreBrowsers && root.isBrowser(p)))
    // dbusName del reproductor elegido a mano ("" = automatico).
    property string selectedId: ""
    readonly property var active: {
        const ps = root.players;
        if (!ps || ps.length === 0) return null;
        const chosen = ps.find(p => p.dbusName === root.selectedId);
        if (chosen) return chosen;
        const pref = root.preferred ? ps.find(p => root.keyOf(p) === root.preferred) : null;
        if (pref) return pref;
        return ps.find(p => p.isPlaying) || ps[0];
    }

    // Nombre legible: el de la aplicacion ("Zen Browser", "Spotify"), no el
    // identity crudo ("Mozilla zen"). AppInfo: el mismo nombre que en el
    // resto de la shell.
    function nameOf(player: var): string {
        if (!player) return "";
        if (player.desktopEntry && AppInfo.entry(player.desktopEntry)) return AppInfo.name(player.desktopEntry);
        const id = player.identity || "Reproductor";
        return id.charAt(0).toUpperCase() + id.slice(1);
    }

    // Aplicacion (desktop entry) del reproductor, si esta sonando.
    readonly property var playingEntry: root.active && root.active.isPlaying
        ? AppInfo.entry(root.active.desktopEntry || root.active.identity) : null

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
}
