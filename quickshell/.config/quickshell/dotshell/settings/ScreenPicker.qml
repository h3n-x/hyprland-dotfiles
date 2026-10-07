// En que pantallas va la barra (Fase 11 B1, bar.screens): un interruptor por
// pantalla conectada. Todas encendidas = lista vacia (tambien las que se
// conecten despues); la ultima no se puede apagar. Cada pantalla se guarda
// como "desc:<fabricante> <modelo>" si lo tiene (estable entre puertos), si
// no por su conector (BarVisibility.screenKey, el mismo criterio que la barra).
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, BarVisibility.qml
import "../modules"

Column {
    id: picker

    property var value: []
    signal edited(var list)

    readonly property var screens: Quickshell.screens
    function on(s: var): bool {
        return picker.value.length === 0 || picker.value.indexOf(s.name) >= 0 || picker.value.indexOf(BarVisibility.screenKey(s)) >= 0;
    }
    function toggle(s: var): void {
        const now = picker.screens.filter(x => picker.on(x));
        const next = picker.on(s) ? now.filter(x => x !== s) : now.concat([s]);
        if (next.length === 0) return; // la ultima no
        picker.edited(next.length === picker.screens.length ? [] : next.map(x => BarVisibility.screenKey(x)));
    }

    spacing: Tokens.space.xs

    Repeater {
        model: picker.screens
        RowLayout {
            id: line
            required property var modelData
            width: picker.width
            spacing: Tokens.space.md
            Text {
                Layout.fillWidth: true
                text: line.modelData.name + ([line.modelData.manufacturer, line.modelData.model].filter(x => x).length
                    ? " · " + [line.modelData.manufacturer, line.modelData.model].filter(x => x).join(" ") : "")
                elide: Text.ElideRight
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
            }
            Switch {
                activeFocusOnTab: true
                checked: picker.on(line.modelData)
                onToggled: picker.toggle(line.modelData)
            }
        }
    }
}
