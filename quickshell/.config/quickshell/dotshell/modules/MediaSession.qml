// La cancion mostrada por una vista del reproductor (Fase 12 B2; logica de
// P4 B5 que antes vivia en MediaHero): la pestana Musica y la tarjeta de
// Inicio tienen una cada una. Lee MediaState.active (el mismo reproductor que
// la pill y las teclas multimedia).
//
// Cambio de cancion: salida corta (textos y portada) -> datos nuevos ->
// entrada escalonada (titulo, artista, album). Las vistas se ligan a
// textOpacity / textShift / titleOpacity... / coverScale; la portada cruza la
// imagen nueva sobre la vieja cuando ya cargo (MediaCover).
//
// Posicion: al dia en el acto al mostrarse, cada 500 ms solo mientras se ve y
// suena (KI-L19: active = visible de verdad), animada solo en saltos.
import QtQuick
import ".." // Tokens.qml, MediaState.qml

Item {
    id: s
    visible: false

    property bool active: true
    // La barra de progreso arrastrandose: no la pisan los avisos de posicion.
    property bool dragging: false

    readonly property var player: MediaState.active
    readonly property bool hasLength: !!s.player && s.player.lengthSupported && s.player.length > 0
    readonly property bool canSeek: s.hasLength && s.player.canSeek && s.player.positionSupported
    readonly property bool playing: !!s.player && s.player.isPlaying
    readonly property string playerName: MediaState.nameOf(s.player)

    function fmt(seconds: real): string {
        const t = Math.max(0, Math.round(seconds));
        const h = Math.floor(t / 3600);
        const m = Math.floor((t % 3600) / 60);
        const ss = String(t % 60).padStart(2, "0");
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + ss : m + ":" + ss;
    }

    // ---- Pista mostrada (se cambia a mitad de la transicion) ---------------
    readonly property string trackKey: s.player
        ? [s.player.trackTitle, s.player.trackArtist, s.player.trackAlbum, s.player.trackArtUrl].join("|") : ""
    property string title: ""
    property string artist: ""
    property string album: ""
    property string art: ""
    // Cuenta los cambios de cancion animados (la portada gira su forma con cada uno).
    property int changes: 0

    property real textOpacity: 1
    property real textShift: 0
    property real titleOpacity: 1
    property real artistOpacity: 1
    property real albumOpacity: 1
    property real coverScale: 1

    function take(): void {
        const p = s.player;
        s.title = p ? (p.trackTitle || "Sin título") : "";
        s.artist = p ? (p.trackArtist || "") : "";
        s.album = p ? (p.trackAlbum || "") : "";
        s.art = p ? (p.trackArtUrl || "") : "";
    }
    onTrackKeyChanged: {
        if (!s.active || !s.title || Tokens.motion.scale === 0) {
            trackChange.stop();
            s.take();
            s.syncPosition(false);
            return;
        }
        trackChange.restart();
    }
    Component.onCompleted: s.take()

    SequentialAnimation {
        id: trackChange
        ParallelAnimation {
            NumberAnimation { target: s; property: "textOpacity"; to: 0; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeExit }
            NumberAnimation { target: s; property: "textShift"; to: -6; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeExit }
            NumberAnimation { target: s; property: "coverScale"; to: 0.94; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeExit }
        }
        ScriptAction {
            script: {
                s.take();
                s.changes++;
                s.syncPosition(true);
                s.textShift = 6;
                s.titleOpacity = 0;
                s.artistOpacity = 0;
                s.albumOpacity = 0;
                s.textOpacity = 1;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: s; property: "coverScale"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            NumberAnimation { target: s; property: "textShift"; to: 0; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            NumberAnimation { target: s; property: "titleOpacity"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            SequentialAnimation {
                PauseAnimation { duration: Math.round(40 * Tokens.motion.scale) }
                NumberAnimation { target: s; property: "artistOpacity"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            }
            SequentialAnimation {
                PauseAnimation { duration: Math.round(80 * Tokens.motion.scale) }
                NumberAnimation { target: s; property: "albumOpacity"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            }
        }
    }

    // ---- Posicion -------------------------------------------------------------
    property real barPos: 0
    NumberAnimation {
        id: jumpAnim
        target: s
        property: "barPos"
        duration: Tokens.motion.short
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.motion.easeStandard
    }
    // animate: true anima el cambio si es un salto (mas de 1,5 s).
    function syncPosition(animate: bool): void {
        const p = s.player;
        const target = p && s.hasLength ? Math.max(0, Math.min(p.length, p.position)) : 0;
        if (animate && Math.abs(target - s.barPos) > 1.5 && Tokens.motion.scale > 0) {
            jumpAnim.to = target;
            jumpAnim.restart();
        } else if (!jumpAnim.running) {
            s.barPos = target;
        }
    }
    function seek(seconds: real): void {
        s.barPos = seconds;
        MediaState.seek(seconds);
    }
    onActiveChanged: {
        if (!s.active || !s.player) return;
        // Al mostrarse: posicion al dia en el acto (no espera 500 ms ni salta).
        s.player.positionChanged();
        s.syncPosition(false);
    }
    Timer {
        interval: 500
        repeat: true
        running: s.active && s.playing && s.player.positionSupported
        onTriggered: {
            s.player.positionChanged();
            s.syncPosition(true);
        }
    }
    Connections {
        target: s.player
        // Busqueda desde otro lado (el propio reproductor, teclas): salto animado.
        function onPositionChanged() {
            if (s.active && !s.dragging) s.syncPosition(true);
        }
    }

    // Teclas comunes (Espacio, izquierda/derecha); N y P las maneja cada vista
    // (con el empujon de su boton).
    function handleKey(event: var): bool {
        const p = s.player;
        if (!p) return false;
        if (event.key === Qt.Key_Space) {
            if (!event.isAutoRepeat) MediaState.togglePlaying();
        } else if (event.key === Qt.Key_Left) {
            MediaState.seek(p.position - 10);
        } else if (event.key === Qt.Key_Right) {
            MediaState.seek(p.position + 10);
        } else {
            return false;
        }
        return true;
    }
}
