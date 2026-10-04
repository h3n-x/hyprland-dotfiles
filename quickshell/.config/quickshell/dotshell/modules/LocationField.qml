// Ciudad del clima en el centro de configuracion (Fase 10 B4,
// dashboard.weather.location): la ciudad elegida, "Cambiar" (abre CitySearch
// debajo de la fila, como la lista de Select) y "Quitar". Elegir pasa por
// weather-fetch --set, que redondea las coordenadas (~10 km) y guarda en el
// almacen; quitar, por weather-fetch --clear. No guarda estado propio.
import QtQuick
import Quickshell
import ".." // Colors.qml, Tokens.qml

Row {
    id: root

    property var value: null
    property bool open: false
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/weather-fetch"

    function choose(place: var): void {
        Quickshell.execDetached([root.script, "--set", String(place.lat), String(place.lon), place.name, place.detail || ""]);
        root.open = false;
    }

    spacing: Tokens.space.sm

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 220)
        elide: Text.ElideRight
        text: root.value ? root.value.name : "Sin ciudad"
        color: root.value ? Colors.text : Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.body
    }
    Button {
        activeFocusOnTab: true
        icon: root.open ? "close" : "edit_location"
        label: root.open ? "Cancelar" : (root.value ? "Cambiar" : "Elegir")
        onClicked: root.open = !root.open
    }
    Button {
        visible: !!root.value && !root.open
        activeFocusOnTab: visible
        icon: "delete"
        label: "Quitar"
        onClicked: Quickshell.execDetached([root.script, "--clear"])
    }
}
