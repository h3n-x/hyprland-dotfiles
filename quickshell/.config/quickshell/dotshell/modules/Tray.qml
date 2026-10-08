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
import ".." // Colors.qml, Tokens.qml

// En fila o en columna segun la barra (BarFlow, Fase 11 B3).
BarFlow {
    id: root
    required property var panelWindow
    spacing: Tokens.space.sm
    // Sin esto, con la bandeja vacia (hoy: nm-applet/blueman filtrados,
    // nada mas registrado) el RowLayout del Pill que lo contiene igual le
    // reserva el "spacing" de los dos lados a este Row de ancho 0 -- se ve
    // como un hueco de doble espacio entre los iconos vecinos (Bluetooth y
    // Microphone). Los items invisibles SI se saltean para spacing en un
    // RowLayout (a diferencia de un Row/Column comun).
    // Si se muestra, segun su propio estado (que este en la barra lo decide bar.layout, Fase 11 B1).
    // La barra lee shown, no visible: visible depende del padre y una pill
    // oculta nunca volveria a mostrarse.
    readonly property bool shown: root.filteredItems.length > 0
    visible: shown

    // Las apps con un reproductor MPRIS activo ya tienen la pill multimedia
    // y el reproductor del dashboard (Mpris.qml, MediaHero.qml) -- no hace falta duplicarlas
    // aca (tipico: Spotify aparece tambien en la bandeja si no se filtra). Match difuso por nombre (desktopEntry vs. id
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

    readonly property string stopScript: Quickshell.env("HOME") + "/.config/hypr/scripts/tray-stop.sh"

    TrayDropdown {
        id: trayDropdown
        panelWindow: root.panelWindow
    }

    Repeater {
        model: root.filteredItems

        Item {
            id: trayItem
            required property var modelData
            // Iconos de app (tema de iconos, sin padding interno): 16 px igualan
            // opticamente a los Material Symbols de 20 (decision I2).
            width: Tokens.icon.sm
            height: Tokens.icon.sm

            Image {
                anchors.fill: parent
                source: trayItem.modelData.icon
                smooth: true
            }

            // Su posicion la pone TrayDropdown.anchorMenu al abrirlo (la misma
            // politica que los popups anclados, tambien con la barra vertical).
            QsMenuAnchor {
                id: menuAnchor
                menu: trayItem.modelData.menu
            }

            // Cada icono es un boton propio (Q2 = A).
            HoverHalo { hovered: trayMouse.containsMouse; pressed: trayMouse.pressed }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        trayDropdown.openFor(trayItem, trayItem.modelData, menuAnchor);
                    } else if (mouse.button === Qt.MiddleButton) {
                        Quickshell.execDetached([root.stopScript, trayItem.modelData.id, trayItem.modelData.title || trayItem.modelData.id]);
                    } else {
                        trayItem.modelData.activate();
                    }
                }
            }
        }
    }
}
