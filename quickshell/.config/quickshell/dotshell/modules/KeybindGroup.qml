// Un grupo de atajos (Fase 10 B4; sacado de la guia de atajos, unica copia):
// nombre e icono del grupo, "un modo" si es un submapa, y cada atajo con su
// descripcion y sus combinaciones en teclas (Keycap). Lo usan la guia
// (Super+/, en columnas) y la pagina Atajos del centro de configuracion.
//
//   KeybindGroup { group: { name, icon, mode, items: [{ text, combos: [{ mods, keys }] }] } }
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, KeybindState.qml

DashZone {
    id: zone
    required property var group

    component T: Text {
        property int size: Tokens.type.body
        property int wt: Tokens.weight.regular
        color: Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: size
        font.weight: wt
        elide: Text.ElideRight
    }

    padding: Tokens.space.md
    implicitHeight: zoneCol.implicitHeight + 2 * Tokens.space.md
    ColumnLayout {
        id: zoneCol
        width: parent.width
        spacing: Tokens.space.xs + 2
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.space.sm
            Icon { name: zone.group.icon; size: Tokens.icon.sm; color: Colors.accent }
            T { text: zone.group.name; size: Tokens.type.label; wt: Tokens.weight.semibold; color: Colors.textMuted }
            T {
                visible: zone.group.mode
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: I18n.tr("a mode")
                size: Tokens.type.caption
                color: Colors.border
            }
        }
        Repeater {
            model: zone.group.items
            // Descripcion y teclas en una linea; si las teclas no
            // entran, van debajo (alineadas a la derecha).
            GridLayout {
                id: row
                required property var modelData
                readonly property bool stacked: label.implicitWidth + keysRow.implicitWidth + Tokens.space.sm > row.width
                Layout.fillWidth: true
                columns: row.stacked ? 1 : 2
                columnSpacing: Tokens.space.sm
                rowSpacing: Tokens.space.xs
                T { id: label; Layout.fillWidth: true; text: row.modelData.text }
                // Combinaciones: teclas unidas, varias separadas por "o".
                Row {
                    id: keysRow
                    Layout.alignment: Qt.AlignRight
                    spacing: Tokens.space.xs + 2
                    Repeater {
                        model: row.modelData.combos
                        Row {
                            id: combo
                            required property var modelData
                            required property int index
                            spacing: 3
                            T {
                                visible: combo.index > 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: "o"
                                size: Tokens.type.caption
                                color: Colors.border
                                rightPadding: 2
                            }
                            Repeater {
                                model: combo.modelData.mods.map(m => KeybindState.modLabel(m)).concat(combo.modelData.keys)
                                Keycap {
                                    required property string modelData
                                    label: modelData
                                    spoken: KeybindState.words(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
