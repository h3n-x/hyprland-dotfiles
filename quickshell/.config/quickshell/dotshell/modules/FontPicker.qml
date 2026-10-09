// Selector de fuente (Fase 10 B2): la pildora muestra la fuente elegida
// escrita en ella misma; la lista (FontList) va debajo de la fila, como la de
// Select. Las familias instaladas salen de fc-list una sola vez, al abrir:
// las que cubren el castellano (sin simbolos, emoji, iconos ni las variantes
// CJK), proporcionales para la interfaz y monoespaciadas para el codigo. No guarda estado: el consumidor da
// `current` y recibe chosen(familia).
//
//   FontPicker { id: f; mono: false; current: x }
//   FontList { visible: f.open; families: f.families; current: f.current
//              onChosen: v => { x = v; f.open = false } }
import QtQuick
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root

    property string current: ""
    property bool mono: false
    property bool open: false
    property var families: []
    signal chosen(string family)

    readonly property bool installed: root.families.length === 0 || root.families.indexOf(root.current) >= 0

    onOpenChanged: if (root.open && root.families.length === 0 && !lister.running) lister.running = true
    property Process lister: Process {
        command: ["fc-list", ":lang=es", "--format", "%{family[0]}|%{spacing}\\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                const skip = /symbol|emoji|icon|material|webdings|wingdings|math|cjk|dingbat|d050000l/i;
                const out = {};
                for (const l of this.text.split("\n")) {
                    const [f, sp] = l.split("|");
                    if (!f || skip.test(f)) continue;
                    if ((sp === "100" || /\bmono\b/i.test(f)) === root.mono) out[f] = true;
                }
                root.families = Object.keys(out).sort((a, b) => a.localeCompare(b));
            }
        }
    }

    implicitHeight: Tokens.pill.height - Tokens.space.xs
    implicitWidth: Math.min(Tokens.px(260), pickRow.implicitWidth + Tokens.space.md * 2)
    radius: Tokens.radius.pill(height)
    color: root.open ? Colors.accentAltContainer : "transparent"
    border.color: root.open ? "transparent" : root.activeFocus ? Colors.accent : Colors.divider
    Keys.onReturnPressed: root.open = !root.open
    Keys.onEnterPressed: root.open = !root.open
    Keys.onSpacePressed: root.open = !root.open
    StateLayer { hovered: pickMouse.containsMouse; pressed: pickMouse.pressed; focused: root.activeFocus }
    Row {
        id: pickRow
        anchors.centerIn: parent
        spacing: Tokens.space.hair
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Tokens.px(260) - Tokens.space.md * 2 - Tokens.icon.sm)
            elide: Text.ElideRight
            text: root.current
            color: root.open ? Colors.textOnAccentAltContainer : Colors.text
            font.family: root.current
            font.pixelSize: Tokens.type.label
        }
        Icon {
            name: root.open ? "arrow_drop_up" : "arrow_drop_down"
            size: Tokens.icon.sm
            color: root.open ? Colors.textOnAccentAltContainer : Colors.textMuted
        }
    }
    MouseArea {
        id: pickMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }
}
