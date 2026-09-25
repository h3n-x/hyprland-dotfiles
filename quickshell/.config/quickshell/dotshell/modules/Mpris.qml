// Reemplaza a waybar/modules/mpris.jsonc. Solo se muestra si hay un
// reproductor MPRIS activo (Spotify via spicetify, navegador, etc.).
// Presentacion neutra: mismo icono Material Symbols para cualquier
// reproductor, sin iconos dependientes de la app (desktop entry).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml
import Quickshell.Services.Mpris

Item {
    id: root
    readonly property var player: Mpris.players.values[0] ?? null
    // Condicion de datos para el Pill contenedor (ver Bar.qml). No usar
    // "visible" para eso: en QML visible es la visibilidad EFECTIVA -- si el
    // Pill arranca oculto (la lista de reproductores llega unos ms despues
    // del arranque), el hijo reporta false por tener al padre oculto y el
    // Pill no vuelve a mostrarse nunca (deadlock).
    readonly property bool active: !!root.player
    visible: root.active

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // RowLayout (no Row) a proposito: el icono (16px) y el texto (13px)
    // tienen alturas distintas, y Row no deja usar Layout.alignment /
    // anchors por hijo para centrarlos -- ver el mismo problema que se
    // encontro y se corrigio en Volume.qml.
    RowLayout {
        id: row
        spacing: Tokens.gap.inline

        Icon {
            Layout.alignment: Qt.AlignVCenter
            name: "music_note"
            size: Tokens.icon.sm
        }

        Icon {
            Layout.alignment: Qt.AlignVCenter
            name: root.player && root.player.isPlaying ? "play_arrow" : "pause"
            filled: true
            size: Tokens.icon.sm
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            color: Colors.m3onSurface
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
            font.weight: Tokens.weight.medium
            // Solo el titulo -- sin artista, a pedido del usuario.
            text: root.player ? (root.player.trackTitle || "Unknown Title") : ""
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
    }
}
