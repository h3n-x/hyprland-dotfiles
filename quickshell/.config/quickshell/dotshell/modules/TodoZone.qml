// Zona Tareas de Inicio (Fase 11 B5, P11.6): una lista simple (TodoState:
// ~/.local/state/dotfiles/todo.json). Arriba el campo "Nueva tarea" (Enter la
// agrega), despues las pendientes (clic = hecha, la cruz al pasar el raton la
// quita) y, plegadas, las hechas ("Limpiar" las borra). Ancha: dos columnas.
//
// Teclado: en el campo, las teclas son suyas; Esc lo deja (done). Enter sobre
// la zona elegida con Tab entra al campo (focusField).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, TodoState.qml

ColumnLayout {
    id: root
    property bool active: false
    property bool wide: false
    readonly property real ideal: root.implicitHeight
    // Cuantas filas se ven antes de desplazar.
    readonly property int maxRows: root.wide ? 5 : 6
    property bool showDone: false
    signal done()
    spacing: Tokens.space.sm

    Subscription { demand: TodoState.demand; active: root.active }

    function focusField(): void {
        field.focusInput();
    }

    ZoneTitle {
        Layout.fillWidth: true
        text: I18n.tr("Tasks")
        detail: TodoState.problem ? "· " + TodoState.problem
            : TodoState.open.length ? "· " + I18n.trn("%n pending", "%n pending", TodoState.open.length) : ""
    }
    SearchField {
        id: field
        Layout.fillWidth: true
        size: "regular"
        icon: "add"
        placeholder: TodoState.readOnly ? I18n.tr("Read only") : I18n.tr("New task")
        enabled: TodoState.loaded && !TodoState.readOnly
        keyHandler: (event) => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (TodoState.add(field.text)) field.text = "";
                return true;
            }
            if (event.key === Qt.Key_Escape) {
                root.done();
                return true;
            }
            return false;
        }
    }

    // Pendientes (y, desplegadas, las hechas).
    Flickable {
        id: flick
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(grid.implicitHeight, root.maxRows * (Tokens.row.height + grid.rowSpacing))
        visible: grid.implicitHeight > 0
        contentHeight: grid.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        GridLayout {
            id: grid
            width: flick.width
            columns: root.wide ? 2 : 1
            columnSpacing: Tokens.space.md
            rowSpacing: 0
            Repeater {
                model: TodoState.open.concat(root.showDone ? TodoState.done : [])
                Item {
                    id: task
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: Tokens.row.height
                    StateLayer { radius: Tokens.radius.sm; hovered: taskMouse.containsMouse; pressed: taskMouse.pressed }
                    MouseArea {
                        id: taskMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TodoState.toggle(task.modelData.id)
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.space.xs
                        anchors.rightMargin: Tokens.space.xs
                        spacing: Tokens.space.sm
                        Icon {
                            name: task.modelData.done ? "check_circle" : "radio_button_unchecked"
                            filled: task.modelData.done
                            size: Tokens.icon.sm
                            color: task.modelData.done ? Colors.accent : Colors.textMuted
                        }
                        Text {
                            Layout.fillWidth: true
                            text: task.modelData.text
                            elide: Text.ElideRight
                            color: task.modelData.done ? Colors.textMuted : Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.strikeout: task.modelData.done
                        }
                        // Quitar (al pasar el raton).
                        Item {
                            implicitWidth: Tokens.icon.sm + Tokens.space.xs
                            implicitHeight: implicitWidth
                            opacity: taskMouse.containsMouse || removeMouse.containsMouse ? 1 : 0
                            StateLayer { radius: width / 2; hovered: removeMouse.containsMouse; pressed: removeMouse.pressed }
                            Icon { anchors.centerIn: parent; name: "close"; size: Tokens.icon.sm - 2; color: Colors.textMuted }
                            MouseArea {
                                id: removeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: TodoState.remove(task.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
    // Sin pendientes: una linea tranquila (no un hueco).
    Text {
        visible: TodoState.loaded && !TodoState.open.length && !root.showDone
        Layout.fillWidth: true
        text: TodoState.done.length ? I18n.tr("All done.") : I18n.tr("Nothing pending.")
        color: Colors.border
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
    }
    // Hechas: plegadas en una linea; Limpiar las borra.
    RowLayout {
        visible: TodoState.done.length > 0
        Layout.fillWidth: true
        spacing: Tokens.space.sm
        Text {
            text: root.showDone ? I18n.trn("Hide %n done", "Hide %n done", TodoState.done.length) : I18n.trn("%n done", "%n done", TodoState.done.length)
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
            font.weight: Tokens.weight.medium
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showDone = !root.showDone
            }
        }
        Item { Layout.fillWidth: true }
        Text {
            text: I18n.trc("tasks", "Clear")
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
            font.weight: Tokens.weight.medium
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    TodoState.clearDone();
                    root.showDone = false;
                }
            }
        }
    }
    // Junto a una zona mas alta: lo de arriba queda arriba.
    Item { Layout.fillHeight: true }
}
