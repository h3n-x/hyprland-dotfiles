// Control segmentado (Fase 10 B1; sacado del panel "Tema global" de la
// galeria, unica copia): una pildora con un segmento por opcion y la
// seleccion como pildora interior con un check. Lo usan el tema global de la
// galeria y el centro de configuracion. No guarda estado: el consumidor da
// `current` y reacciona a chosen(value).
//
//   Segmented { options: [[0, "Estándar"], [1, "Máximo"]]; current: x; onChosen: v => x = v }
//
// `options` es una lista de [valor, texto]; los valores numericos se comparan
// con una tolerancia (0.33 guardado como 0.330000…).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root

    property var options: []
    property var current
    signal chosen(var value)

    function same(a, b): bool {
        return (typeof a === "number" && typeof b === "number") ? Math.abs(a - b) < 0.01 : a === b;
    }

    // Segmentos de igual ancho; el ancho natural cabe la etiqueta mas larga
    // con su check (quien lo pone en un Layout con fillWidth decide el resto).
    implicitWidth: options.length * (widest.advanceWidth + Tokens.icon.sm + Tokens.space.hair + 2 * Tokens.space.md) + 6
    implicitHeight: Tokens.pill.height + Tokens.space.xs
    radius: Tokens.radius.pill(height)
    color: "transparent"
    border.color: root.activeFocus ? Colors.accent : Colors.divider

    // Teclado (si quien lo usa le da activeFocusOnTab): flechas a la opcion vecina.
    function step(dir: int): void {
        let i = root.options.findIndex(o => root.same(root.current, o[0]));
        i = Math.max(0, Math.min(root.options.length - 1, i + dir));
        if (root.options[i] && !root.same(root.current, root.options[i][0])) root.chosen(root.options[i][0]);
    }
    Keys.onLeftPressed: root.step(-1)
    Keys.onRightPressed: root.step(1)
    TextMetrics {
        id: widest
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
        font.weight: Tokens.weight.semibold
        text: root.options.reduce((a, o) => String(o[1]).length > a.length ? String(o[1]) : a, "")
    }
    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 0
        Repeater {
            model: root.options
            Item {
                id: seg
                required property var modelData
                required property int index
                readonly property bool sel: root.same(root.current, seg.modelData[0])
                Layout.fillWidth: true
                Layout.fillHeight: true
                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.radius.pill(height)
                    color: seg.sel ? Colors.accentAltContainer : "transparent"
                    StateLayer {
                        radius: parent.radius
                        hovered: segMouse.containsMouse
                        pressed: segMouse.pressed
                        contentColor: seg.sel ? Colors.textOnAccentAltContainer : Colors.textMuted
                    }
                }
                Row {
                    anchors.centerIn: parent
                    spacing: Tokens.space.hair
                    Icon { visible: seg.sel; name: "check"; size: Tokens.icon.sm; color: Colors.textOnAccentAltContainer }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: seg.modelData[1]
                        color: seg.sel ? Colors.textOnAccentAltContainer : Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        font.weight: seg.sel ? Tokens.weight.semibold : Tokens.weight.regular
                    }
                }
                MouseArea {
                    id: segMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!seg.sel) root.chosen(seg.modelData[0])
                }
            }
        }
    }
}
