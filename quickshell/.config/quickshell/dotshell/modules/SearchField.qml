// Campo de busqueda (Fase 4 B10; unico de la shell desde la Fase 8 B3, P8.8):
// lo usan el Picker (lanzador, portapapeles, emoji, ventanas), la guia de
// atajos, la galeria y la busqueda de ciudad del clima, y lo usara la
// busqueda global del centro de configuracion (P10), y, con su icono, el
// campo de una tarea nueva de Inicio (Fase 11 B5).
//
// keyHandler(event) recibe cada tecla antes que el texto: true = la consume;
// false = sigue al campo (las flechas izquierda/derecha mueven el cursor).
// keyReleaseHandler(event) igual para las teclas soltadas (soltar Super en el
// selector de ventanas). El campo no decide nada por su cuenta: Enter y Esc
// son de quien lo usa.
//
//   SearchField { placeholder: "Buscar…"; size: "regular"; keyHandler: (e) => … }
import QtQuick
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: box
    property string placeholder: ""
    // Icono de la izquierda (la lupa; "add" en el campo de una tarea nueva, Fase 11 B5).
    property string icon: "search"
    property var keyHandler: null
    property var keyReleaseHandler: null
    // "large": tarjetas de busqueda (Picker, guia). "regular": dentro de una
    // vista (galeria, clima).
    property string size: "large"
    property alias text: input.text
    readonly property bool hasFocus: input.activeFocus
    readonly property bool large: box.size === "large"

    function focusInput(): void {
        input.forceActiveFocus();
    }

    implicitHeight: box.large ? Tokens.row.heightLarge : Tokens.row.height
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
        name: box.icon
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
        font.pixelSize: box.large ? Tokens.type.title : Tokens.type.body
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
        Keys.onReleased: (event) => {
            if (box.keyReleaseHandler && box.keyReleaseHandler(event)) event.accepted = true;
        }
    }
    HoverHandler { cursorShape: Qt.IBeamCursor }
    Text {
        visible: input.text.length === 0
        anchors.left: parent.left
        anchors.leftMargin: input.anchors.leftMargin
        anchors.verticalCenter: parent.verticalCenter
        text: box.placeholder
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: input.font.pixelSize
    }
}
