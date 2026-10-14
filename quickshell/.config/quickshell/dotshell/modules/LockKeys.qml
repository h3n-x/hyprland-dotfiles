// Bloq Mayus / Bloq Num en la barra (Fase 11 B2): un icono por tecla
// activada, solo mientras alguna lo esta. KeyboardState lo lee al soltar esas
// teclas (atajos no consumidores) y solo si este modulo esta en la barra.
import QtQuick
import ".." // Colors.qml, Tokens.qml, KeyboardState.qml

Item {
    id: root
    readonly property bool shown: KeyboardState.capsLock || KeyboardState.numLock
    // Texto de la informacion al pasar el raton (bar.tooltips, Fase 11 B2b).
    readonly property string tooltip: [KeyboardState.capsLock ? I18n.tr("Caps Lock on") : "", KeyboardState.numLock ? I18n.tr("Num Lock on") : ""].filter(x => x).join(" · ")
    visible: shown

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    BarFlow {
        id: row
        spacing: Tokens.space.xs
        Icon { visible: KeyboardState.capsLock; name: "keyboard_capslock"; size: Tokens.icon.md }
        Text {
            visible: KeyboardState.numLock
            text: "1"
            color: Colors.text
            font.family: Tokens.font.mono
            font.pixelSize: Tokens.type.label
            font.weight: Tokens.weight.semibold
        }
    }
}
