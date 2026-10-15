// Resultados de la busqueda del centro de configuracion (Fase 10 B1): hasta
// seis opciones bajo el campo (SettingsModel.search: esquema, sin tildes),
// con su pagina y seccion. Flechas para moverse, Enter o clic para ir:
// chosen(key) y la ventana la muestra iluminada en su pagina.
import QtQuick
import QtQuick.Effects
import ".." // Colors.qml, Tokens.qml
import "../modules"

Rectangle {
    id: box

    required property SettingsModel model
    property string query: ""
    property int current: 0
    readonly property var results: box.model.search(box.query, 6)
    readonly property bool empty: box.query.trim() !== "" && box.results.length === 0
    signal chosen(string key)

    onQueryChanged: box.current = 0
    // Teclas del campo (SearchField.keyHandler): true = consumida.
    function handleKey(event): bool {
        if (!box.visible) return false;
        if (event.key === Qt.Key_Down) {
            box.current = Math.min(box.results.length - 1, box.current + 1);
            return true;
        }
        if (event.key === Qt.Key_Up) {
            box.current = Math.max(0, box.current - 1);
            return true;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (box.results[box.current]) box.chosen(box.results[box.current]);
            return true;
        }
        return false;
    }

    visible: box.query.trim() !== ""
    implicitHeight: col.implicitHeight + 2 * Tokens.space.sm
    radius: Tokens.radius.lg
    color: Colors.surfaceHigh
    border.color: Colors.divider
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: 32
        shadowBlur: Tokens.shadow.lg.blur / 32
        shadowVerticalOffset: Tokens.shadow.lg.offsetY
        shadowOpacity: Tokens.shadow.lg.opacity
        shadowColor: Colors.shadow
    }

    Column {
        id: col
        x: Tokens.space.sm
        y: Tokens.space.sm
        width: parent.width - 2 * Tokens.space.sm

        Text {
            visible: box.empty
            leftPadding: Tokens.space.md
            topPadding: Tokens.space.sm
            bottomPadding: Tokens.space.sm
            text: I18n.tr("Nothing matches “%1”", box.query.trim())
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
        }
        Repeater {
            model: box.results
            Rectangle {
                id: res
                required property string modelData
                required property int index
                readonly property var meta: box.model.keys[res.modelData] || ({})
                readonly property bool sel: res.index === box.current
                width: col.width
                height: resInfo.implicitHeight + 2 * Tokens.space.sm
                radius: Tokens.radius.md
                color: res.sel ? Colors.accentAltContainer : "transparent"
                StateLayer { hovered: resMouse.containsMouse; pressed: resMouse.pressed; contentColor: res.sel ? Colors.textOnAccentAltContainer : Colors.text }
                Column {
                    id: resInfo
                    x: Tokens.space.md
                    width: parent.width - 2 * Tokens.space.md - enterHint.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space.hair
                    Text {
                        width: parent.width
                        text: res.meta.label || res.modelData
                        elide: Text.ElideRight
                        color: res.sel ? Colors.textOnAccentAltContainer : Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.weight: Tokens.weight.medium
                    }
                    Text {
                        width: parent.width
                        text: box.model.categoryLabel(res.meta.category) + (res.meta.sectionLabel ? " · " + res.meta.sectionLabel : "")
                        elide: Text.ElideRight
                        color: res.sel ? Colors.textOnAccentAltContainer : Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                    }
                }
                Text {
                    id: enterHint
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.space.md
                    anchors.verticalCenter: parent.verticalCenter
                    text: res.sel ? I18n.trc("key", "Enter") : ""
                    color: Colors.textOnAccentAltContainer
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                }
                MouseArea {
                    id: resMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: box.current = res.index
                    onClicked: box.chosen(res.modelData)
                }
            }
        }
    }
}
