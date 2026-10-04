// Ruta editable (Fase 10 B1): el valor en monoespaciada, recortado por el
// medio; clic = editar. Enter guarda, Esc descarta. No valida nada: el
// consumidor la pasa al motor de opciones, que expande "~" y rechaza lo que no
// es una ruta absoluta (el motivo se muestra en la fila). El selector de
// carpetas del portal llega mas adelante.
//
//   PathField { value: x; onEdited: v => x = v }
import QtQuick
import Quickshell
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root

    property string value: ""
    signal edited(string value)

    // Con la carpeta personal abreviada, como se escribe.
    readonly property string home: Quickshell.env("HOME")
    function pretty(p: string): string {
        return root.home && p.startsWith(root.home + "/") ? "~" + p.slice(root.home.length) : p;
    }

    implicitWidth: 300
    implicitHeight: Tokens.pill.height
    radius: Tokens.radius.sm
    color: input.activeFocus ? Colors.surfaceHighest : "transparent"
    border.color: input.activeFocus || root.activeFocus ? Colors.accent : Colors.divider
    // Con el teclado: Tab llega aca, Enter empieza a editar.
    activeFocusOnTab: true
    Keys.onReturnPressed: root.begin()
    Keys.onEnterPressed: root.begin()

    function begin(): void {
        input.text = root.pretty(root.value);
        input.forceActiveFocus();
        input.selectAll();
    }

    StateLayer {
        hovered: mouse.containsMouse && !input.activeFocus
    }
    Icon {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: Tokens.space.sm
        anchors.verticalCenter: parent.verticalCenter
        name: "folder"
        size: Tokens.icon.sm
        color: Colors.textMuted
    }
    Text {
        visible: !input.activeFocus
        anchors.left: icon.right
        anchors.leftMargin: Tokens.space.sm
        anchors.right: parent.right
        anchors.rightMargin: Tokens.space.sm
        anchors.verticalCenter: parent.verticalCenter
        text: root.pretty(root.value)
        elide: Text.ElideMiddle
        color: Colors.text
        font.family: Tokens.font.mono
        font.pixelSize: Tokens.type.label
    }
    TextInput {
        id: input
        visible: activeFocus
        anchors.left: icon.right
        anchors.leftMargin: Tokens.space.sm
        anchors.right: parent.right
        anchors.rightMargin: Tokens.space.sm
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: Colors.text
        selectionColor: Colors.accentContainer
        selectedTextColor: Colors.textOnAccentContainer
        font.family: Tokens.font.mono
        font.pixelSize: Tokens.type.label
        selectByMouse: true
        // Cursor fijo, como SearchField: el parpadeo repinta sin parar.
        cursorDelegate: Rectangle {
            width: 2
            color: Colors.accent
            visible: input.cursorVisible
        }
        Keys.onEscapePressed: (event) => {
            event.accepted = true;
            root.forceActiveFocus();
        }
        onAccepted: {
            const t = input.text.trim();
            root.forceActiveFocus();
            if (t && t !== root.pretty(root.value)) root.edited(t);
        }
    }
    MouseArea {
        id: mouse
        visible: !input.activeFocus
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onClicked: root.begin()
    }
}
