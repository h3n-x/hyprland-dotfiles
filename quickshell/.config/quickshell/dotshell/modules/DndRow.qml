// "No molestar" en el centro de control (Fase 4; componente propio desde la
// Fase 11 B6: el ajuste rapido "dnd" en tamano fila): nombre e interruptor.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, QuickTiles.qml

RowLayout {
    Text {
        text: "No molestar"
        color: Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.body
        Layout.fillWidth: true
    }

    Switch {
        checked: QuickTiles.dnd.active
        onToggled: QuickTiles.dnd.toggle()
    }
}
