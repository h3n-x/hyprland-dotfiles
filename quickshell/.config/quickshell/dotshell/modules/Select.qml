// Selector de una opcion entre varias (Fase 10 B1; sacado del "Esquema
// predeterminado" del panel "Tema global", unica copia): la pildora con el
// valor actual. La lista se despliega dentro de la ventana con SelectList,
// que el consumidor pone donde quepa (debajo de la fila); `open` los une.
//
//   Select { id: s; options: [["a", "Uno"], ["b", "Dos"]]; current: x }
//   SelectList { visible: s.open; options: s.options; current: s.current
//                onChosen: v => { x = v; s.open = false } }
import QtQuick
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root

    property var options: []
    property var current
    property bool open: false

    function labelOf(v): string {
        for (const e of root.options)
            if (e[0] === v) return e[1];
        return String(v);
    }

    implicitHeight: Tokens.pill.height - Tokens.space.xs
    implicitWidth: pickRow.implicitWidth + Tokens.space.md * 2
    radius: Tokens.radius.pill(height)
    color: root.open ? Colors.accentAltContainer : "transparent"
    border.color: root.open ? "transparent" : root.activeFocus ? Colors.accent : Colors.divider

    // Teclado (si quien lo usa le da activeFocusOnTab): Enter o Espacio abre y
    // cierra la lista; las flechas eligen la opcion vecina sin abrirla.
    signal chosen(var value)
    function step(dir: int): void {
        let i = root.options.findIndex(o => o[0] === root.current);
        i = Math.max(0, Math.min(root.options.length - 1, i + dir));
        if (root.options[i] && root.options[i][0] !== root.current) root.chosen(root.options[i][0]);
    }
    Keys.onReturnPressed: root.open = !root.open
    Keys.onEnterPressed: root.open = !root.open
    Keys.onSpacePressed: root.open = !root.open
    Keys.onUpPressed: root.step(-1)
    Keys.onDownPressed: root.step(1)
    Keys.onEscapePressed: (event) => {
        event.accepted = root.open;
        root.open = false;
    }
    StateLayer { hovered: pickMouse.containsMouse; pressed: pickMouse.pressed }
    Row {
        id: pickRow
        anchors.centerIn: parent
        spacing: Tokens.space.hair
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.labelOf(root.current)
            color: root.open ? Colors.textOnAccentAltContainer : Colors.text
            font.family: Tokens.font.ui
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
