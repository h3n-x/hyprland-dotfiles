// Contenedor redondeado reutilizable para agrupar modulos -- reemplaza al
// truco de glyphs de esquina (custom/left|right#bg-1|bg-2|bg-3) que hacia
// falta en Waybar para simular el mismo efecto en CSS/GTK. En QML se puede
// dibujar la forma directamente, mismo lenguaje "card" que ya usa
// el menu de GRUB.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml y Tokens.qml (pragma Singleton) viven en el directorio padre

Rectangle {
    id: root

    default property alias content: row.data
    property real horizontalPadding: Tokens.pad.pillH
    property real spacing: Tokens.gap.inline
    // En una barra a un costado (Fase 11 B3) los modulos van en columna y la
    // pildora tiene el ancho fijo y el alto de su contenido.
    property bool vertical: false

    // Alto fijo (Tokens.pill.height, D14), no derivado del contenido: si cada
    // Pill midiera su alto segun lo que tiene adentro, los de iconos y los de
    // texto quedan de alturas distintas uno al lado del otro.
    implicitWidth: root.vertical ? Tokens.pill.height : row.implicitWidth + horizontalPadding * 2
    implicitHeight: root.vertical ? row.implicitHeight + horizontalPadding * 2 : Tokens.pill.height
    radius: Tokens.radius.pill(height)
    // Solo flotante lleva fondo propio (bar.style, Fase 11 B3b): sobre una barra
    // sólida o transparente, la píldora agrupa sin dibujar.
    color: Tokens.bar.style === "floating" ? Colors.surfaceLow : "transparent"

    // Hover de la pill entera, solo para pills de accion unica (Clock, Mpris;
    // decision Q2 = A). En las de varios botones cada control lleva su propio
    // HoverHalo y esto queda en false.
    property bool hovered: false
    property bool pressed: false
    // Los modulos de adentro (Fase 11 B1): la barra lee su `shown` para no
    // dejar una pildora vacia y el hover de pildora entera (wholePill).
    readonly property var parts: row.children
    StateLayer { hovered: root.hovered; pressed: root.pressed }

    // Un layout (no Row/Column) a proposito: con Row, cada hijo se posiciona
    // con y=0 (top-align), asi que un modulo con font.pixelSize mas chico (ej.
    // Microphone.qml, 13px) queda visualmente "mas arriba" que uno con
    // pixelSize mas grande (ej. Network.qml, 15px) al lado. GridLayout (Fase
    // 11 B3) en fila o en columna segun `vertical`; cada hijo lleva
    // Layout.alignment: Qt.AlignCenter (BarEntry) para quedar centrado en los
    // dos sentidos.
    GridLayout {
        id: row
        anchors.centerIn: parent
        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: root.vertical ? -1 : 1
        columns: root.vertical ? 1 : -1
        rowSpacing: root.spacing
        columnSpacing: root.spacing
    }
}
