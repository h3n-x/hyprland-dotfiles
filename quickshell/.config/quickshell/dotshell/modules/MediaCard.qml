// Tarjeta del reproductor en Inicio (Fase 12 B2, D-B2-6): portada chica con la
// misma forma, titulo, artista, una linea de progreso y anterior / reproducir
// / siguiente. El reproductor entero (y la letra) esta en la pestana Musica:
// un clic en la tarjeta (fuera de los botones) o L la abren.
// Mismas piezas que la pestana (MediaSession, MediaCover, MediaControls,
// MediaProgress): una sola implementacion. El clic lo da la zona (DashZone:
// la zona "media" tiene la vista "music"), asi crece hacia la pestana.
//
// Teclas (con el foco en la zona): Espacio, izquierda/derecha -/+10 s, N / P,
// L = Musica con la letra.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, LyricsState.qml

Item {
    id: card
    property bool active: false
    signal openMusic()

    implicitHeight: Math.max(Tokens.cover.card, textCol.implicitHeight) + 2 * Tokens.space.md

    MediaSession {
        id: session
        active: card.active
    }
    // El acento de la portada (B4): solo mientras se ve.
    Subscription { demand: MediaColors.demand; active: card.active && !!session.player }

    function handleKey(event: var): bool {
        if (!session.player) return false;
        if (session.handleKey(event)) return true;
        if (event.key === Qt.Key_N) controls.next();
        else if (event.key === Qt.Key_P) controls.previous();
        else if (event.key === Qt.Key_L || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (event.key === Qt.Key_L) LyricsState.viewOpen = true;
            card.openMusic();
        } else return false;
        return true;
    }

    MediaBackdrop {
        anchors.fill: parent
        images: cover.images
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Tokens.space.md
        spacing: Tokens.space.md

        MediaCover {
            id: cover
            Layout.alignment: Qt.AlignVCenter
            session: session
            size: Tokens.cover.card
            halo: false
        }
        ColumnLayout {
            id: textCol
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.space.hair
            opacity: session.textOpacity
            transform: Translate { y: session.textShift }
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.space.xs
                Icon {
                    name: session.playing ? "equalizer" : "pause"
                    filled: true
                    size: Tokens.icon.sm
                    color: session.playing ? Colors.accent : Colors.textMuted
                }
                Text {
                    Layout.fillWidth: true
                    text: session.playerName
                    color: session.playing ? Colors.accent : Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                    font.weight: Tokens.weight.semibold
                    elide: Text.ElideRight
                }
            }
            Text {
                Layout.fillWidth: true
                text: session.title
                opacity: session.titleOpacity
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.headline
                font.weight: Tokens.weight.semibold
                elide: Text.ElideRight
            }
            Text {
                visible: !!session.artist
                Layout.fillWidth: true
                text: session.artist
                opacity: session.artistOpacity
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                elide: Text.ElideRight
            }
            MediaProgress {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.space.xs
                session: session
                thin: true
            }
        }
        MediaControls {
            id: controls
            Layout.alignment: Qt.AlignVCenter
            session: session
            compact: true
        }
    }
}
