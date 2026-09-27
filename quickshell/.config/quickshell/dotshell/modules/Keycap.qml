// Una tecla dibujada (Fase 4 B10): texto ("Super", "Q", "Impr") o icono de
// Material Symbols ("@volume_up"); "@arrows" dibuja las cuatro flechas en una
// sola tecla. Superficie neutra con el borde de abajo mas grueso, como una
// tecla real. La usan la guia de atajos y, mas adelante, la pagina Atajos
// del centro de configuracion (P10.11) y cualquier indicacion de teclas.
//
//   Keycap { label: "Super" }   Keycap { label: "@play_pause" }
import QtQuick
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: cap
    property string label: ""
    // Palabras para lectores de pantalla (si no, la etiqueta).
    property string spoken: ""
    readonly property bool isIcon: cap.label.charAt(0) === "@"
    readonly property var icons: cap.label === "@arrows" ? ["arrow_left", "arrow_drop_up", "arrow_drop_down", "arrow_right"]
                                 : cap.isIcon ? [cap.label.slice(1)] : []

    implicitHeight: 24
    implicitWidth: cap.isIcon ? iconRow.implicitWidth + Tokens.space.sm + 2 : Math.max(cap.implicitHeight, text.implicitWidth + Tokens.space.md)
    radius: Tokens.radius.xs + 2
    color: Colors.surfaceHighest
    border.width: 1
    border.color: Colors.divider

    Accessible.role: Accessible.StaticText
    Accessible.name: cap.spoken || cap.label

    // Borde inferior: la tecla "sobresale".
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        radius: cap.radius
        color: Colors.divider
    }
    Text {
        id: text
        visible: !cap.isIcon
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        text: cap.label
        color: Colors.text
        // Una o dos letras en monoespaciada (Q, 1 … 0); palabras en la de interfaz.
        font.family: cap.label.length <= 2 ? Tokens.font.mono : Tokens.font.ui
        font.pixelSize: Tokens.type.caption
        font.weight: Tokens.weight.semibold
    }
    Row {
        id: iconRow
        visible: cap.isIcon
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        spacing: -2
        Repeater {
            model: cap.icons
            Icon {
                required property string modelData
                name: modelData
                size: Tokens.icon.sm
            }
        }
    }
}
