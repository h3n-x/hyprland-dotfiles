// Reemplaza a waybar/modules/optional/tray.jsonc. SystemTray es nativo
// (protocolo StatusNotifierItem via DBus), muestra los mismos iconos que
// nm-applet/blueman-applet/etc. (ver autostart.lua). El menu contextual
// (click derecho) es lo mas nuevo/fragil de este modulo -- probado con lo
// que haya disponible en este equipo, el posicionamiento del menu puede
// necesitar ajuste fino mas adelante.
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import ".." // Colors.qml

Row {
    id: root
    required property var panelWindow
    spacing: 10
    // Sin esto, con la bandeja vacia (hoy: nm-applet/blueman filtrados,
    // nada mas registrado) el RowLayout del Pill que lo contiene igual le
    // reserva el "spacing" de los dos lados a este Row de ancho 0 -- se ve
    // como un hueco de doble espacio entre los iconos vecinos (Bluetooth y
    // Microphone). Los items invisibles SI se saltean para spacing en un
    // RowLayout (a diferencia de un Row/Column comun).
    visible: root.filteredItems.length > 0

    // Las apps con un reproductor MPRIS activo ya muestran su icono al
    // lado del titulo en Mpris.qml (ver Bar.qml) -- no hace falta
    // duplicarlas aca (tipico: Spotify aparece en las dos bandejas a la
    // vez si no se filtra). Match difuso por nombre (desktopEntry vs. id
    // del tray item) porque no hay una forma directa de correlacionar un
    // SystemTrayItem con un MprisPlayer -- son dos protocolos DBus
    // distintos sin campo en comun.
    function isMprisApp(item) {
        const id = (item.id || "").toLowerCase();
        if (!id) return false;
        for (const p of Mpris.players.values) {
            const entry = (p.desktopEntry || "").toLowerCase();
            if (entry && (id.includes(entry) || entry.includes(id))) return true;
        }
        return false;
    }

    // nm-applet y blueman tienen ahora su propio icono con logica real
    // (Network.qml/Bluetooth.qml, ver Bar.qml) -- se filtran de aca para
    // no duplicar. ids confirmados en vivo (Component.onCompleted con un
    // console.log temporal): "nm-applet" y "blueman".
    readonly property var hiddenIds: ["nm-applet", "blueman"]
    function isHidden(item) {
        return root.hiddenIds.includes(item.id) || root.isMprisApp(item);
    }

    readonly property var filteredItems: SystemTray.items.values.filter(item => !root.isHidden(item))

    Repeater {
        model: root.filteredItems

        Item {
            id: trayItem
            required property var modelData
            width: 18
            height: 18

            Image {
                anchors.fill: parent
                source: trayItem.modelData.icon
                smooth: true
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: trayItem.modelData.menu
                anchor.window: root.panelWindow
                anchor.rect.y: root.panelWindow.height
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        if (trayItem.modelData.hasMenu) menuAnchor.open();
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate();
                    } else {
                        trayItem.modelData.activate();
                    }
                }
            }
        }
    }
}
