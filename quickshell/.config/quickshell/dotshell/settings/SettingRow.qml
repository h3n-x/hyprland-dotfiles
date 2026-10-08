// Una opcion del almacen (Fase 10 B1): etiqueta, descripcion, "Cambiada" y
// cuando se aplica, el control que corresponde a su tipo (SettingsModel.
// control) y, si esta cambiada, volver al valor de fabrica. Todo cambio va
// por SettingsState (-> scripts/settings, el unico que escribe); si el motor
// lo rechaza, el motivo queda debajo, en el color fijo de peligro (P8.7).
// Los marcadores son neutros: "cambiada" es un estado y los colores de
// identidad nunca marcan estados (principio 23).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, SettingsState.qml
import "../modules"

Item {
    id: row

    required property string key
    required property SettingsModel model
    // Resultado de la busqueda: la fila se ilumina una vez.
    property bool highlighted: false

    readonly property var meta: SettingsState.meta(row.key) || ({})
    readonly property var value: SettingsState.value(row.key)
    readonly property bool modified: SettingsState.isModified(row.key)
    readonly property string error: SettingsState.errors[row.key] || ""
    readonly property string kind: row.model.control(row.key)
    readonly property string note: row.model.applyNote(row.key)
    // Pantallas (B5) siempre a todo el ancho, debajo del texto.
    readonly property bool stacked: ["outputs", "barLayout", "screens", "homeZones", "tiles", "apps", "folders", "checks"].indexOf(row.kind) >= 0 || (!!control.item && control.item.implicitWidth > col.width * 0.6)
    // El selector abierto (su lista va debajo, a lo ancho de la fila).
    readonly property bool listOpen: ["select", "font", "layouts", "apps", "player", "location"].indexOf(row.kind) >= 0 && !!control.item && control.item.open
    // Lo que Hyprland usa ahora, si difiere del almacen (Fase 10 B3): modo juego,
    // un hyprctl a mano. Informacion, no un estado de error: neutro.
    readonly property var liveInfo: row.meta.hypr ? row.model.live[row.key] : null

    function set(v: var): void {
        SettingsState.set(row.key, v);
    }

    implicitHeight: col.implicitHeight + 2 * Tokens.space.md

    // Brillo del resultado de la busqueda: entra, se sostiene y se va (una
    // vez; con movimiento reducido, sin fundido).
    Rectangle {
        id: glow
        anchors.fill: parent
        radius: Tokens.radius.md
        color: Colors.tint(Colors.accent, Tokens.tint.track)
        border.width: 1
        border.color: Colors.accent
        opacity: 0
    }
    onHighlightedChanged: if (row.highlighted) flash.restart()
    SequentialAnimation {
        id: flash
        NumberAnimation { target: glow; property: "opacity"; to: 1; duration: Tokens.motion.short }
        PauseAnimation { duration: 1400 }
        NumberAnimation { target: glow; property: "opacity"; to: 0; duration: Tokens.motion.long }
    }

    ColumnLayout {
        id: col
        x: Tokens.space.lg
        y: Tokens.space.md
        width: parent.width - 2 * Tokens.space.lg
        spacing: Tokens.space.sm

        // Texto, volver y control en una linea; si el control es ancho (un
        // segmentado con etiquetas largas) pasa debajo, a todo el ancho.
        GridLayout {
            Layout.fillWidth: true
            columns: row.stacked ? 2 : 3
            columnSpacing: Tokens.space.md
            rowSpacing: Tokens.space.sm

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.space.hair
                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.space.sm
                    Text {
                        text: row.meta.label || row.key
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.weight: Tokens.weight.medium
                    }
                    Chip { visible: row.modified; icon: "edit"; label: "Cambiada" }
                    Chip { visible: row.note !== ""; icon: "schedule"; label: row.note }
                }
                Text {
                    visible: !!row.meta.description
                    Layout.fillWidth: true
                    text: row.meta.description || ""
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                    wrapMode: Text.WordWrap
                }
                Row {
                    visible: !!row.liveInfo && !row.liveInfo.same
                    spacing: Tokens.space.xs
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "info"; size: Tokens.icon.sm; color: Colors.textMuted }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.liveInfo ? "Hyprland usa ahora: " + row.liveInfo.live.map(v => typeof v === "boolean" ? (v ? "encendido" : "apagado")
                            : String(v).replace(".", ",")).join(" · ") : ""
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                    }
                }
                Row {
                    visible: row.error !== ""
                    spacing: Tokens.space.xs
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "error"; filled: true; size: Tokens.icon.sm; color: Colors.danger }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "No se guardó: " + row.error.replace(/; no se guardó$/, "")
                        color: Colors.danger
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                    }
                }
            }

            // Volver al valor de fabrica (solo si esta cambiada).
            Rectangle {
                id: resetBtn
                visible: row.modified
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Tokens.pill.height
                implicitHeight: Tokens.pill.height
                radius: width / 2
                color: "transparent"
                activeFocusOnTab: visible
                Keys.onReturnPressed: SettingsState.reset(row.key)
                Keys.onSpacePressed: SettingsState.reset(row.key)
                StateLayer { hovered: resetMouse.containsMouse; pressed: resetMouse.pressed; focused: resetBtn.activeFocus }
                Icon { anchors.centerIn: parent; name: "undo"; size: Tokens.icon.sm; color: Colors.textMuted }
                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SettingsState.reset(row.key)
                }
            }

            Loader {
                id: control
                Layout.alignment: Qt.AlignVCenter
                Layout.columnSpan: row.stacked ? 2 : 1
                Layout.fillWidth: row.stacked
                sourceComponent: ({
                    "switch": switchC, "segmented": segmentedC, "select": selectC,
                    "stepper": stepperC, "slider": sliderC, "path": pathC, "font": fontC, "layouts": layoutsC,
                    "player": selectC, "location": locationC, "time": timeC, "outputs": outputsC, "barLayout": barLayoutC, "screens": screensC, "homeZones": homeZonesC, "tiles": tilesC,
                    "apps": chipsC, "folders": chipsC, "text": textC, "checks": checksC
                })[row.kind] || null
            }
        }

        // Lista del selector, a lo ancho de la fila (como en la galeria).
        SelectList {
            visible: row.listOpen && (row.kind === "select" || row.kind === "player")
            Layout.fillWidth: true
            options: row.model.options(row.key)
            current: row.value
            onChosen: (v) => row.set(v)
            onClosed: control.item.open = false
        }
        // Busqueda de ciudad (Fase 10 B4), en el mismo lugar.
        CitySearch {
            visible: row.listOpen && row.kind === "location"
            Layout.fillWidth: true
            onVisibleChanged: if (visible) { reset(); Qt.callLater(focusInput); }
            onChosen: (place) => control.item.choose(place)
            onEscaped: control.item.open = false
        }
        // Lista para agregar (Fase 10 B3: distribuciones del teclado; Fase 11 B5:
        // aplicaciones fijadas), en el mismo lugar.
        PickList {
            visible: row.listOpen && (row.kind === "layouts" || row.kind === "apps")
            Layout.fillWidth: true
            entries: (row.kind === "layouts" || row.kind === "apps") && control.item ? control.item.entries : []
            placeholder: row.kind === "apps" ? "Buscar una aplicación" : "Buscar una distribución (spanish, latam, dvorak…)"
            taken: row.value || []
            onChosen: (id) => control.item.add(id)
            onClosed: control.item.open = false
        }
        // Lista de fuentes (Fase 10 B2), en el mismo lugar.
        FontList {
            visible: row.listOpen && row.kind === "font"
            Layout.fillWidth: true
            families: row.kind === "font" && control.item ? control.item.families : []
            current: row.kind === "font" ? (row.value || "") : ""
            onChosen: (f) => row.set(f)
            onClosed: control.item.open = false
        }
    }

    // Etiqueta neutra de contorno (cambiada, cuando se aplica).
    component Chip: Rectangle {
        id: chip
        property string icon
        property string label
        height: 20
        width: chipRow.implicitWidth + Tokens.space.md
        radius: Tokens.radius.pill(height)
        color: "transparent"
        border.color: Colors.divider
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: Tokens.space.xs
            Icon { anchors.verticalCenter: parent.verticalCenter; name: chip.icon; size: 12; color: Colors.textMuted }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.label
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
            }
        }
    }

    Component {
        id: switchC
        Switch {
            objectName: "control-switch"
            activeFocusOnTab: true
            checked: !!row.value
            onToggled: row.set(!row.value)
        }
    }
    Component {
        id: segmentedC
        Segmented {
            objectName: "control-segmented"
            activeFocusOnTab: true
            options: row.model.options(row.key)
            current: row.value
            onChosen: (v) => row.set(v)
        }
    }
    Component {
        id: selectC
        Select {
            objectName: "control-select"
            activeFocusOnTab: true
            options: row.model.options(row.key)
            current: row.value
            onChosen: (v) => row.set(v)
        }
    }
    Component {
        id: stepperC
        Stepper {
            objectName: "control-stepper"
            from: row.meta.min
            to: row.meta.max
            value: row.value
            unit: row.meta.unit || ""
            labels: row.meta.labels || ({})
            onMoved: (v) => row.set(v)
        }
    }
    Component {
        id: sliderC
        Slider {
            objectName: "control-slider"
            implicitWidth: 260 + Tokens.space.md + 84
            from: row.meta.min
            to: row.meta.max
            step: row.meta.step || 0
            integer: row.meta.type === "int"
            value: row.value
            unit: row.meta.unit || ""
            labels: row.meta.labels || ({})
            onMoved: (v) => row.set(row.meta.type === "int" ? Math.round(v) : v)
        }
    }
    Component {
        id: pathC
        PathField {
            objectName: "control-path"
            pick: ({ "image": "image", "dir": "dir" })[row.meta.kind] || ""
            value: row.value || ""
            onEdited: (v) => row.set(v)
        }
    }
    Component {
        id: fontC
        FontPicker {
            objectName: "control-font"
            activeFocusOnTab: true
            mono: row.meta.kind === "font-mono"
            current: row.value || ""
        }
    }
    Component {
        id: layoutsC
        LayoutList {
            objectName: "control-layouts"
            value: row.value || []
            maxItems: row.meta.maxItems || 4
            onEdited: (l) => row.set(l)
        }
    }
    // Texto corto (Fase 11 B5): el mismo campo que las rutas, con letra normal.
    Component {
        id: textC
        PathField {
            objectName: "control-text"
            plain: true
            placeholder: row.meta.placeholder || "Sin elegir"
            value: row.value || ""
            onEdited: (v) => row.set(v)
        }
    }
    // Varias opciones con su interruptor (Fase 11 B5b): a lo ancho de la fila.
    Component {
        id: checksC
        CheckList {
            objectName: "control-checks"
            options: row.model.options(row.key)
            value: row.value || []
            onEdited: (l) => row.set(l)
        }
    }
    // Aplicaciones y carpetas fijadas (Fase 11 B5): a lo ancho de la fila.
    Component {
        id: chipsC
        ChipList {
            objectName: "control-" + row.kind
            mode: row.kind
            value: row.value || []
            maxItems: row.meta.maxItems || 12
            onEdited: (l) => row.set(l)
        }
    }
    Component {
        id: timeC
        TimeField {
            objectName: "control-time"
            value: row.value || "00:00"
            onEdited: (v) => row.set(v)
        }
    }
    // Pantallas (Fase 10 B5): el panel entero ocupa el ancho de la fila.
    Component {
        id: outputsC
        DisplaysPanel {
            objectName: "control-outputs"
        }
    }
    // Barra (Fase 11 B1): el editor de la disposicion y las pantallas con barra.
    Component {
        id: barLayoutC
        BarLayoutEditor {
            objectName: "control-barLayout"
        }
    }
    // Zonas de Inicio (Fase 11 B4): resumen y el boton que lleva al editor del dashboard.
    Component {
        id: homeZonesC
        LayoutSummary {
            objectName: "control-homeZones"
            value: row.value || []
        }
    }
    // Ajustes rapidos (Fase 11 B6): el mismo resumen, su editor es el del centro de control.
    Component {
        id: tilesC
        LayoutSummary {
            objectName: "control-tiles"
            key: "controlCenter.tiles"
            value: row.value || []
        }
    }
    Component {
        id: screensC
        ScreenPicker {
            objectName: "control-screens"
            value: row.value || []
            onEdited: (l) => row.set(l)
        }
    }
    Component {
        id: locationC
        LocationField {
            objectName: "control-location"
            value: row.value
        }
    }
}
