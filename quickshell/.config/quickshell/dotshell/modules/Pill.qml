// Contenedor redondeado reutilizable para agrupar modulos -- reemplaza al
// truco de glyphs de esquina (custom/left|right#bg-1|bg-2|bg-3) que hacia
// falta en Waybar para simular el mismo efecto en CSS/GTK. En QML se puede
// dibujar la forma directamente, mismo lenguaje "card" que ya usan
// rofi/swaync/el menu de GRUB.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml (pragma Singleton) vive en el directorio padre

Rectangle {
    id: root

    default property alias content: row.data
    property real horizontalPadding: 14
    property real verticalPadding: 6
    property real spacing: 10
    // Alto fijo (no derivado del contenido): si cada Pill midiera su alto
    // segun su propio contenido, el de Workspaces (puntos de 10px) queda
    // mas bajo que los que tienen texto (~13-16px) -- results en pills de
    // distinta altura una al lado de la otra, se nota mucho.
    property real minContentHeight: 20

    implicitWidth: row.implicitWidth + horizontalPadding * 2
    implicitHeight: Math.max(row.implicitHeight, minContentHeight) + verticalPadding * 2
    radius: height / 2
    color: Colors.bg1

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
