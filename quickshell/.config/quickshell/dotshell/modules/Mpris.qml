// Reemplaza a waybar/modules/mpris.jsonc. Solo se muestra si hay un
// reproductor MPRIS activo (Spotify via spicetify, navegador, etc.).
// Muestra el icono de la app real del reproductor (via su desktop entry,
// no un icono de la bandeja -- mas robusto: no depende de que esa app
// ademas registre un tray icon).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".." // Colors.qml
import Quickshell.Services.Mpris

Item {
    id: root
    readonly property var player: Mpris.players.values[0] ?? null
    visible: !!root.player

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // RowLayout (no Row) a proposito: el icono (16px) y el texto (13px)
    // tienen alturas distintas, y Row no deja usar Layout.alignment /
    // anchors por hijo para centrarlos -- ver el mismo problema que se
    // encontro y se corrigio en Volume.qml.
    RowLayout {
        id: row
        spacing: 6

        IconImage {
            Layout.alignment: Qt.AlignVCenter
            implicitSize: 16
            source: root.player ? Quickshell.iconPath(root.player.desktopEntry, "multimedia-player") : ""
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            color: Colors.fg
            font.pixelSize: 13
            text: root.player && root.player.isPlaying ? "󰐊" : "󰏤"
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            color: Colors.fg
            font.pixelSize: 13
            // Solo el titulo -- sin artista, a pedido del usuario.
            text: root.player ? (root.player.trackTitle || "Unknown Title") : ""
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
    }
}
