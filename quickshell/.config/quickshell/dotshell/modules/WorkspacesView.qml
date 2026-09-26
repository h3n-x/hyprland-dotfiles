// Vista Escritorios del dashboard (Fase 4 B7): cada workspace como la
// pantalla real a escala, con la captura de cada ventana en su lugar y la
// decoracion de Hyprland (WorkspaceThumb, detailed). Los mismos slots que la
// barra, mas el workspace especial si tiene ventanas.
//
// Solo los workspaces con ventanas (y el enfocado) son miniaturas grandes: los
// vacios van al final como numeros chicos (clic: ir a ese). Debajo de cada
// miniatura, lo minimo: su numero, los iconos de sus aplicaciones y la
// principal; marcas solo cuando hay algo que decir (urgente, pantalla
// completa, flotantes). Clic en el fondo: ir al workspace; clic en una
// ventana: ir a esa ventana (DesktopState.focusWindow, la misma logica que el
// selector). En los dos casos la miniatura se levanta, las demas se velan y el
// dashboard se cierra mientras Hyprland cambia.
//
// Las capturas se toman una vez al abrir la vista y se sueltan al salir
// (Dashboard.qml la carga solo mientras se ve).
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import ".." // Colors.qml, Tokens.qml, DesktopState.qml, DashboardState.qml, AppInfo.qml

ColumnLayout {
    id: view
    property string screenName: ""
    property bool active: false
    property bool narrow: false
    spacing: Tokens.space.md

    // Con pocos escritorios ocupados, miniaturas mas grandes (2 columnas).
    readonly property int columns: view.narrow || view.tiles.length <= 2 ? 2 : 3
    readonly property var specials: Hyprland.workspaces.values.filter(w => w.id < 0 && DesktopState.windowsOf(w.id).length > 0)
    readonly property var tiles: DesktopState.slots
        .filter(w => Hyprland.focusedWorkspace === w || (!w.placeholder && DesktopState.windowsOf(w.id).some(x => !x.hidden)))
        .concat(view.specials)
    readonly property var empties: DesktopState.slots.filter(w => view.tiles.indexOf(w) < 0)
    readonly property int focusedIndex: view.tiles.findIndex(w => !w.placeholder && Hyprland.focusedWorkspace === w)
    property int selected: -1
    property int chosenId: 0

    // Al abrir: la geometria al dia (las capturas salen de ahi).
    onActiveChanged: if (view.active) {
        view.selected = -1;
        view.chosenId = 0;
        DesktopState.refresh();
    }

    function go(id: int, address: string): void {
        if (view.chosenId) return;
        view.chosenId = id;
        DashboardState.close();
        if (address) DesktopState.focusWindow(address);
        else DesktopState.focusWorkspace(id);
    }
    // Flechas en la rejilla, Enter va, 1-9 van directo (Dashboard.qml).
    function handleKey(event: var): bool {
        const n = view.tiles.length;
        const start = view.selected >= 0 ? view.selected : Math.max(0, view.focusedIndex);
        const step = event.key === Qt.Key_Left ? -1 : event.key === Qt.Key_Right ? 1
            : event.key === Qt.Key_Up ? -view.columns : event.key === Qt.Key_Down ? view.columns : 0;
        if (step !== 0) {
            view.selected = Math.max(0, Math.min(n - 1, start + step));
            return true;
        }
        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && view.selected >= 0) {
            view.go(view.tiles[view.selected].id, "");
            return true;
        }
        return false;
    }

    GridLayout {
        id: grid
        Layout.preferredWidth: view.width
        Layout.topMargin: Tokens.space.xs
        columns: view.columns
        columnSpacing: Tokens.space.lg
        rowSpacing: Tokens.space.lg
        readonly property real tileWidth: (view.width - (view.columns - 1) * columnSpacing - 8) / view.columns

        Repeater {
            model: view.tiles
            ColumnLayout {
                id: cell
                required property var modelData
                required property int index
                readonly property bool special: cell.modelData.id < 0
                readonly property var wins: DesktopState.windowsOf(cell.modelData.id).filter(w => !w.hidden)
                // La principal: la enfocada o, si no, la mas grande.
                readonly property var main: cell.wins.slice().sort((a, b) => (a.focused ? -1 : b.focused ? 1 : b.w * b.h - a.w * a.h))[0] || null
                readonly property var apps: {
                    const seen = [];
                    for (const w of cell.wins) if (seen.indexOf(w.cls) < 0) seen.push(w.cls);
                    return seen;
                }
                readonly property bool focusedWs: !cell.modelData.placeholder && Hyprland.focusedWorkspace === cell.modelData
                Layout.preferredWidth: grid.tileWidth
                spacing: Tokens.space.sm

                Item {
                    Layout.preferredWidth: grid.tileWidth
                    Layout.preferredHeight: thumb.height + 6
                    WorkspaceThumb {
                        id: thumb
                        x: 3
                        y: 3
                        width: grid.tileWidth - 6
                        height: implicitHeight
                        slot: cell.modelData
                        screenName: view.screenName
                        live: view.active
                        detailed: true
                        selected: view.selected === cell.index
                        chosen: view.chosenId === cell.modelData.id
                        veiled: view.chosenId !== 0 && view.chosenId !== cell.modelData.id
                        onPicked: view.go(cell.modelData.id, "")
                        onWindowPicked: (address) => view.go(cell.modelData.id, address)
                    }
                    // Contorno del workspace enfocado.
                    Rectangle {
                        visible: cell.focusedWs
                        anchors.fill: thumb
                        anchors.margins: -3
                        radius: Tokens.radius.sm + 3
                        color: "transparent"
                        border.width: 2
                        border.color: Colors.m3primary
                        scale: thumb.scale
                    }
                }

                // Pie: numero, aplicaciones, la principal y marcas si las hay.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.space.sm
                    opacity: view.chosenId && view.chosenId !== cell.modelData.id ? 0.4 : 1
                    Rectangle {
                        implicitWidth: Math.max(22, wsNum.implicitWidth + 12)
                        implicitHeight: 22
                        radius: 11
                        color: cell.focusedWs ? Colors.m3primary : Colors.m3surfaceContainerHighest
                        Text {
                            id: wsNum
                            anchors.centerIn: parent
                            text: cell.special ? "S" : cell.modelData.id
                            color: cell.focusedWs ? Colors.m3onPrimary : Colors.m3onSurfaceVariant
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.caption
                            font.weight: Tokens.weight.semibold
                        }
                    }
                    Repeater {
                        model: cell.apps.slice(0, 4)
                        Image {
                            required property string modelData
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            sourceSize: Qt.size(36, 36)
                            source: AppInfo.icon(modelData)
                            asynchronous: true
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: cell.special ? "Especial" + (cell.main ? " · " + AppInfo.name(cell.main.cls) : "")
                            : cell.main ? AppInfo.name(cell.main.cls) + (cell.wins.length > 1 ? " y " + (cell.wins.length - 1) + " más" : "")
                            : "Vacío"
                        color: cell.main ? Colors.m3onSurface : Colors.m3outline
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        font.weight: cell.focusedWs ? Tokens.weight.semibold : Tokens.weight.regular
                        elide: Text.ElideRight
                    }
                    // Marcas (solo si aplican).
                    Icon {
                        visible: cell.wins.some(w => w.urgent)
                        name: "error"
                        filled: true
                        size: Tokens.icon.sm
                        color: Colors.m3error
                    }
                    Icon {
                        visible: cell.wins.some(w => w.fullscreen)
                        name: "fullscreen"
                        size: Tokens.icon.sm
                        color: Colors.m3onSurfaceVariant
                    }
                    Row {
                        visible: cell.wins.some(w => w.floating)
                        spacing: 2
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: "picture_in_picture"; size: Tokens.icon.sm; color: Colors.m3onSurfaceVariant }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: cell.wins.filter(w => w.floating).length
                            color: Colors.m3onSurfaceVariant
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.caption
                        }
                    }
                }
            }
        }
    }

    // Vacios: numeros chicos, sin miniatura (no compiten con los que tienen ventanas).
    RowLayout {
        visible: view.empties.length > 0
        Layout.fillWidth: true
        Layout.topMargin: Tokens.space.xs
        spacing: Tokens.space.sm
        Text {
            text: view.empties.length === 1 ? "Vacío" : "Vacíos"
            color: Colors.m3outline
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
        }
        Repeater {
            model: view.empties
            Rectangle {
                id: chip
                required property var modelData
                implicitWidth: 44
                implicitHeight: 28
                radius: 14
                color: "transparent"
                border.width: 1
                border.color: Colors.m3outlineVariant
                opacity: view.chosenId && view.chosenId !== chip.modelData.id ? 0.4 : 1
                StateLayer { hovered: chipMouse.containsMouse; pressed: chipMouse.pressed }
                Row {
                    anchors.centerIn: parent
                    spacing: 2
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "add"; size: 14; color: Colors.m3onSurfaceVariant }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: chip.modelData.id
                        color: Colors.m3onSurfaceVariant
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        font.weight: Tokens.weight.medium
                    }
                }
                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: view.go(chip.modelData.id, "")
                }
            }
        }
        Item { Layout.fillWidth: true }
    }
}
