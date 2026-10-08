// Una lista editable en su lugar, vista desde el centro de configuracion:
// solo el resumen (en orden, con su tamano) y "Editar", que abre su editor
// (que es uno solo y no se duplica aca). Las zonas de Inicio (Fase 11 B4:
// HomeZones en el dashboard; DASHBOARD_EDIT_CMD) y los ajustes rapidos (B6:
// TileGrid en el centro de control; CONTROLCENTER_EDIT_CMD). Esas variables
// cambian el comando (vacio = nada, para las pruebas).
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, SettingsState.qml
import "../modules"

ColumnLayout {
    id: summary
    property var value: []
    // La clave (con su registro "widgets") y lo que dice.
    property string key: "dashboard.home.zones"
    readonly property bool tiles: summary.key === "controlCenter.tiles"
    readonly property var widgets: (SettingsState.meta(summary.key) || {}).widgets || ({})
    readonly property var zones: (summary.value || []).filter(z => !!summary.widgets[z.id])
    readonly property string envName: summary.tiles ? "CONTROLCENTER_EDIT_CMD" : "DASHBOARD_EDIT_CMD"
    readonly property var editCmd: Quickshell.env(summary.envName) !== null && Quickshell.env(summary.envName) !== undefined
        ? (Quickshell.env(summary.envName) ? Quickshell.env(summary.envName).split(" ") : [])
        : ["qs", "-c", "dotshell", "ipc", "call", summary.tiles ? "controlcenter" : "dashboard", "edit"]
    spacing: Tokens.space.sm

    Flow {
        Layout.fillWidth: true
        spacing: Tokens.space.xs
        Repeater {
            model: summary.zones
            Rectangle {
                id: chip
                required property var modelData
                readonly property var info: summary.widgets[chip.modelData.id] || ({})
                implicitHeight: 28
                implicitWidth: chipRow.implicitWidth + Tokens.space.md * 2
                radius: 14
                color: Colors.tint(Colors.surfaceHighest, Tokens.tint.well)
                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: Tokens.space.xs + 2
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: chip.info.icon || ""; size: Tokens.icon.sm; color: Colors.text }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // "full" (la linea y la musica, Fase 11 B5): sin tamano que elegir, solo el nombre.
                        text: (chip.info.label || chip.modelData.id) + ((chip.info.sizes || []).length < 2 ? ""
                            : " · " + ({ wide: summary.tiles ? "ancho" : "ancha", compact: "compacta", small: "pequeño", row: "fila" })[chip.modelData.size])
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                    }
                }
            }
        }
        Text {
            visible: summary.zones.length === 0
            text: summary.tiles ? "Sin ajustes rápidos: el centro de control muestra solo las notificaciones." : "Sin zonas: Inicio queda vacío."
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
        }
    }
    Button {
        objectName: summary.tiles ? "editTiles" : "editHome"
        label: summary.tiles ? "Editar ajustes rápidos" : "Editar Inicio"
        icon: "edit"
        onClicked: if (summary.editCmd.length) Quickshell.execDetached(summary.editCmd)
    }
}
