// Pestana Musica del dashboard (Fase 12 B2, P12.2 / P12.4): portada con
// forma (media.cover.shape) y un anillo libre alrededor para las barras de
// B3 · el reproductor (titulo, artista, album, progreso, controles, chips con
// mas de uno) · la letra en su columna (B1; solo aca, D-R-3). Sin fondo propio
// (B4: ni portada difuminada ni halo). Angosta: portada y reproductor lado a lado, la letra
// debajo.
//
// Sin nada sonando la pestana queda (un lugar fijo) y lo dice; no corre nada.
// Barras de audio alrededor de la portada (B3, media.visualizer.*): cava corre
// solo mientras la pestana se ve y suena (CavaState).
// Con algo sonando: la posicion cada 500 ms (MediaSession) y el temporizador
// de la letra (LyricsState), solo mientras la pestana se ve.
//
// Teclas: Espacio, izquierda/derecha -/+10 s, N / P, L muestra u oculta la
// letra, [ ] (o - +) corrigen su desfase.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, MediaState.qml, LyricsState.qml

Item {
    id: tab
    property bool active: false
    property bool narrow: false

    readonly property bool hasPlayer: !!session.player
    readonly property bool lyricsShown: LyricsState.viewOpen && tab.hasPlayer
    property bool picking: false
    onLyricsShownChanged: if (!tab.lyricsShown) tab.picking = false
    readonly property string hint: controls.hint
    // Anillo libre alrededor de la portada (las barras de B3).
    readonly property int ring: Tokens.space.xl
    readonly property int coverBox: Tokens.cover.music + 2 * tab.ring
    // Letra al lado solo si entran portada, reproductor (un minimo) y letra;
    // si no (pantalla angosta, interfaz grande), la letra va debajo.
    readonly property bool stacked: tab.narrow
        || tab.width < tab.coverBox + Tokens.px(240) + Tokens.panel.widthMd + 2 * Tokens.space.lg + 2 * Tokens.space.lg

    implicitHeight: !tab.hasPlayer ? Tokens.px(240)
        : tab.stacked ? top.implicitHeight + (tab.lyricsShown ? Tokens.space.md + Tokens.px(220) : 0) + 2 * Tokens.space.lg
        : Math.max(tab.coverBox, details.implicitHeight) + 2 * Tokens.space.lg

    MediaSession {
        id: session
        active: tab.active
    }
    Subscription { demand: LyricsState.demand; active: tab.active && tab.lyricsShown }
    // El acento de la portada (B4): solo mientras se ve.
    Subscription { demand: MediaColors.demand; active: tab.active && tab.hasPlayer }
    // Visualizador (Fase 12 B3): solo visible, sonando, con la opcion y sin "reducir movimiento".
    readonly property bool barsOn: SettingsState.value("media.visualizer.enabled") === true && Tokens.motion.scale > 0
    Subscription { demand: CavaState.demand; active: tab.active && tab.barsOn && session.playing }

    function handleKey(event: var): bool {
        if (!tab.hasPlayer) return false;
        if (session.handleKey(event)) return true;
        if (event.key === Qt.Key_N) controls.next();
        else if (event.key === Qt.Key_P) controls.previous();
        else if (event.key === Qt.Key_L) LyricsState.viewOpen = !LyricsState.viewOpen;
        else if (tab.lyricsShown && (event.key === Qt.Key_BracketLeft || event.key === Qt.Key_Minus)) LyricsState.nudge(-0.5);
        else if (tab.lyricsShown && (event.key === Qt.Key_BracketRight || event.key === Qt.Key_Plus)) LyricsState.nudge(0.5);
        else if (tab.picking && event.key === Qt.Key_Escape) tab.picking = false;
        else return false;
        return true;
    }

    // Texto chico clicable (pie de la letra).
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

    // ---- Nada suena -----------------------------------------------------------------
    ColumnLayout {
        visible: !tab.hasPlayer
        anchors.centerIn: parent
        spacing: Tokens.space.sm
        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: "music_off"
            size: Tokens.icon.xl
            color: Colors.textMuted
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: I18n.tr("Nothing playing")
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.headline
            font.weight: Tokens.weight.semibold
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: I18n.tr("When a player starts, it shows up here with its lyrics.")
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
        }
    }

    // ---- Portada + reproductor (+ letra al lado si hay lugar) ---------------------
    RowLayout {
        id: top
        visible: tab.hasPlayer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.space.lg
        height: tab.stacked ? implicitHeight : parent.height - 2 * Tokens.space.lg
        spacing: Tokens.space.lg

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: tab.stacked ? Tokens.cover.music * 0.7 : tab.coverBox
            implicitHeight: implicitWidth
            // Barras de audio alrededor (B3): en el anillo libre y un poco mas
            // (el margen de la pestana), detras de la portada.
            CoverBars {
                anchors.fill: parent
                outline: cover.outline
                ring: (tab.stacked ? 0 : tab.ring) + Tokens.space.md
            }
            MediaCover {
                id: cover
                anchors.centerIn: parent
                session: session
                // Sin halo ni fondo difuminado (pedido del usuario, B4): la portada
                // con su forma y las barras sobre el color de siempre.
                halo: false
                size: tab.stacked ? Math.round(Tokens.cover.music * 0.7) : Tokens.cover.music
            }
        }

        // Reproductor.
        ColumnLayout {
            id: details
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            // Reproductor: estado + nombre; con mas de uno, chips para elegir.
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.control.sm
                spacing: Tokens.space.xs
                Icon {
                    name: session.playing ? "equalizer" : "pause"
                    filled: true
                    size: Tokens.icon.sm
                    color: session.playing ? Colors.accent : Colors.textMuted
                    Behavior on color { ColorAnimation { duration: Tokens.motion.short } }
                }
                Text {
                    Layout.fillWidth: true
                    visible: MediaState.players.length <= 1
                    text: session.playerName
                    color: session.playing ? Colors.accent : Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                    font.weight: Tokens.weight.semibold
                    elide: Text.ElideRight
                }
                Flow {
                    Layout.fillWidth: true
                    visible: MediaState.players.length > 1
                    spacing: Tokens.space.xs
                    Repeater {
                        model: MediaState.players
                        Rectangle {
                            id: chip
                            required property var modelData
                            readonly property bool on: chip.modelData === session.player
                            implicitHeight: Tokens.px(26)
                            implicitWidth: chipText.implicitWidth + Tokens.space.md * 2
                            radius: height / 2
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
                // Letra: mostrar u ocultar su columna (tambien L).
                Rectangle {
                    implicitHeight: Tokens.px(26)
                    implicitWidth: lyrRow.implicitWidth + Tokens.space.md * 2
                    radius: height / 2
                    color: tab.lyricsShown ? Colors.accentAltContainer : "transparent"
                    border.width: tab.lyricsShown ? 0 : 1
                    border.color: Colors.divider
                    StateLayer { hovered: lyrMouse.containsMouse; pressed: lyrMouse.pressed }
                    Row {
                        id: lyrRow
                        anchors.centerIn: parent
                        spacing: Tokens.space.xs
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: "lyrics"; size: Tokens.icon.sm; color: tab.lyricsShown ? Colors.textOnAccentAltContainer : Colors.textMuted }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.tr("Lyrics")
                            color: tab.lyricsShown ? Colors.textOnAccentAltContainer : Colors.textMuted
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

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.space.sm
                spacing: Tokens.space.hair
                opacity: session.textOpacity
                transform: Translate { y: session.textShift }
                Text {
                    Layout.fillWidth: true
                    text: session.title
                    opacity: session.titleOpacity
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.displayLarge
                    font.weight: Tokens.weight.semibold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    visible: !!session.artist
                    Layout.fillWidth: true
                    text: session.artist
                    opacity: session.artistOpacity
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.headline
                    elide: Text.ElideRight
                }
                Text {
                    visible: !!session.album
                    Layout.fillWidth: true
                    text: session.album
                    opacity: session.albumOpacity
                    color: Colors.border
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                    elide: Text.ElideRight
                }
            }

            MediaProgress {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.space.lg
                session: session
                hint: tab.hint || (tab.barsOn && CavaState.available === false ? I18n.tr("No cava: install it to see the bars") : "")
            }
            MediaControls {
                id: controls
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.space.sm
                session: session
            }
        }

        // Letra al lado (ancho).
        Loader {
            Layout.fillHeight: true
            Layout.preferredWidth: Tokens.panel.widthMd
            active: !tab.stacked && tab.lyricsShown
            visible: active
            sourceComponent: lyricsC
        }
    }
    // Letra debajo (angosto).
    Loader {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: top.bottom
        anchors.margins: Tokens.space.lg
        anchors.topMargin: Tokens.space.md
        height: Tokens.px(220)
        active: tab.stacked && tab.lyricsShown
        visible: active
        sourceComponent: lyricsC
    }

    // ---- La columna de la letra -------------------------------------------------------
    Component {
        id: lyricsC
        Rectangle {
            radius: Tokens.radius.md
            color: Colors.tint(Colors.surfaceHighest, Tokens.tint.well)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.space.md
                spacing: Tokens.space.sm
                LyricsView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    canSeek: session.canSeek
                }
                // De donde viene, "Otra letra" y el desfase.
                Row {
                    Layout.fillWidth: true
                    spacing: Tokens.space.sm
                    LinkText {
                        text: ({ file: I18n.tr("Next to the file"), folder: I18n.tr("Your folder"), cache: "LRCLIB", lrclib: "LRCLIB" })[LyricsState.source] || ""
                        plain: true
                    }
                    LinkText {
                        visible: LyricsState.online && LyricsState.status !== "searching"
                        text: I18n.tr("Other lyrics")
                        onClicked: {
                            tab.picking = true;
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
            }

            // "Otra letra": los candidatos de LRCLIB, sobre la columna.
            Rectangle {
                visible: tab.picking
                anchors.fill: parent
                radius: Tokens.radius.md
                color: Colors.surfaceHigh
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.space.md
                    spacing: Tokens.space.xs
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: LyricsState.searching ? I18n.tr("Searching…") : LyricsState.candidates.length ? I18n.tr("Choose the lyrics for this song") : I18n.tr("No others")
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            font.weight: Tokens.weight.semibold
                            elide: Text.ElideRight
                        }
                        LinkText { text: I18n.tr("Close"); onClicked: tab.picking = false }
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
                                    text: session.fmt(cand.modelData.duration || 0)
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
                                    tab.picking = false;
                                    LyricsState.choose(cand.modelData.id);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
