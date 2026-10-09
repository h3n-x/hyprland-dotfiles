// Ruta editable (Fase 10 B1): el valor en monoespaciada, recortado por el
// medio; clic = editar. Enter guarda, Esc descarta. No valida nada: el
// consumidor la pasa al motor de opciones, que expande "~" y rechaza lo que no
// es una ruta absoluta (el motivo se muestra en la fila). Con pick ("image"
// o "dir"), el boton "Elegir…" abre el selector del portal (scripts/pick-file,
// Fase 10 B2).
//
//   PathField { value: x; pick: "dir"; onEdited: v => x = v }
//
// Fase 11 B5: tambien el campo de texto corto del centro (plain: true; p. ej.
// el nombre del saludo): letra normal, sin "~", y vacio es un valor (el
// placeholder dice que significa).
import QtQuick
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root

    property string value: ""
    // "" (solo escribir), "image" o "dir".
    property string pick: ""
    // Texto corto en vez de ruta.
    property bool plain: false
    property string placeholder: ""
    signal edited(string value)

    // Selector del portal: corre solo mientras esta abierto.
    property Process picker: Process {
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/pick-file", root.pick === "dir" ? "--folder" : "--images",
            "--start", root.value.indexOf("/") >= 0 ? root.value.slice(0, root.pick === "dir" ? undefined : root.value.lastIndexOf("/")) : ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim();
                if (p && p !== root.value) root.edited(p);
            }
        }
    }

    // Con la carpeta personal abreviada, como se escribe.
    readonly property string home: Quickshell.env("HOME")
    function pretty(p: string): string {
        if (root.plain) return p;
        return root.home && p.startsWith(root.home + "/") ? "~" + p.slice(root.home.length) : p;
    }

    implicitWidth: Tokens.px(300) + (pickBtn.visible ? pickBtn.width : 0)
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
        name: root.plain ? "edit" : "folder"
        size: Tokens.icon.sm
        color: Colors.textMuted
    }
    Text {
        visible: !input.activeFocus
        anchors.left: icon.right
        anchors.leftMargin: Tokens.space.sm
        anchors.right: pickBtn.visible ? pickBtn.left : parent.right
        anchors.rightMargin: Tokens.space.sm
        anchors.verticalCenter: parent.verticalCenter
        text: root.value ? root.pretty(root.value) : root.placeholder
        elide: Text.ElideMiddle
        color: root.value ? Colors.text : Colors.textMuted
        font.family: root.plain ? Tokens.font.ui : Tokens.font.mono
        font.pixelSize: Tokens.type.label
    }
    TextInput {
        id: input
        visible: activeFocus
        anchors.left: icon.right
        anchors.leftMargin: Tokens.space.sm
        anchors.right: pickBtn.visible ? pickBtn.left : parent.right
        anchors.rightMargin: Tokens.space.sm
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: Colors.text
        selectionColor: Colors.accentContainer
        selectedTextColor: Colors.textOnAccentContainer
        font.family: root.plain ? Tokens.font.ui : Tokens.font.mono
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
            if ((t || root.plain) && t !== root.pretty(root.value)) root.edited(t);
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
    // "Elegir…": el selector del portal (encima del area de edicion).
    Item {
        id: pickBtn
        visible: root.pick !== ""
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: pickRow.implicitWidth + 2 * Tokens.space.md
        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height - 2 * Tokens.space.xs
            color: Colors.divider
        }
        StateLayer {
            radius: Tokens.radius.sm
            hovered: pickMouse.containsMouse
            pressed: pickMouse.pressed || root.picker.running
        }
        Row {
            id: pickRow
            anchors.centerIn: parent
            spacing: Tokens.space.xs
            Icon { anchors.verticalCenter: parent.verticalCenter; name: root.pick === "dir" ? "folder_open" : "image"; size: Tokens.icon.sm; color: Colors.textMuted }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Elegir…"
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.weight: Tokens.weight.semibold
            }
        }
        MouseArea {
            id: pickMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (!root.picker.running) root.picker.running = true
        }
    }
}
