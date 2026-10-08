// Fila o columna segun la barra (Fase 11 B3): en una barra arriba o abajo, los
// hijos van en fila centrados en alto; a un costado, en columna centrados en
// ancho. Un solo componente para los dos sentidos (sin copias "vertical" de
// cada modulo, D-P11-1). Los hijos no llevan anchors: el Grid los ubica.
//
//   BarFlow { spacing: Tokens.space.xs; Icon { … } Text { … } }
import QtQuick
import ".." // Tokens.qml

Grid {
    readonly property bool vertical: Tokens.bar.vertical
    rows: vertical ? -1 : 1
    columns: vertical ? 1 : -1
    flow: vertical ? Grid.TopToBottom : Grid.LeftToRight
    verticalItemAlignment: Grid.AlignVCenter
    horizontalItemAlignment: Grid.AlignHCenter
}
