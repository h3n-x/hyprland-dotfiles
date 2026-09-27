// Insignia de estado (Fase 8 B2, P8.7; nacio como la severidad de B9). La
// forma unica de mostrar un estado: icono + texto + color de significado, asi
// el estado se entiende aunque no se distinga el color (regla C4: protanopia,
// acento del wallpaper parecido a un estado). Niveles de B9 (N7):
//   0 Informacion        neutro, contorno
//   1 Recomendacion      neutro con enfasis, contorno (no usa el acento: D10)
//   2 Advertencia        warning (fijo)
//   3 Accion importante  danger (fijo)
// Nunca un color de identidad (principio 23). El peso visual crece con el
// nivel: los neutros van con contorno, los de significado rellenos.
//
//   StatusBadge { level: 2 }                    // "Advertencia"
//   StatusBadge { level: 3; label: "Crítico" }  // texto propio, mismo icono y color
import QtQuick
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root
    property int level: 1
    property string label: ""

    readonly property var spec: [
        { l: "Información", i: "info", bg: "transparent", fg: Colors.textMuted },
        { l: "Recomendación", i: "lightbulb", bg: "transparent", fg: Colors.text },
        { l: "Advertencia", i: "warning", bg: Colors.warningContainer, fg: Colors.textOnWarningContainer },
        { l: "Acción importante", i: "priority_high", bg: Colors.dangerContainer, fg: Colors.textOnDangerContainer }
    ][Math.max(0, Math.min(3, root.level))]

    implicitHeight: 24
    implicitWidth: row.implicitWidth + Tokens.space.lg
    radius: Tokens.radius.pill(height)
    color: root.spec.bg
    border.width: root.level <= 1 ? 1 : 0
    border.color: Colors.divider

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Tokens.space.xs
        Icon { anchors.verticalCenter: parent.verticalCenter; name: root.spec.i; size: 14; filled: true; color: root.spec.fg }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label || root.spec.l
            color: root.spec.fg
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
            font.weight: Tokens.weight.semibold
            wrapMode: Text.NoWrap
        }
    }
}
