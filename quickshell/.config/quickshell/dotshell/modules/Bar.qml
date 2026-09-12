// Barra principal. Layout a pedido del usuario:
// izquierda: pill de workspaces, pill de mpris (solo titulo) -- separados.
// centro: reloj (toggle hora/fecha al click, ver Clock.qml).
// derecha, en pills separados: (update, bandeja, microfono) / (bateria,
// idle inhibitor) -- y power, aparte, al final del todo.
//
// Se sacaron (a pedido) cpu/memoria/temperatura/gpu/distro -- ver plan de
// migracion para el detalle de por que se habian agregado. Volume.qml y
// Backlight.qml TAMBIEN se sacaron de aca (ya esta el OSD, ver Osd.qml) --
// pero siguen corriendo, instanciados sin UI en shell.qml, porque son los
// que disparan ese OSD (Pipewire/FileView + OsdState.show()).
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 38
    margins {
        top: 6
        left: 10
        right: 10
    }
    color: "transparent"
    // SUPER+SHIFT+B (ver binds.lua + shell.qml) -- toggle global, afecta a
    // todas las pantallas a la vez (BarVisibility es un singleton).
    visible: !BarVisibility.hidden

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Pill {
            Layout.alignment: Qt.AlignVCenter
            Workspaces { Layout.alignment: Qt.AlignVCenter }
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            // Sin esto, con el reproductor cerrado quedaria una "burbuja"
            // vacia (el Item de Mpris.qml se pone invisible, pero Row
            // igual le reserva su espacio -- ver el mismo tema en Pill.qml).
            // No se importa Quickshell.Services.Mpris aca para leer esto
            // directo porque ese modulo exporta un singleton TAMBIEN
            // llamado "Mpris" que chocaria con este componente local del
            // mismo nombre (mismo problema que IdleInhibitor, ver
            // IdleToggle.qml) -- se expone la visibilidad del propio
            // componente en su lugar.
            visible: mprisModule.visible
            Mpris { id: mprisModule; Layout.alignment: Qt.AlignVCenter }
        }

        Item { Layout.fillWidth: true }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            Clock { Layout.alignment: Qt.AlignVCenter }
        }

        Item { Layout.fillWidth: true }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            spacing: 14
            Update { Layout.alignment: Qt.AlignVCenter }
            Network { Layout.alignment: Qt.AlignVCenter; panelWindow: bar }
            Bluetooth { Layout.alignment: Qt.AlignVCenter; panelWindow: bar }
            Tray { Layout.alignment: Qt.AlignVCenter; panelWindow: bar }
            Microphone { Layout.alignment: Qt.AlignVCenter }
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            spacing: 14
            Battery { Layout.alignment: Qt.AlignVCenter }
            IdleToggle { Layout.alignment: Qt.AlignVCenter; panelWindow: bar }
        }

        Power {
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
