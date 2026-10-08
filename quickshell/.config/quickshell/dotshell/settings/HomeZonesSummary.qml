// Zonas de Inicio en el centro de configuracion (Fase 11 B4): solo el resumen
// (en orden, con su tamano) y "Editar Inicio", que abre el dashboard ya
// editando. El editor es uno solo, en el dashboard (HomeZones); aca no se
// duplica. DASHBOARD_EDIT_CMD cambia el comando (vacio = nada, para las pruebas).
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, SettingsState.qml
import "../modules"

ColumnLayout {
    id: summary
    property var value: []
    readonly property var widgets: (SettingsState.meta("dashboard.home.zones") || {}).widgets || ({})
    readonly property var zones: (summary.value || []).filter(z => !!summary.widgets[z.id])
    readonly property var editCmd: Quickshell.env("DASHBOARD_EDIT_CMD") !== null && Quickshell.env("DASHBOARD_EDIT_CMD") !== undefined
        ? (Quickshell.env("DASHBOARD_EDIT_CMD") ? Quickshell.env("DASHBOARD_EDIT_CMD").split(" ") : [])
        : ["qs", "-c", "dotshell", "ipc", "call", "dashboard", "edit"]
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
                        text: (chip.info.label || chip.modelData.id) + (chip.modelData.size === "full" ? "" : " · " + (chip.modelData.size === "wide" ? "ancha" : "compacta"))
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                    }
                }
            }
        }
        Text {
            visible: summary.zones.length === 0
            text: "Sin zonas: Inicio muestra solo la hora, los avisos, el clima y la música."
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
        }
    }
    Button {
        objectName: "editHome"
        label: "Editar Inicio"
        icon: "edit"
        onClicked: if (summary.editCmd.length) Quickshell.execDetached(summary.editCmd)
    }
}
