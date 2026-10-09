// Reproductor del dashboard (Fase 4 B7; logica de B5, P4.8): el protagonista
// de Inicio mientras hay un reproductor. La portada domina (216 px, con el
// halo de sus propios colores de B5) y se repite difuminada como fondo de toda
// la zona; el titulo es el texto mas grande del dashboard. Progreso con
// busqueda, cinco controles siempre en el mismo lugar y, con mas de un
// reproductor, chips para elegirlo. Lee y actua sobre MediaState.active (el
// mismo reproductor que la pill y las teclas multimedia).
//
// Cambio de cancion (B5, sin cambios): salida corta de portada y textos,
// entrada con la portada nueva cruzada sobre la vieja cuando ya cargo y los
// textos escalonados; el fondo se cruza con la portada. Sin actividad
// continua: la posicion se refresca cada 500 ms solo visible y sonando; el
// fondo difuminado se calcula una vez por portada (capa en cache).
//
// Estados: sin portada (nota sobre un contenedor tonal), sin artista o sin
// album (la linea no aparece), sin duracion (una leyenda en lugar de la
// barra), con duracion pero sin busqueda (barra sin tirador). Lo que el
// reproductor no admite queda atenuado y al pasar el mouse dice por que.
//
// Teclas (con el foco en el reproductor, via handleKey): Espacio reproduce o
// pausa, izquierda/derecha buscan -/+10 s, N / P siguiente / anterior.
//
// Letra (Fase 12 B1, P12.2): L la abre o la cierra (tambien "Letra", que
// aparece al pasar el raton). Ocupa el lugar del titulo (LyricsView); el
// titulo pasa a la linea del reproductor y, en la de los tiempos, de donde
// viene, "Otra letra" (elegir entre los candidatos de LRCLIB) y el desfase
// (- / +, tambien con [ y ]). LyricsState trabaja solo mientras se ve.
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".." // Colors.qml, Tokens.qml, MediaState.qml, LyricsState.qml

Item {
    id: hero

    // 248 de siempre; con el texto grande (Fase 12: hasta 150 %), lo que pida la columna de texto.
    implicitHeight: Math.max(248, info.implicitHeight + 2 * Tokens.space.lg)

    readonly property var player: MediaState.active
    // Visible de verdad (el dashboard lo liga a su Presence): sin esto sigue
    // "visible" con la ventana oculta y el temporizador correria (KI-L19).
    property bool active: true
    readonly property bool hasLength: !!hero.player && hero.player.lengthSupported && hero.player.length > 0
    readonly property bool canSeek: hero.hasLength && hero.player.canSeek && hero.player.positionSupported
    readonly property string playerName: MediaState.nameOf(hero.player)
    readonly property int coverSize: 216
    // Letra abierta (Fase 12 B1) y la lista de candidatos ("Otra letra").
    readonly property bool lyricsOpen: LyricsState.viewOpen && !!hero.player
    property bool picking: false
    onLyricsOpenChanged: if (!hero.lyricsOpen) hero.picking = false
    Subscription { demand: LyricsState.demand; active: hero.active && hero.lyricsOpen }
    HoverHandler { id: heroHover }

    function fmt(seconds: real): string {
        const s = Math.max(0, Math.round(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const ss = String(s % 60).padStart(2, "0");
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + ss : m + ":" + ss;
    }

    // ---- Pista mostrada (se cambia a mitad de la transicion) ---------------
    readonly property string trackKey: hero.player
        ? [hero.player.trackTitle, hero.player.trackArtist, hero.player.trackAlbum, hero.player.trackArtUrl].join("|") : ""
    property string shownTitle: ""
    property string shownArtist: ""
    property string shownAlbum: ""

    function takeTrack(): void {
        const p = hero.player;
        hero.shownTitle = p ? (p.trackTitle || "Sin título") : "";
        hero.shownArtist = p ? (p.trackArtist || "") : "";
        hero.shownAlbum = p ? (p.trackAlbum || "") : "";
        cover.show(p ? p.trackArtUrl : "");
    }
    onTrackKeyChanged: {
        if (!hero.active || !hero.shownTitle) {
            hero.takeTrack();
            hero.syncPosition(false);
            return;
        }
        trackChange.restart();
    }
    Component.onCompleted: hero.takeTrack()

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
                hero.takeTrack();
                hero.syncPosition(true);
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
        target: hero
        property: "barPos"
        duration: Tokens.motion.short
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.motion.easeStandard
    }
    // animate: true anima el cambio si es un salto (mas de 1,5 s).
    function syncPosition(animate: bool): void {
        const p = hero.player;
        const target = p && hero.hasLength ? Math.max(0, Math.min(p.length, p.position)) : 0;
        if (animate && Math.abs(target - hero.barPos) > 1.5 && Tokens.motion.scale > 0) {
            jumpAnim.to = target;
            jumpAnim.restart();
        } else if (!jumpAnim.running) {
            hero.barPos = target;
        }
    }
    onActiveChanged: {
        if (!hero.active || !hero.player) return;
        // Al abrir: posicion al dia en el acto (antes esperaba 500 ms y saltaba).
        hero.player.positionChanged();
        hero.syncPosition(false);
    }
    Timer {
        interval: 500
        repeat: true
        running: hero.active && !!hero.player && hero.player.isPlaying && hero.player.positionSupported
        onTriggered: {
            hero.player.positionChanged();
            hero.syncPosition(true);
        }
    }
    Connections {
        target: hero.player
        // Busqueda desde otro lado (el propio reproductor, teclas): salto animado.
        function onPositionChanged() {
            if (hero.active && !seekMouse.pressed) hero.syncPosition(true);
        }
    }

    // Texto chico clicable de la linea de la letra.
    component LinkText: Text {
        id: lt
        property bool plain: false
        signal clicked()
        color: lt.plain ? Colors.border : ltMouse.containsMouse ? Colors.text : Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.caption
        font.weight: lt.plain ? Tokens.weight.regular : Tokens.weight.medium
        font.features: Tokens.tabularNumbers
        MouseArea {
            id: ltMouse
            anchors.fill: parent
            enabled: !lt.plain
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: lt.clicked()
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
        // Teclado (N / P): el mismo empujon que el clic.
        function press(): void {
            if (!ctl.usable) return;
            if (ctl.nudge !== 0 && Tokens.motion.scale > 0) nudgeAnim.restart();
            ctl.clicked();
        }
        implicitWidth: ctl.big ? 56 : 40
        implicitHeight: ctl.big ? 56 : 40

        Rectangle {
            id: face
            anchors.fill: parent
            radius: ctl.big ? Tokens.radius.lg : width / 2
            color: ctl.big ? Colors.accent : (ctl.on ? Colors.accentAltContainer : "transparent")
            opacity: ctl.usable ? 1 : 0.35
            scale: ctlMouse.pressed && ctl.usable ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
            Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }
            transform: Translate { id: shove; x: 0 }

            StateLayer {
                hovered: ctlMouse.containsMouse && ctl.usable
                pressed: ctlMouse.pressed && ctl.usable
                contentColor: ctl.big ? Colors.textOnAccent : Colors.text
            }
            Icon {
                anchors.centerIn: parent
                name: ctl.icon
                filled: ctl.big || ctl.on
                size: ctl.big ? Tokens.icon.lg : Tokens.icon.md
                color: ctl.big ? Colors.textOnAccent : (ctl.on ? Colors.textOnAccentAltContainer : Colors.textMuted)
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
                color: ctl.big ? Colors.textOnAccent : Colors.textMuted
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
                if (ctlMouse.containsMouse && !ctl.usable) hero.hint = "No disponible en " + hero.playerName + ": " + ctl.label;
                else if (!ctlMouse.containsMouse && hero.hint.endsWith(ctl.label)) hero.hint = "";
            }
            onClicked: ctl.press()
        }
    }

    function handleKey(event: var): bool {
        const p = hero.player;
        if (!p) return false;
        if (event.key === Qt.Key_Space) {
            if (!event.isAutoRepeat) MediaState.togglePlaying();
        } else if (event.key === Qt.Key_Left) {
            MediaState.seek(p.position - 10);
        } else if (event.key === Qt.Key_Right) {
            MediaState.seek(p.position + 10);
        } else if (event.key === Qt.Key_N) {
            nextCtl.press();
        } else if (event.key === Qt.Key_P) {
            prevCtl.press();
        } else if (event.key === Qt.Key_L) {
            LyricsState.viewOpen = !LyricsState.viewOpen;
        } else if (hero.lyricsOpen && event.key === Qt.Key_BracketLeft) {
            LyricsState.nudge(-0.5);
        } else if (hero.lyricsOpen && event.key === Qt.Key_BracketRight) {
            LyricsState.nudge(0.5);
        } else {
            return false;
        }
        return true;
    }

    // ---- Fondo: la portada difuminada, cruzada con la portada ---------------
    // En una capa: el desenfoque se recalcula solo cuando cambia la portada o
    // su opacidad (el cruce), no en cada cuadro.
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: backdropMask
        }
        Rectangle {
            anchors.fill: parent
            color: Colors.surfaceHigh
        }
        Repeater {
            model: [artA, artB]
            MultiEffect {
                required property Image modelData
                anchors.fill: parent
                visible: modelData.status === Image.Ready
                source: modelData
                opacity: modelData.opacity * 0.75
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                saturation: 0.1
                brightness: -0.2
            }
        }
        // Velo hacia la derecha: el texto siempre sobre una base legible.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Colors.tint(Colors.surfaceHigh, Tokens.opacity.scrimImage / 2) }
                GradientStop { position: 0.3; color: Colors.tint(Colors.surfaceHigh, Tokens.tint.overlay) }
                GradientStop { position: 1.0; color: Colors.tint(Colors.surfaceHigh, Tokens.tint.overlay) }
            }
        }
    }
    Item {
        id: backdropMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: Tokens.radius.md
        }
    }

    // ---- Portada ----------------------------------------------------------------
    // Dos capas que se cruzan cuando la nueva ya cargo (nunca un hueco en
    // blanco), halo con la misma portada detras y borde fino para que una
    // portada muy oscura no se pierda en el fondo.
    Item {
        id: cover
        x: Tokens.space.lg
        anchors.verticalCenter: parent.verticalCenter
        width: hero.coverSize
        height: hero.coverSize
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
            width: parent.width * 1.2
            height: parent.height * 1.2
            source: cover.front
            blurEnabled: true
            blur: 1.0
            blurMax: 48
            saturation: 0.2
            // Tope para portadas muy claras: un halo, no un foco.
            brightness: -0.1
            opacity: 0.5
        }

        // Esquinas redondeadas de verdad (el clip de un Rectangle es recto): capa
        // con mascara, recalculada solo cuando cambia la portada o su cruce.
        Rectangle {
            anchors.fill: parent
            radius: Tokens.radius.lg
            color: Colors.surfaceHighest
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: coverMask
            }

            Icon {
                anchors.centerIn: parent
                visible: !cover.hasArt
                name: "music_note"
                size: Tokens.icon.xl
                color: Colors.textMuted
            }
            Image {
                id: artA
                anchors.fill: parent
                opacity: 0
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(hero.coverSize * 2, hero.coverSize * 2)
                asynchronous: true
                onStatusChanged: if (artA.status === Image.Ready && cover.back === artA) cover.backReady()
            }
            Image {
                id: artB
                anchors.fill: parent
                opacity: 0
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(hero.coverSize * 2, hero.coverSize * 2)
                asynchronous: true
                onStatusChanged: if (artB.status === Image.Ready && cover.back === artB) cover.backReady()
            }
        }
        Item {
            id: coverMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Rectangle {
                anchors.fill: parent
                radius: Tokens.radius.lg
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: Tokens.radius.lg
            color: "transparent"
            border.width: 1
            border.color: Colors.divider
        }
    }

    // ---- Texto, progreso y controles --------------------------------------------
    ColumnLayout {
        id: info
        anchors.left: cover.right
        anchors.leftMargin: Tokens.space.xl
        anchors.right: parent.right
        anchors.rightMargin: Tokens.space.xl
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        // Reproductor: estado + nombre; con mas de uno, chips para elegir.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: Tokens.space.xs
            Icon {
                name: hero.player && hero.player.isPlaying ? "equalizer" : "pause"
                filled: true
                size: Tokens.icon.sm
                color: hero.player && hero.player.isPlaying ? Colors.accent : Colors.textMuted
                Behavior on color { ColorAnimation { duration: Tokens.motion.short } }
            }
            Text {
                Layout.fillWidth: true
                visible: MediaState.players.length <= 1
                // Con la letra abierta, el titulo va aca (su lugar es de la letra).
                text: hero.lyricsOpen ? hero.playerName + " · " + hero.shownTitle + (hero.shownArtist ? " — " + hero.shownArtist : "") : hero.playerName
                color: hero.player && hero.player.isPlaying ? Colors.accent : Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                font.weight: Tokens.weight.semibold
                elide: Text.ElideRight
            }
            Row {
                Layout.fillWidth: true
                visible: MediaState.players.length > 1
                spacing: Tokens.space.xs
                Repeater {
                    model: MediaState.players
                    Rectangle {
                        id: chip
                        required property var modelData
                        readonly property bool on: chip.modelData === hero.player
                        implicitHeight: 26
                        implicitWidth: chipText.implicitWidth + Tokens.space.md * 2
                        radius: 13
                        color: chip.on ? Colors.accentAltContainer : "transparent"
                        border.width: chip.on ? 0 : 1
                        border.color: Colors.divider
                        Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }
                        StateLayer { hovered: chipMouse.containsMouse; pressed: chipMouse.pressed }
                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: MediaState.nameOf(chip.modelData)
                            color: chip.on ? Colors.textOnAccentAltContainer : Colors.textMuted
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.caption
                            font.weight: Tokens.weight.medium
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
            // "Letra": al pasar el raton o con la letra abierta (de fabrica no se ve).
            Rectangle {
                visible: heroHover.hovered || hero.lyricsOpen
                implicitHeight: 26
                implicitWidth: lyrRow.implicitWidth + Tokens.space.md * 2
                radius: 13
                color: hero.lyricsOpen ? Colors.accentAltContainer : "transparent"
                border.width: hero.lyricsOpen ? 0 : 1
                border.color: Colors.divider
                StateLayer { hovered: lyrMouse.containsMouse; pressed: lyrMouse.pressed }
                Row {
                    id: lyrRow
                    anchors.centerIn: parent
                    spacing: Tokens.space.xs
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "lyrics"; size: Tokens.icon.sm; color: hero.lyricsOpen ? Colors.textOnAccentAltContainer : Colors.textMuted }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Letra"
                        color: hero.lyricsOpen ? Colors.textOnAccentAltContainer : Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                        font.weight: Tokens.weight.medium
                    }
                }
                MouseArea {
                    id: lyrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: LyricsState.viewOpen = !LyricsState.viewOpen
                }
            }
        }

        // Letra abierta: en el lugar del titulo, con su mismo alto (el reproductor no cambia de tamano).
        LyricsView {
            visible: hero.lyricsOpen
            Layout.fillWidth: true
            Layout.topMargin: Tokens.space.sm
            Layout.preferredHeight: textBlock.implicitHeight
            canSeek: hero.canSeek
        }
        ColumnLayout {
            id: textBlock
            visible: !hero.lyricsOpen
            Layout.fillWidth: true
            Layout.topMargin: Tokens.space.sm
            spacing: Tokens.space.hair
            property real shift: 0
            transform: Translate { y: textBlock.shift }

            Text {
                id: titleText
                Layout.fillWidth: true
                text: hero.shownTitle
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.displayLarge
                font.weight: Tokens.weight.semibold
                elide: Text.ElideRight
            }
            Text {
                id: artistText
                visible: !!hero.shownArtist
                Layout.fillWidth: true
                text: hero.shownArtist
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.headline
                elide: Text.ElideRight
            }
            Text {
                id: albumText
                visible: !!hero.shownAlbum
                Layout.fillWidth: true
                text: hero.shownAlbum
                color: Colors.border
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                elide: Text.ElideRight
            }
        }

        // Progreso (con duracion) o leyenda (sin duracion).
        Item {
            id: track
            visible: hero.hasLength
            Layout.fillWidth: true
            Layout.topMargin: Tokens.space.lg
            implicitHeight: 16
            readonly property real frac: seekMouse.pressed ? track.dragPos
                : (hero.hasLength ? hero.barPos / hero.player.length : 0)
            property real dragPos: 0

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Colors.tint(Colors.textMuted, Tokens.tint.track)
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * Math.max(0, Math.min(1, track.frac))
                height: 4
                radius: 2
                color: Colors.accent
            }
            Rectangle {
                visible: hero.canSeek
                x: parent.width * Math.max(0, Math.min(1, track.frac)) - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: seekMouse.pressed ? 18 : (seekMouse.containsMouse ? 16 : 14)
                height: width
                radius: width / 2
                color: Colors.accent
                Behavior on width { NumberAnimation { duration: Tokens.motion.fast } }
            }
            MouseArea {
                id: seekMouse
                objectName: "mediaSeek"
                anchors.fill: parent
                anchors.topMargin: -Tokens.space.xs
                anchors.bottomMargin: -Tokens.space.xs
                enabled: hero.canSeek
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => track.dragPos = Math.max(0, Math.min(1, mouse.x / width))
                onPositionChanged: (mouse) => {
                    if (seekMouse.pressed) track.dragPos = Math.max(0, Math.min(1, mouse.x / width));
                }
                onReleased: {
                    const target = track.dragPos * hero.player.length;
                    hero.barPos = target;
                    MediaState.seek(target);
                }
            }
        }
        // Tiempos; en el medio, por que un control esta atenuado (al pasar el
        // mouse) o que no hay busqueda.
        RowLayout {
            visible: hero.hasLength
            Layout.fillWidth: true
            Text {
                text: hero.fmt(track.frac * (hero.player ? hero.player.length : 0))
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                font.features: Tokens.tabularNumbers
            }
            // Con la letra: de donde viene, "Otra letra" y el desfase.
            Row {
                visible: hero.lyricsOpen && !hero.hint
                Layout.fillWidth: true
                spacing: Tokens.space.sm
                LinkText {
                    text: ({ file: "Junto al archivo", folder: "Tu carpeta", cache: "LRCLIB", lrclib: "LRCLIB" })[LyricsState.source] || ""
                    plain: true
                }
                LinkText {
                    visible: LyricsState.online && LyricsState.status !== "searching"
                    text: "Otra letra"
                    onClicked: {
                        hero.picking = true;
                        LyricsState.search();
                    }
                }
                LinkText { visible: LyricsState.synced; text: "−"; onClicked: LyricsState.nudge(-0.5) }
                LinkText {
                    visible: LyricsState.synced
                    plain: true
                    text: (LyricsState.offset > 0 ? "+" : "") + LyricsState.offset.toFixed(1).replace(".", ",") + " s"
                }
                LinkText { visible: LyricsState.synced; text: "+"; onClicked: LyricsState.nudge(0.5) }
            }
            Text {
                visible: !hero.lyricsOpen || !!hero.hint
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: hero.hint || (hero.canSeek ? "" : "sin búsqueda")
                color: hero.hint ? Colors.textMuted : Colors.border
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                elide: Text.ElideRight
            }
            Text {
                text: hero.fmt(hero.player ? hero.player.length : 0)
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                font.features: Tokens.tabularNumbers
            }
        }
        RowLayout {
            visible: !!hero.player && !hero.hasLength
            Layout.fillWidth: true
            Layout.topMargin: Tokens.space.lg
            spacing: Tokens.space.xs
            Icon {
                name: "sensors"
                size: Tokens.icon.sm
                color: Colors.textMuted
            }
            Text {
                Layout.fillWidth: true
                text: hero.hint || "Sin duración · el reproductor no informa el progreso"
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                elide: Text.ElideRight
            }
        }

        // Cinco controles, siempre en el mismo lugar.
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.space.sm
            spacing: Tokens.space.md
            Control {
                icon: "shuffle"
                label: "aleatorio"
                usable: !!hero.player && hero.player.shuffleSupported
                on: !!hero.player && hero.player.shuffleSupported && hero.player.shuffle
                onClicked: MediaState.toggleShuffle()
            }
            Control {
                id: prevCtl
                icon: "skip_previous"
                label: "anterior"
                nudge: -4
                usable: !!hero.player && hero.player.canGoPrevious
                onClicked: MediaState.previous()
            }
            Control {
                big: true
                icon: "play_arrow"
                altIcon: "pause"
                showAlt: !!hero.player && hero.player.isPlaying
                label: "reproducir o pausar"
                usable: !!hero.player && hero.player.canTogglePlaying
                onClicked: MediaState.togglePlaying()
            }
            Control {
                id: nextCtl
                icon: "skip_next"
                label: "siguiente"
                nudge: 4
                usable: !!hero.player && hero.player.canGoNext
                onClicked: MediaState.next()
            }
            Control {
                icon: hero.player && hero.player.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                label: "repetir"
                usable: !!hero.player && hero.player.loopSupported
                on: !!hero.player && hero.player.loopSupported && hero.player.loopState !== MprisLoopState.None
                onClicked: MediaState.cycleLoop()
            }
        }
    }

    // ---- "Otra letra": los candidatos de LRCLIB, sobre la columna de texto ----------------
    Rectangle {
        visible: hero.picking
        anchors.left: cover.right
        anchors.leftMargin: Tokens.space.lg
        anchors.right: parent.right
        anchors.rightMargin: Tokens.space.lg
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.space.md
        radius: Tokens.radius.md
        color: Colors.surfaceHigh
        z: 5
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.space.md
            spacing: Tokens.space.xs
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: LyricsState.searching ? "Buscando…" : LyricsState.candidates.length ? "Elige la letra de esta canción" : "No hay otras"
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                    font.weight: Tokens.weight.semibold
                }
                LinkText { text: "Cerrar"; onClicked: hero.picking = false }
            }
            ListView {
                id: cands
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: LyricsState.candidates
                delegate: Rectangle {
                    id: cand
                    required property var modelData
                    width: cands.width
                    height: Tokens.row.height
                    radius: Tokens.radius.sm
                    color: "transparent"
                    StateLayer { hovered: candMouse.containsMouse; pressed: candMouse.pressed }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.space.sm
                        anchors.rightMargin: Tokens.space.sm
                        spacing: Tokens.space.sm
                        Icon { name: cand.modelData.synced ? "lyrics" : "notes"; size: Tokens.icon.sm; color: Colors.textMuted }
                        Text {
                            Layout.fillWidth: true
                            text: cand.modelData.track + " — " + cand.modelData.artist + (cand.modelData.album ? " · " + cand.modelData.album : "")
                            elide: Text.ElideRight
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                        }
                        Text {
                            text: hero.fmt(cand.modelData.duration || 0)
                            color: Colors.textMuted
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.caption
                            font.features: Tokens.tabularNumbers
                        }
                    }
                    MouseArea {
                        id: candMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            hero.picking = false;
                            LyricsState.choose(cand.modelData.id);
                        }
                    }
                }
            }
        }
    }
}
