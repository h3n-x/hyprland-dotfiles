// Avatar, arriba de su seccion en Apariencia (Fase 10 B2): ~/.face tal cual
// lo usan el bloqueo, el greeter y el arranque (Avatar.qml, se relee cuando
// cambia), y de donde sale. Elegir la fuente o la imagen rehace ~/.face al momento
// (AvatarSync en la shell: theme-apply.sh --face). Si la imagen propia no se
// puede leer, ~/.face queda como estaba y se dice aca.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml, SettingsState.qml
import "../modules"

Item {
    id: card

    readonly property bool own: SettingsState.value("appearance.avatar") === "image"
    readonly property string image: SettingsState.value("appearance.avatarImage") || ""
    // La imagen propia se prueba cargandola (la misma que se recortaria).
    Image {
        id: probe
        visible: false
        source: card.own && card.image ? "file://" + card.image : ""
        sourceSize.width: 64
        asynchronous: true
    }
    readonly property bool unreadable: card.own && (probe.status === Image.Error || (probe.status === Image.Null && !!card.image))

    implicitHeight: row.implicitHeight + 2 * Tokens.space.lg

    RowLayout {
        id: row
        x: Tokens.space.lg
        y: Tokens.space.lg
        width: parent.width - 2 * Tokens.space.lg
        spacing: Tokens.space.lg

        Avatar {
            size: 72
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.space.xs
            Text {
                Layout.fillWidth: true
                text: card.own ? "Tu imagen, recortada al centro." : "Se recorta del fondo en cada cambio de tema."
                wrapMode: Text.WordWrap
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
            }
            Text {
                Layout.fillWidth: true
                text: "En el bloqueo al momento; en la pantalla de inicio de sesión y en el arranque, en el próximo pase del sistema (un minuto)."
                wrapMode: Text.WordWrap
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
            // Estado con icono y texto (C4); color fijo de aviso.
            RowLayout {
                visible: card.unreadable
                spacing: Tokens.space.xs
                Icon { name: "warning"; filled: true; size: Tokens.icon.sm; color: Colors.warning }
                Text {
                    Layout.fillWidth: true
                    text: "No se puede leer la imagen: el avatar sigue siendo el anterior."
                    wrapMode: Text.WordWrap
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
            }
        }
    }
}
