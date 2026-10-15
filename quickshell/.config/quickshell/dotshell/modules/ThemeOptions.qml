// Opciones de color de UN wallpaper (Fase 3 B8b): color base y esquema.
//
// Color base: los candidatos que matugen encuentra en la imagen (el dominante
// primero, marcado con un punto) o, si la imagen no tiene un color claro, 8
// colores predefinidos (decision B8h). Esquema: Predeterminado (el global) o
// uno propio; "Mas..." muestra el resto. Elegir guarda la excepcion al
// instante (decision B8b-1, como favoritos y etiquetas); "Restablecer" la
// borra. No se aplica nada: la paleta de la vista previa (y de Aplicar) sale de
// la cache, que theme-apply.sh refresca tras cada cambio.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml

ColumnLayout {
    id: root

    property var candidates: []
    property bool noColor: false
    // Opciones efectivas de la cache ({seed, scheme, contrast}) y excepcion guardada.
    property var opts: null
    property var override: null

    signal seedChosen(string seed)
    signal schemeChosen(string scheme) // "" = predeterminado
    signal resetRequested()

    readonly property var presets: ["#d9534f", "#e8894a", "#d9a93a", "#5f9e5a", "#3a9e96", "#4a7fd4", "#6a5fc8", "#c95f9b"]
    readonly property var swatches: root.noColor ? root.presets : root.candidates
    readonly property string seed: root.opts ? root.opts.seed : ""
    readonly property string overrideScheme: root.override && root.override.scheme ? root.override.scheme : ""
    readonly property var mainSchemes: ["scheme-content", "scheme-tonal-spot", "scheme-vibrant"]
    readonly property var moreSchemes: ["scheme-expressive", "scheme-fidelity", "scheme-neutral", "scheme-monochrome",
                                        "scheme-rainbow", "scheme-fruit-salad"]
    readonly property var schemeNames: ({
        "scheme-content": I18n.trc("color scheme", "Content"), "scheme-tonal-spot": I18n.trc("color scheme", "Tonal spot"), "scheme-vibrant": I18n.trc("color scheme", "Vibrant"),
        "scheme-expressive": I18n.trc("color scheme", "Expressive"), "scheme-fidelity": I18n.trc("color scheme", "Fidelity"), "scheme-neutral": I18n.trc("color scheme", "Neutral"),
        "scheme-monochrome": I18n.trc("color scheme", "Monochrome"), "scheme-rainbow": I18n.trc("color scheme", "Rainbow"), "scheme-fruit-salad": I18n.trc("color scheme", "Fruit salad") })
    // "Mas..." abierto; tambien si el esquema propio es uno de los de adentro.
    property bool showMore: false
    readonly property bool moreSelected: root.moreSchemes.indexOf(root.overrideScheme) >= 0

    spacing: Tokens.space.sm

    // Chip de eleccion: el elegido se marca con el relleno (como los filtros de la galeria).
    component Chip: Rectangle {
        id: chip
        property string text
        property bool selected: false
        property string trailingIcon: ""
        signal clicked()
        implicitHeight: Tokens.pill.height - Tokens.space.xs
        // Relleno algo menor que el de los chips de etiquetas: los cinco entran en una fila.
        implicitWidth: chipRow.implicitWidth + (Tokens.space.xs + Tokens.space.hair) * 2
        radius: Tokens.radius.pill(height)
        color: chip.selected ? Colors.accentAltContainer : "transparent"
        border.color: chip.selected ? "transparent" : Colors.divider
        StateLayer {
            hovered: chipMouse.containsMouse
            pressed: chipMouse.pressed
            contentColor: chip.selected ? Colors.textOnAccentAltContainer : Colors.textMuted
        }
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: Tokens.space.hair
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.text
                color: chip.selected ? Colors.textOnAccentAltContainer : Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.weight: chip.selected ? Tokens.weight.semibold : Tokens.weight.regular
            }
            Icon {
                visible: chip.trailingIcon !== ""
                name: chip.trailingIcon
                size: Tokens.icon.sm
                color: chip.selected ? Colors.textOnAccentAltContainer : Colors.textMuted
            }
        }
        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: I18n.tr("THIS WALLPAPER")
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
            font.weight: Tokens.weight.semibold
            font.letterSpacing: 0.6
        }
        Item { Layout.fillWidth: true }
        Text {
            visible: !!root.override
            text: I18n.tr("Custom ·")
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
        }
        Rectangle {
            visible: !!root.override
            implicitHeight: resetRow.implicitHeight + Tokens.space.hair * 2
            implicitWidth: resetRow.implicitWidth + Tokens.space.xs * 2
            radius: Tokens.radius.sm
            color: "transparent"
            StateLayer { hovered: resetMouse.containsMouse; pressed: resetMouse.pressed; contentColor: Colors.accent }
            Row {
                id: resetRow
                anchors.centerIn: parent
                spacing: Tokens.space.hair
                Icon { name: "restart_alt"; size: Tokens.icon.sm; color: Colors.accent }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("Reset")
                    color: Colors.accent
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                    font.weight: Tokens.weight.semibold
                }
            }
            MouseArea {
                id: resetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.resetRequested()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: I18n.tr("Base color")
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
        }
        Item { Layout.fillWidth: true }
        Text {
            text: root.noColor ? I18n.tr("no clear color in the image") : (root.seed === root.candidates[0] ? I18n.tr("dominant") : I18n.tr("chosen"))
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
        }
    }
    Row {
        spacing: root.noColor ? Tokens.space.sm : Tokens.space.md
        Repeater {
            model: root.swatches
            Item {
                id: sw
                required property string modelData
                required property int index
                readonly property bool sel: sw.modelData.toLowerCase() === root.seed
                width: root.noColor ? Tokens.px(28) : Tokens.px(32)
                height: width + 7
                // Anillo del elegido.
                Rectangle {
                    width: sw.width; height: sw.width; radius: width / 2
                    color: "transparent"
                    border.width: sw.sel ? 2 : 0
                    border.color: Colors.accent
                }
                Rectangle {
                    x: sw.sel ? 4 : 0; y: x
                    width: sw.width - (sw.sel ? 8 : 0); height: width; radius: width / 2
                    color: sw.modelData
                    border.color: Colors.tint(Colors.text, Tokens.tint.track)
                    scale: swMouse.containsMouse && !sw.sel ? 1.08 : 1
                    Behavior on scale { NumberAnimation { duration: Tokens.motion.fast } }
                }
                // Punto del dominante.
                Rectangle {
                    visible: !root.noColor && sw.index === 0
                    x: (sw.width - width) / 2; y: sw.width + 3
                    width: 4; height: 4; radius: 2
                    color: Colors.textMuted
                }
                MouseArea {
                    id: swMouse
                    width: sw.width; height: sw.width
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!sw.sel) root.seedChosen(sw.modelData.toLowerCase())
                }
            }
        }
    }

    Text {
        Layout.topMargin: Tokens.space.hair
        text: I18n.tr("Scheme")
        color: Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
    }
    Flow {
        Layout.fillWidth: true
        spacing: Tokens.space.xs
        Chip {
            text: I18n.tr("Default")
            selected: root.overrideScheme === ""
            onClicked: if (!selected) root.schemeChosen("")
        }
        Repeater {
            model: root.mainSchemes
            Chip {
                required property string modelData
                text: root.schemeNames[modelData]
                selected: root.overrideScheme === modelData
                onClicked: if (!selected) root.schemeChosen(modelData)
            }
        }
        // Con un esquema de "Mas..." elegido, el chip lo nombra.
        Chip {
            text: root.moreSelected ? root.schemeNames[root.overrideScheme] : I18n.tr("More")
            selected: root.moreSelected
            trailingIcon: root.showMore ? "expand_less" : "expand_more"
            onClicked: root.showMore = !root.showMore
        }
    }
    Flow {
        visible: root.showMore
        Layout.fillWidth: true
        spacing: Tokens.space.xs
        Repeater {
            model: root.moreSchemes
            Chip {
                required property string modelData
                text: root.schemeNames[modelData]
                selected: root.overrideScheme === modelData
                onClicked: {
                    if (!selected) root.schemeChosen(modelData);
                    root.showMore = false;
                }
            }
        }
    }
}
