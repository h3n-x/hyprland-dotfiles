// Los atajos en la pagina Atajos del centro de configuracion (Fase 10 B4,
// P10.11): la misma lista que la guia (Super+/) con KeybindGroup y la misma
// busqueda (KeybindState.filter), en dos columnas. Se lee de Hyprland al
// abrir la pagina (keybinds data), sin escuchar sus eventos.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, KeybindState.qml
import "../modules"

ColumnLayout {
    id: root

    readonly property var groups: KeybindState.filter(search.text)
    readonly property int shown: root.groups.reduce((n, g) => n + g.items.length, 0)
    // Dos columnas equilibradas por cantidad de atajos.
    readonly property var cols: {
        const c = [[], []], h = [0, 0];
        for (const g of root.groups) {
            const i = h[0] <= h[1] ? 0 : 1;
            c[i].push(g);
            h[i] += g.items.length + 2;
        }
        return c;
    }

    Component.onCompleted: KeybindState.reload()

    spacing: Tokens.space.md

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space.md
        SearchField {
            id: search
            Layout.fillWidth: true
            size: "regular"
            placeholder: "Buscar un atajo (descripción o teclas)"
        }
        Text {
            text: !KeybindState.data ? "Leyendo los atajos…"
                : search.text ? (root.shown === 1 ? "1 resultado" : root.shown + " resultados")
                : KeybindState.total + " atajos"
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space.md
        Repeater {
            model: root.cols
            ColumnLayout {
                id: col
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: Tokens.space.md
                Repeater {
                    model: col.modelData
                    KeybindGroup {
                        required property var modelData
                        Layout.fillWidth: true
                        group: modelData
                    }
                }
            }
        }
    }
    Text {
        visible: !!KeybindState.data && root.shown === 0
        text: "Ningún atajo coincide con «" + search.text + "»"
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.body
    }
    Text {
        Layout.fillWidth: true
        text: "Las descripciones salen de binds.lua; para cambiar un atajo, hoy se edita ese archivo."
        wrapMode: Text.WordWrap
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.caption
    }
}
