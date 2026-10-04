// Pagina de una categoria, generada desde el esquema (Fase 10 B1): titulo,
// "Restablecer la página" (pide confirmacion), una tarjeta por seccion con
// una SettingRow por clave y, al final, las opciones avanzadas plegadas
// (se despliegan solas si alguna esta cambiada o si la busqueda lleva a una).
// Una pagina puede sumar contenido propio arriba de una seccion (extras:
// nombre de la seccion -> Component; Apariencia, Fase 10 B2): las opciones
// siguen siendo las del esquema, con su busqueda, cambios y restablecer.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, SettingsState.qml
import "../modules"

ColumnLayout {
    id: page

    required property string category
    required property SettingsModel model
    property string highlightKey: ""
    property var extras: ({})

    readonly property var sections: page.model.sections(page.category)
    readonly property var keys: page.model.byCategory[page.category] || []
    readonly property int changed: page.keys.filter(k => SettingsState.isModified(k)).length
    readonly property int advancedCount: page.model.advancedCount(page.category)
    property bool showAdvanced: page.keys.some(k => page.model.keys[k].advanced && SettingsState.isModified(k))
    property bool confirming: false

    // Filas por clave, para llevar la busqueda a una (SettingsWindow.reveal).
    property var rows: ({})
    function rowFor(key: string): Item {
        if (page.model.keys[key] && page.model.keys[key].advanced) page.showAdvanced = true;
        return page.rows[key] || null;
    }

    spacing: Tokens.space.lg
    // Valores de Hyprland de esta pagina (Fase 10 B3).
    Component.onCompleted: page.model.refreshLive(page.category)

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space.md
        Icon {
            name: (page.model.page(page.category) || {}).icon || "settings"
            size: Tokens.icon.lg
            color: Colors.accent
        }
        Text {
            Layout.fillWidth: true
            text: page.model.categoryLabel(page.category)
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.display
            font.weight: Tokens.weight.semibold
        }
        Button {
            visible: page.changed > 0 && !page.confirming
            activeFocusOnTab: visible
            label: "Restablecer la página"
            icon: "restart_alt"
            onClicked: page.confirming = true
        }
        // Confirmacion en el lugar: cuantas vuelven a fabrica.
        Text {
            visible: page.confirming
            text: page.changed === 1 ? "¿Volver 1 opción a fábrica?" : "¿Volver " + page.changed + " opciones a fábrica?"
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
        }
        Button {
            visible: page.confirming
            activeFocusOnTab: visible
            label: "Cancelar"
            onClicked: page.confirming = false
        }
        Button {
            visible: page.confirming
            activeFocusOnTab: visible
            label: "Restablecer"
            main: true
            onClicked: {
                SettingsState.resetCategory(page.category);
                page.confirming = false;
            }
        }
    }
    // Si ya no hay nada cambiado (otro la restablecio), la pregunta se va.
    onChangedChanged: if (page.changed === 0) page.confirming = false

    // Contenido propio arriba de todas las secciones (extras["_top"]; la lista
    // de atajos, Fase 10 B4).
    Loader {
        active: !!page.extras["_top"]
        visible: active
        Layout.fillWidth: true
        sourceComponent: page.extras["_top"] || null
    }

    Repeater {
        model: page.sections
        ColumnLayout {
            id: section
            required property var modelData
            readonly property var shownKeys: section.modelData.keys.concat(page.showAdvanced ? section.modelData.advanced : [])
            visible: section.shownKeys.length > 0
            Layout.fillWidth: true
            spacing: Tokens.space.sm

            Text {
                visible: !!section.modelData.name
                Layout.leftMargin: Tokens.space.xs
                text: section.modelData.name
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.weight: Tokens.weight.semibold
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: list.implicitHeight
                radius: Tokens.radius.lg
                color: Colors.surface
                border.color: Colors.divider
                Column {
                    id: list
                    width: parent.width
                    Loader {
                        active: !!page.extras[section.modelData.name]
                        visible: active
                        width: list.width
                        sourceComponent: page.extras[section.modelData.name] || null
                    }
                    Repeater {
                        model: section.shownKeys
                        Column {
                            id: cell
                            required property string modelData
                            required property int index
                            width: list.width
                            Rectangle {
                                visible: cell.index > 0 || !!page.extras[section.modelData.name]
                                x: Tokens.space.lg
                                width: parent.width - 2 * Tokens.space.lg
                                height: 1
                                color: Colors.divider
                            }
                            SettingRow {
                                id: settingRow
                                width: parent.width
                                key: cell.modelData
                                model: page.model
                                highlighted: page.highlightKey === cell.modelData
                                Component.onCompleted: page.rows[cell.modelData] = settingRow
                                Component.onDestruction: if (page.rows[cell.modelData] === settingRow) delete page.rows[cell.modelData]
                            }
                        }
                    }
                }
            }
        }
    }

    // Opciones avanzadas: plegadas al final de la pagina.
    Rectangle {
        id: advToggle
        visible: page.advancedCount > 0
        Layout.alignment: Qt.AlignLeft
        implicitWidth: advRow.implicitWidth + Tokens.space.lg
        implicitHeight: Tokens.pill.height
        radius: Tokens.radius.pill(height)
        color: "transparent"
        activeFocusOnTab: visible
        Keys.onReturnPressed: page.showAdvanced = !page.showAdvanced
        Keys.onSpacePressed: page.showAdvanced = !page.showAdvanced
        StateLayer { hovered: advMouse.containsMouse; pressed: advMouse.pressed; focused: advToggle.activeFocus }
        Row {
            id: advRow
            anchors.centerIn: parent
            spacing: Tokens.space.xs
            Icon { anchors.verticalCenter: parent.verticalCenter; name: page.showAdvanced ? "expand_less" : "expand_more"; size: Tokens.icon.sm; color: Colors.textMuted }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (page.showAdvanced ? "Ocultar las opciones avanzadas" : "Opciones avanzadas") + " (" + page.advancedCount + ")"
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.weight: Tokens.weight.semibold
            }
        }
        MouseArea {
            id: advMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: page.showAdvanced = !page.showAdvanced
        }
    }
}
