// Icono de Material Symbols por nombre de ligadura (decisiones D10, I2, I4 del
// design system): text: "wifi" en vez de un glyph de uso privado -- los
// glyphs invisibles se pierden al editar (asi se vaciaron dos labels de
// hyprlock, KI-C18). Familia, tamano y ejes salen de Tokens; el color por
// defecto es el rol m3onSurface.
//
//   Icon { name: "wifi"; filled: Networking.wifiEnabled }
import QtQuick
import ".." // Tokens.qml, Colors.qml

Text {
    id: root
    property string name: ""
    // Relleno 1 = encendido/activo, 0 = apagado/inactivo (regla de D10).
    property bool filled: false
    property int size: Tokens.icon.md
    property int weight: Tokens.weight.regular

    text: name
    color: Colors.m3onSurface
    font.family: Tokens.font.icon
    font.pixelSize: size
    font.variableAxes: Tokens.icon.axes(filled, weight, size)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
