// Tarjeta del media hub (Fase 4 B5, P4.8; refinamiento B5-R1..R4): la
// portada es el elemento principal (128 px, con un halo hecho con la misma
// portada difuminada: colores de la portada, calculado una vez por imagen),
// titulo, artista y album, progreso con busqueda, cinco controles siempre en
// el mismo lugar y chips para elegir reproductor. Lee y actua sobre
// MediaState.active (el mismo reproductor que la pill y las teclas
// multimedia). La usa el desplegable de la barra (MediaDropdown.qml).
//
// Cambio de cancion: transicion coordinada en dos tiempos (salida corta de
// portada y textos, entrada con la portada nueva cruzada sobre la vieja
// cuando ya cargo y los textos escalonados). Sin actividad continua: la
// posicion se refresca cada 500 ms solo con la tarjeta visible y sonando, y
// la barra solo se anima en saltos (buscar, cambio de pista). Todas las
// duraciones salen de Tokens.motion (reducir movimiento = instantaneo).
//
// Estados: sin portada (nota sobre un contenedor tonal), sin artista o sin
// album (la linea no aparece), sin duracion (una leyenda en lugar de la
// barra), con duracion pero sin busqueda (barra sin tirador). Lo que el
// reproductor no admite queda atenuado en su lugar y al pasar el mouse dice
// por que.
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".." // Colors.qml, Tokens.qml, MediaState.qml

Item {
    id: card

    readonly property var player: MediaState.active
    // Visible de verdad (el desplegable lo liga a su Presence): sin esto la
    // tarjeta sigue "visible" con la ventana oculta y el temporizador correria.
    property bool active: true
    readonly property bool hasLength: !!card.player && card.player.lengthSupported && card.player.length > 0
    readonly property bool canSeek: card.hasLength && card.player.canSeek && card.player.positionSupported
    readonly property string playerName: MediaState.nameOf(card.player)
    readonly property int coverSize: 128

    implicitWidth: Tokens.panel.widthLg
    implicitHeight: col.implicitHeight

    function fmt(seconds: real): string {
        const s = Math.max(0, Math.round(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const ss = String(s % 60).padStart(2, "0");
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + ss : m + ":" + ss;
    }

    // ---- Pista mostrada (se cambia a mitad de la transicion) ---------------
    readonly property string trackKey: card.player
        ? [card.player.trackTitle, card.player.trackArtist, card.player.trackAlbum, card.player.trackArtUrl].join("|") : ""
    property string shownTitle: ""
    property string shownArtist: ""
    property string shownAlbum: ""

    function takeTrack(): void {
        const p = card.player;
        card.shownTitle = p ? (p.trackTitle || "Sin título") : "";
        card.shownArtist = p ? (p.trackArtist || "") : "";
        card.shownAlbum = p ? (p.trackAlbum || "") : "";
        cover.show(p ? p.trackArtUrl : "");
    }
    onTrackKeyChanged: {
        if (!card.active || !card.shownTitle) {
            card.takeTrack();
            card.syncPosition(false);
            return;
        }
        trackChange.restart();
    }
    Component.onCompleted: card.takeTrack()

    // Salida corta (portada y textos) -> datos nuevos -> entrada escalonada.
    SequentialAnimation {
        id: trackChange
        ParallelAnimation {
            NumberAnimation { target: textBlock; property: "opacity"; to: 0; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeExit }
            NumberAnimation { target: textBlock; property: "shift"; to: -6; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeExit }
            NumberAnimation { target: cover; property: "scale"; to: 0.94; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeExit }
        }
        ScriptAction {
            script: {
                card.takeTrack();
                card.syncPosition(true);
                textBlock.shift = 6;
                titleText.opacity = 0;
                artistText.opacity = 0;
                albumText.opacity = 0;
                textBlock.opacity = 1;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: cover; property: "scale"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            NumberAnimation { target: textBlock; property: "shift"; to: 0; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            NumberAnimation { target: titleText; property: "opacity"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            SequentialAnimation {
                PauseAnimation { duration: Math.round(40 * Tokens.motion.scale) }
                NumberAnimation { target: artistText; property: "opacity"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            }
            SequentialAnimation {
                PauseAnimation { duration: Math.round(80 * Tokens.motion.scale) }
                NumberAnimation { target: albumText; property: "opacity"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            }
        }
    }

    // ---- Posicion: sin saltos al abrir, animada solo en saltos --------------
    property real barPos: 0
    NumberAnimation {
        id: jumpAnim
        target: card
        property: "barPos"
        duration: Tokens.motion.short
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.motion.easeStandard
    }
    // animate: true anima el cambio si es un salto (mas de 1,5 s).
    function syncPosition(animate: bool): void {
        const p = card.player;
        const target = p && card.hasLength ? Math.max(0, Math.min(p.length, p.position)) : 0;
        if (animate && Math.abs(target - card.barPos) > 1.5 && Tokens.motion.scale > 0) {
            jumpAnim.to = target;
            jumpAnim.restart();
        } else if (!jumpAnim.running) {
            card.barPos = target;
        }
    }
    onActiveChanged: {
        if (!card.active || !card.player) return;
        // Al abrir: posicion al dia en el acto (antes esperaba 500 ms y saltaba).
        card.player.positionChanged();
        card.syncPosition(false);
    }
    Timer {
        interval: 500
        repeat: true
        running: card.active && !!card.player && card.player.isPlaying && card.player.positionSupported
        onTriggered: {
            card.player.positionChanged();
            card.syncPosition(true);
        }
    }
    Connections {
        target: card.player
        // Busqueda desde otro lado (el propio reproductor, teclas): salto animado.
        function onPositionChanged() {
            if (card.active && !seekMouse.pressed) card.syncPosition(true);
        }
    }

    // ---- Controles ----------------------------------------------------------
    // Texto de ayuda de un control no disponible (bajo los controles).
    property string hint: ""

    component Control: Item {
        id: ctl
        property string icon
        property string altIcon: ""     // play/pause: los dos iconos se cruzan
        property bool showAlt: false
        property bool on: false
        property bool big: false
        property bool usable: true
        property string label: ""
        property int nudge: 0           // anterior/siguiente: pequeño empujon al usarlo
        signal clicked()
        implicitWidth: ctl.big ? 56 : 40
        implicitHeight: ctl.big ? 56 : 40

        Rectangle {
            id: face
            anchors.fill: parent
            radius: ctl.big ? Tokens.radius.lg : width / 2
            color: ctl.big ? Colors.m3primary : (ctl.on ? Colors.m3secondaryContainer : "transparent")
            opacity: ctl.usable ? 1 : 0.35
            scale: ctlMouse.pressed && ctl.usable ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }
            transform: Translate { id: shove; x: 0 }

            StateLayer {
                hovered: ctlMouse.containsMouse && ctl.usable
                pressed: ctlMouse.pressed && ctl.usable
                contentColor: ctl.big ? Colors.m3onPrimary : Colors.m3onSurface
            }
            Icon {
                anchors.centerIn: parent
                name: ctl.icon
                filled: ctl.big || ctl.on
                size: ctl.big ? Tokens.icon.lg : Tokens.icon.md
                color: ctl.big ? Colors.m3onPrimary : (ctl.on ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant)
                opacity: ctl.altIcon && ctl.showAlt ? 0 : 1
                scale: ctl.altIcon && ctl.showAlt ? 0.6 : 1
                Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }
                Behavior on scale { NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            }
            Icon {
                visible: !!ctl.altIcon
                anchors.centerIn: parent
                name: ctl.altIcon
                filled: true
                size: ctl.big ? Tokens.icon.lg : Tokens.icon.md
                color: ctl.big ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                opacity: ctl.showAlt ? 1 : 0
                scale: ctl.showAlt ? 1 : 0.6
                Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }
                Behavior on scale { NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            }
        }
        SequentialAnimation {
            id: nudgeAnim
            NumberAnimation { target: shove; property: "x"; to: ctl.nudge; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
            NumberAnimation { target: shove; property: "x"; to: 0; duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
        }
        MouseArea {
            id: ctlMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: ctl.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onContainsMouseChanged: {
                if (ctlMouse.containsMouse && !ctl.usable) card.hint = "No disponible en " + card.playerName + ": " + ctl.label;
                else if (!ctlMouse.containsMouse && card.hint.endsWith(ctl.label)) card.hint = "";
            }
            onClicked: {
                if (!ctl.usable) return;
                if (ctl.nudge !== 0 && Tokens.motion.scale > 0) nudgeAnim.restart();
                ctl.clicked();
            }
        }
    }

    // ---- Vista ----------------------------------------------------------------
    ColumnLayout {
        id: col
        width: card.width
        spacing: Tokens.space.md

        // Nada sonando.
        ColumnLayout {
            visible: !card.player
            Layout.fillWidth: true
            Layout.topMargin: Tokens.space.lg
            Layout.bottomMargin: Tokens.space.lg
            spacing: Tokens.space.sm
            Icon {
                Layout.alignment: Qt.AlignHCenter
                name: "music_off"
                size: Tokens.icon.xl
                color: Colors.m3onSurfaceVariant
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "No hay nada reproduciéndose"
                color: Colors.m3onSurfaceVariant
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
            }
        }

        // Reproductores (solo si hay mas de uno): nombre legible, sin iconos de app.
        Flow {
            visible: MediaState.players.length > 1
            Layout.fillWidth: true
            spacing: Tokens.space.xs
            Repeater {
                model: MediaState.players
                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool on: chip.modelData === card.player
                    implicitHeight: 28
                    implicitWidth: chipRow.implicitWidth + Tokens.space.md * 2
                    radius: Tokens.radius.sm
                    color: chip.on ? Colors.m3secondaryContainer : "transparent"
                    border.width: chip.on ? 0 : 1
                    border.color: Colors.m3outlineVariant
                    Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }
                    StateLayer { hovered: chipMouse.containsMouse; pressed: chipMouse.pressed }
                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: Tokens.space.xs
                        Icon {
                            name: chip.modelData.isPlaying ? "equalizer" : "pause"
                            size: Tokens.icon.sm
                            color: chip.on ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                        }
                        Text {
                            text: MediaState.nameOf(chip.modelData)
                            color: chip.on ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            font.weight: Tokens.weight.medium
                        }
                    }
                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaState.select(chip.modelData)
                    }
                }
            }
        }

        RowLayout {
            visible: !!card.player
            Layout.fillWidth: true
            spacing: Tokens.space.lg

            // Portada: dos capas que se cruzan cuando la nueva ya cargo (nunca un
            // hueco en blanco), halo con la misma portada detras y borde fino para
            // que una portada muy oscura no se pierda en el fondo.
            Item {
                id: cover
                Layout.alignment: Qt.AlignTop
                implicitWidth: card.coverSize
                implicitHeight: card.coverSize
                transformOrigin: Item.Center

                property bool frontIsA: true
                readonly property Image front: cover.frontIsA ? artA : artB
                readonly property Image back: cover.frontIsA ? artB : artA
                readonly property bool hasArt: cover.front.status === Image.Ready && cover.front.opacity > 0

                function show(url: string): void {
                    if (url === cover.front.source.toString() && cover.front.status === Image.Ready) return;
                    if (!url) {
                        fade.stop();
                        cover.front.opacity = 0;
                        cover.back.opacity = 0;
                        cover.back.source = "";
                        return;
                    }
                    cover.back.opacity = 0;
                    cover.back.source = url;
                }
                function backReady(): void {
                    fade.stop();
                    fade.target = cover.back;
                    fadeOld.target = cover.front;
                    cover.frontIsA = !cover.frontIsA; // la nueva pasa adelante
                    fade.restart();
                    fadeOld.restart();
                }
                NumberAnimation { id: fade; property: "opacity"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
                NumberAnimation { id: fadeOld; property: "opacity"; to: 0; duration: Tokens.motion.medium }

                // Halo: la portada del frente difuminada (se recalcula solo al cambiar).
                MultiEffect {
                    visible: cover.hasArt
                    anchors.centerIn: parent
                    width: parent.width * 1.3
                    height: parent.height * 1.3
                    source: cover.front
                    blurEnabled: true
                    blur: 1.0
                    blurMax: 48
                    saturation: 0.2
                    // Tope para portadas muy claras: un halo, no un foco.
                    brightness: -0.1
                    opacity: 0.55
                }

                Rectangle {
                    id: coverFrame
                    anchors.fill: parent
                    radius: Tokens.radius.lg
                    color: Colors.m3surfaceContainerHighest
                    clip: true

                    Icon {
                        anchors.centerIn: parent
                        visible: !cover.hasArt
                        name: "music_note"
                        size: Tokens.icon.xl
                        color: Colors.m3onSurfaceVariant
                    }
                    Image {
                        id: artA
                        anchors.fill: parent
                        opacity: 0
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(card.coverSize * 2, card.coverSize * 2)
                        asynchronous: true
                        onStatusChanged: if (artA.status === Image.Ready && cover.back === artA) cover.backReady()
                    }
                    Image {
                        id: artB
                        anchors.fill: parent
                        opacity: 0
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(card.coverSize * 2, card.coverSize * 2)
                        asynchronous: true
                        onStatusChanged: if (artB.status === Image.Ready && cover.back === artB) cover.backReady()
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.radius.lg
                    color: "transparent"
                    border.width: 1
                    border.color: Colors.m3outlineVariant
                }
            }

            ColumnLayout {
                id: textBlock
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Tokens.space.xs
                property real shift: 0
                transform: Translate { y: textBlock.shift }

                Text {
                    id: titleText
                    Layout.fillWidth: true
                    text: card.shownTitle
                    color: Colors.m3onSurface
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.headline
                    font.weight: Tokens.weight.semibold
                    lineHeight: 1.1
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
                Text {
                    id: artistText
                    visible: !!card.shownArtist
                    Layout.fillWidth: true
                    text: card.shownArtist
                    color: Colors.m3onSurfaceVariant
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                    font.weight: Tokens.weight.medium
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    id: albumText
                    visible: !!card.shownAlbum
                    Layout.fillWidth: true
                    text: card.shownAlbum
                    color: Colors.m3outline
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                    elide: Text.ElideRight
                }
            }
        }

        // Progreso (con duracion) o leyenda (sin duracion).
        ColumnLayout {
            visible: !!card.player && card.hasLength
            Layout.fillWidth: true
            spacing: Tokens.space.xs

            Item {
                id: track
                Layout.fillWidth: true
                implicitHeight: 16
                readonly property real frac: seekMouse.pressed ? track.dragPos
                    : (card.hasLength ? card.barPos / card.player.length : 0)
                property real dragPos: 0

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Colors.m3surfaceContainerHighest
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Math.max(0, Math.min(1, track.frac))
                    height: 4
                    radius: 2
                    color: Colors.m3primary
                }
                Rectangle {
                    visible: card.canSeek
                    x: parent.width * Math.max(0, Math.min(1, track.frac)) - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: seekMouse.pressed ? 18 : (seekMouse.containsMouse ? 16 : 14)
                    height: width
                    radius: width / 2
                    color: Colors.m3primary
                    Behavior on width { NumberAnimation { duration: Tokens.motion.fast } }
                }
                MouseArea {
                    id: seekMouse
                    objectName: "mediaSeek"
                    anchors.fill: parent
                    anchors.topMargin: -Tokens.space.xs
                    anchors.bottomMargin: -Tokens.space.xs
                    enabled: card.canSeek
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => track.dragPos = Math.max(0, Math.min(1, mouse.x / width))
                    onPositionChanged: (mouse) => {
                        if (seekMouse.pressed) track.dragPos = Math.max(0, Math.min(1, mouse.x / width));
                    }
                    onReleased: {
                        const target = track.dragPos * card.player.length;
                        card.barPos = target;
                        MediaState.seek(target);
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: card.fmt(track.frac * (card.player ? card.player.length : 0))
                    color: Colors.m3onSurfaceVariant
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                    font.features: Tokens.tabularNumbers
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: !card.canSeek
                    text: "sin búsqueda"
                    color: Colors.m3outline
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                }
                Item { Layout.fillWidth: true; visible: !card.canSeek }
                Text {
                    text: card.fmt(card.player ? card.player.length : 0)
                    color: Colors.m3onSurfaceVariant
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                    font.features: Tokens.tabularNumbers
                }
            }
        }
        RowLayout {
            visible: !!card.player && !card.hasLength
            Layout.fillWidth: true
            spacing: Tokens.space.xs
            Icon {
                name: "sensors"
                size: Tokens.icon.sm
                color: Colors.m3onSurfaceVariant
            }
            Text {
                Layout.fillWidth: true
                text: "Sin duración · el reproductor no informa el progreso"
                color: Colors.m3onSurfaceVariant
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                elide: Text.ElideRight
            }
        }

        // Cinco controles, siempre en el mismo lugar.
        RowLayout {
            visible: !!card.player
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.space.md
            Control {
                icon: "shuffle"
                label: "aleatorio"
                usable: !!card.player && card.player.shuffleSupported
                on: !!card.player && card.player.shuffleSupported && card.player.shuffle
                onClicked: MediaState.toggleShuffle()
            }
            Control {
                icon: "skip_previous"
                label: "anterior"
                nudge: -4
                usable: !!card.player && card.player.canGoPrevious
                onClicked: MediaState.previous()
            }
            Control {
                big: true
                icon: "play_arrow"
                altIcon: "pause"
                showAlt: !!card.player && card.player.isPlaying
                label: "reproducir o pausar"
                usable: !!card.player && card.player.canTogglePlaying
                onClicked: MediaState.togglePlaying()
            }
            Control {
                icon: "skip_next"
                label: "siguiente"
                nudge: 4
                usable: !!card.player && card.player.canGoNext
                onClicked: MediaState.next()
            }
            Control {
                icon: card.player && card.player.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                label: "repetir"
                usable: !!card.player && card.player.loopSupported
                on: !!card.player && card.player.loopSupported && card.player.loopState !== MprisLoopState.None
                onClicked: MediaState.cycleLoop()
            }
        }

        // Por que un control esta atenuado (al pasar el mouse).
        Text {
            visible: !!card.player
            Layout.fillWidth: true
            Layout.preferredHeight: card.hint ? implicitHeight : 0
            horizontalAlignment: Text.AlignHCenter
            text: card.hint
            opacity: card.hint ? 1 : 0
            color: Colors.m3onSurfaceVariant
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
            Behavior on opacity { NumberAnimation { duration: Tokens.motion.fast } }
        }
    }
}
