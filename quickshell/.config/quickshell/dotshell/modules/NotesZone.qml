// Zona Notas de Inicio (Fase 11 B5, P11.6): una nota de texto plano
// (NotesState: ~/.local/state/dotfiles/notes.json), se guarda sola 500 ms
// despues de dejar de escribir; "Guardado" en el titulo.
//
// Teclado: mientras se escribe, las teclas son de la nota (las letras de las
// vistas no saltan); Esc deja la nota (done) y desde ahi Esc hace lo de
// siempre. Enter sobre la zona elegida con Tab entra a escribir (focusField).
// Cursor fijo, sin parpadeo (el de serie repinta dos veces por segundo).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, NotesState.qml

ColumnLayout {
    id: root
    // El dashboard se ve: solo entonces se pide (y se lee) la nota.
    property bool active: false
    property bool wide: false
    property int baseHeight: 116
    // Alto que pide: crece con el texto hasta un tope, despues se desplaza.
    readonly property real ideal: Math.max(root.baseHeight, Math.min(title.implicitHeight + root.spacing + area.contentHeight + Tokens.space.sm, 300))
    signal done()
    spacing: Tokens.space.sm

    Subscription { demand: NotesState.demand; active: root.active }

    function focusField(): void {
        area.forceActiveFocus();
        area.cursorPosition = area.length;
    }

    // Lo guardado entra al campo al cargar o si cambio en otra pantalla; nunca
    // mientras se escribe (moveria el cursor).
    property bool syncing: false
    function pull(): void {
        if (area.activeFocus || area.text === NotesState.text) return;
        root.syncing = true;
        area.text = NotesState.text;
        root.syncing = false;
    }
    Connections {
        target: NotesState
        function onTextChanged() { root.pull(); }
        function onLoadedChanged() { root.pull(); }
    }
    Component.onCompleted: root.pull()

    ZoneTitle {
        id: title
        Layout.fillWidth: true
        text: "Notas"
        detail: NotesState.problem ? "· " + NotesState.problem
            : NotesState.saving ? "· guardando…" : area.length && NotesState.updated ? "· guardado" : ""
    }
    Flickable {
        id: flick
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: area.contentHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        TextEdit {
            id: area
            width: flick.width
            wrapMode: TextEdit.Wrap
            readOnly: NotesState.readOnly || !NotesState.loaded
            selectByMouse: true
            color: Colors.text
            selectionColor: Colors.accent
            selectedTextColor: Colors.textOnAccent
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
            cursorDelegate: Rectangle {
                width: 2
                color: Colors.accent
                visible: area.cursorVisible
            }
            onTextChanged: if (!root.syncing) NotesState.setText(area.text)
            // El cursor siempre a la vista.
            onCursorRectangleChanged: {
                const r = area.cursorRectangle;
                if (r.y < flick.contentY) flick.contentY = r.y;
                else if (r.y + r.height > flick.contentY + flick.height) flick.contentY = r.y + r.height - flick.height;
            }
            Keys.onEscapePressed: {
                area.deselect();
                root.done();
            }
            Text {
                visible: !area.length && !area.activeFocus
                text: "Escribe algo…"
                color: Colors.border
                font: area.font
            }
        }
        // Clic en el hueco de abajo: a escribir al final.
        MouseArea {
            y: area.contentHeight
            width: flick.width
            height: Math.max(0, flick.height - area.contentHeight)
            cursorShape: Qt.IBeamCursor
            onClicked: root.focusField()
        }
    }
}
