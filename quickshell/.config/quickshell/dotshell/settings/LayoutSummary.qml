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
    function sizeName(size: string): string {
        const names = summary.tiles
            ? { wide: I18n.trc("tile size", "wide"), compact: I18n.trc("tile size", "compact"), small: I18n.trc("tile size", "small"), row: I18n.trc("tile size", "row") }
            : { wide: I18n.trc("zone size", "wide"), compact: I18n.trc("zone size", "compact"), small: I18n.trc("zone size", "small"), row: I18n.trc("zone size", "row") };
        return names[size] || size;
    }
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
                implicitHeight: Tokens.px(28)
                implicitWidth: chipRow.implicitWidth + Tokens.space.md * 2
                radius: Tokens.px(14)
                color: Colors.tint(Colors.surfaceHighest, Tokens.tint.well)
                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: Tokens.space.xs + 2
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: chip.info.icon || ""; size: Tokens.icon.sm; color: Colors.text }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // "full" (la linea y la musica, Fase 11 B5): sin tamano que elegir, solo el nombre.
                        text: I18n.trc(summary.tiles ? "tile" : "zone", chip.info.label || chip.modelData.id) + ((chip.info.sizes || []).length < 2 ? ""
                            : " · " + summary.sizeName(chip.modelData.size))
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                    }
                }
            }
        }
        Text {
            visible: summary.zones.length === 0
            text: summary.tiles ? I18n.tr("No quick settings: the control center shows only the notifications.") : I18n.tr("No zones: Home stays empty.")
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
        }
    }
    Button {
        objectName: summary.tiles ? "editTiles" : "editHome"
        label: summary.tiles ? I18n.tr("Edit quick settings") : I18n.tr("Edit Home")
        icon: "edit"
        onClicked: if (summary.editCmd.length) Quickshell.execDetached(summary.editCmd)
    }
}
