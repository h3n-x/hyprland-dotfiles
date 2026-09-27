// Campo de busqueda (Fase 4 B10): el mismo aspecto que el del Picker
// (contenedor mas alto, icono, borde primary con foco), como componente
// propio. keyHandler(event) recibe las teclas antes que el campo (true = la
// consume).
import QtQuick
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: box
    property string placeholder: ""
    property var keyHandler: null
    property alias text: input.text
    readonly property bool hasFocus: input.activeFocus

    function focusInput(): void {
        input.forceActiveFocus();
    }

    implicitHeight: Tokens.row.heightLarge
    radius: Tokens.radius.md
    color: Colors.surfaceHighest
    border.color: input.activeFocus ? Colors.accent : Colors.divider
    border.width: 1
    Behavior on border.color { ColorAnimation { duration: Tokens.motion.fast } }

    Icon {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: Tokens.space.md
        anchors.verticalCenter: parent.verticalCenter
        name: "search"
        color: Colors.textMuted
    }
    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Tokens.space.md + icon.width + Tokens.space.sm
        anchors.rightMargin: Tokens.space.md
        verticalAlignment: TextInput.AlignVCenter
        color: Colors.text
        selectionColor: Colors.accent
        selectedTextColor: Colors.textOnAccent
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.title
        clip: true
        // Cursor fijo (sin parpadeo): el parpadeo de serie repinta la tarjeta
        // entera dos veces por segundo, ~1 % de un nucleo con el panel quieto
        // (medido en la sonda B10); un cursor propio no parpadea.
        cursorDelegate: Rectangle {
            width: 2
            color: Colors.accent
            visible: input.cursorVisible
        }
        Keys.onPressed: (event) => {
            if (box.keyHandler && box.keyHandler(event)) event.accepted = true;
        }
    }
    Text {
        visible: input.text.length === 0
        anchors.left: parent.left
        anchors.leftMargin: input.anchors.leftMargin
        anchors.verticalCenter: parent.verticalCenter
        text: box.placeholder
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.title
    }
}
