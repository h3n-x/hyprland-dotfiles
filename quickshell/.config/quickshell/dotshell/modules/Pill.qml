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

    // Alto fijo (Tokens.pill.height, D14), no derivado del contenido: si cada
    // Pill midiera su alto segun lo que tiene adentro, los de iconos y los de
    // texto quedan de alturas distintas uno al lado del otro.
    implicitWidth: row.implicitWidth + horizontalPadding * 2
    implicitHeight: Tokens.pill.height
    radius: Tokens.radius.pill(height)
    color: Colors.m3surfaceContainerLow

    // Hover de la pill entera, solo para pills de accion unica (Clock, Mpris;
    // decision Q2 = A). En las de varios botones cada control lleva su propio
    // HoverHalo y esto queda en false.
    property bool hovered: false
    property bool pressed: false
    StateLayer { hovered: root.hovered; pressed: root.pressed }

    // RowLayout (no Row) a proposito: con Row, cada hijo se posiciona con
    // y=0 (top-align), asi que un modulo con font.pixelSize mas chico (ej.
    // Microphone.qml, 13px) queda visualmente "mas arriba" que uno con
    // pixelSize mas grande (ej. Network.qml, 15px) al lado -- mismo bug
    // que ya se corrigio dentro de Audio/Mpris/Osd, esta vez entre iconos
    // del mismo Pill. Cada hijo puesto adentro de un Pill necesita
    // Layout.alignment: Qt.AlignVCenter (ver Bar.qml) para que esto
    // funcione.
    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: root.spacing
    }
}
