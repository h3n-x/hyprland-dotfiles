// Boton de texto en pildora (Fase 10 B1; sacado de las filas de
// Mantenimiento, unica copia): contorno por defecto, relleno de acento con
// main (la accion principal). Lo usan Mantenimiento y el centro de
// configuracion.
//
//   Button { label: "Ver registro"; icon: "article"; onClicked: … }
//   Button { label: "Reiniciar la shell"; main: true; onClicked: … }
import QtQuick
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: btn
    property string label
    property string icon: ""
    property bool main: false
    // Contorno: color del texto/icono y del borde (por defecto los neutros;
    // sobre un aviso, los de su contenedor).
    property color ink: Colors.textMuted
    property color edge: Colors.divider
    signal clicked()
    implicitHeight: 32
    implicitWidth: btnRow.implicitWidth + Tokens.space.lg + Tokens.space.xs
    radius: Tokens.radius.pill(height)
    color: btn.main ? Colors.accent : "transparent"
    border.width: btn.main ? 0 : 1
    border.color: btn.activeFocus ? Colors.accent : btn.edge
    // Con el teclado (si quien lo usa le da activeFocusOnTab): Enter o Espacio.
    Keys.onReturnPressed: btn.clicked()
    Keys.onEnterPressed: btn.clicked()
    Keys.onSpacePressed: btn.clicked()
    StateLayer { hovered: btnMouse.containsMouse; pressed: btnMouse.pressed; focused: btn.activeFocus; contentColor: btn.main ? Colors.textOnAccent : btn.ink }
    Row {
        id: btnRow
        anchors.centerIn: parent
        spacing: Tokens.space.xs + 2
        Icon { anchors.verticalCenter: parent.verticalCenter; visible: btn.icon !== ""; name: btn.icon; size: Tokens.icon.sm; filled: btn.main
            color: btn.main ? Colors.textOnAccent : btn.ink }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            // Sin texto, solo el icono (Fase 11 B5b: el temporizador compacto).
            visible: btn.label !== ""
            text: btn.label
            color: btn.main ? Colors.textOnAccent : btn.ink
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
            font.weight: Tokens.weight.semibold
            font.features: Tokens.tabularNumbers
            maximumLineCount: 3
            elide: Text.ElideRight
        }
    }
    MouseArea { id: btnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
}
