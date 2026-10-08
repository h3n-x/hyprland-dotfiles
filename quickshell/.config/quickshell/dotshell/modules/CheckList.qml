// Varias opciones de una lista, cada una con su interruptor (Fase 11 B5b,
// kind "checks" del esquema: una lista de valores de un enum, p. ej.
// dashboard.now.kinds). Las filas van en el orden del esquema y el valor se
// guarda en ese orden. No guarda estado: el consumidor da `value` y recibe
// edited(lista).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml

ColumnLayout {
    id: root
    // [[valor, texto], ...] en el orden del esquema.
    property var options: []
    property var value: []
    signal edited(var list)

    implicitWidth: 360
    spacing: 0

    function toggle(v: string): void {
        const on = root.value.indexOf(v) >= 0;
        root.edited(root.options.map(o => o[0]).filter(x => x === v ? !on : root.value.indexOf(x) >= 0));
    }

    Repeater {
        model: root.options
        RowLayout {
            id: opt
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: Tokens.row.height
            spacing: Tokens.space.md
            Text {
                Layout.fillWidth: true
                text: opt.modelData[1]
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
                elide: Text.ElideRight
            }
            Switch {
                activeFocusOnTab: true
                checked: root.value.indexOf(opt.modelData[0]) >= 0
                onToggled: root.toggle(opt.modelData[0])
            }
        }
    }
}
