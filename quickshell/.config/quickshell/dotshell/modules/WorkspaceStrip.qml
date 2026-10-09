// Escritorios en Inicio (Fase 4 B7): una miniatura por slot de la barra
// (DesktopState.slots, los mismos numeros que la pill de workspaces), con el
// contorno del workspace enfocado deslizandose entre ellas con el resorte
// calibrado (el mismo que el indicador de la barra).
//
// Elegir uno (clic, Enter o su numero): la miniatura se levanta, las demas se
// velan y el dashboard se cierra en el mismo momento en que Hyprland cambia de
// workspace (B7-m): su deslizamiento se ve detras mientras el panel se funde.
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import ".." // Colors.qml, Tokens.qml, DesktopState.qml, DashboardState.qml, AppInfo.qml

ColumnLayout {
    id: strip
    property string screenName: ""
    // El dashboard se ve (anima cambios, sigue eventos).
    property bool live: false
    // Seleccion del teclado (-1 = ninguna).
    property int selected: -1
    property int chosenId: 0
    spacing: Tokens.space.sm

    readonly property var slots: DesktopState.slots
    readonly property int count: strip.slots.length
    readonly property int focusedIndex: strip.slots.findIndex(w => !w.placeholder && Hyprland.focusedWorkspace === w)
    // Ventana enfocada, solo si esta en el workspace enfocado.
    readonly property var activeWindow: Hyprland.focusedWorkspace
        ? DesktopState.windows.find(w => w.focused && w.wsId === Hyprland.focusedWorkspace.id) || null : null
    // El piso de 72 no escala con la interfaz (px-ok): decide cuantas entran
    // antes de desplazar, y a 150 % cinco siguen entrando en una zona compacta.
    readonly property real tileWidth: Math.max(72, (row.width - (strip.count - 1) * Tokens.space.sm) / Math.max(strip.count, 5))   // px-ok

    function reset(): void {
        strip.selected = -1;
        strip.chosenId = 0;
    }
    function pick(id: int): void {
        if (strip.chosenId) return;
        strip.chosenId = id;
        DashboardState.close();
        DesktopState.focusWorkspace(id);
    }
    // Teclado (con el foco en la zona): izquierda/derecha eligen, Enter va.
    function handleKey(event: var): bool {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            const start = strip.selected >= 0 ? strip.selected : Math.max(0, strip.focusedIndex);
            const step = event.key === Qt.Key_Left ? -1 : 1;
            strip.selected = (start + step + strip.count) % strip.count;
            return true;
        }
        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && strip.selected >= 0) {
            strip.pick(strip.slots[strip.selected].id);
            return true;
        }
        return false;
    }

    // Titulo: "Escritorios · 2 — kitty" (la aplicacion, no el titulo de la
    // ventana: estable y sin ruido).
    ZoneTitle {
        Layout.fillWidth: true
        text: "Escritorios"
        opens: true
        detail: Hyprland.focusedWorkspace
            ? "· " + Hyprland.focusedWorkspace.id + (strip.activeWindow ? " — " + AppInfo.name(strip.activeWindow.cls) : "")
            : ""
    }

    Flickable {
        id: row
        Layout.fillWidth: true
        Layout.preferredHeight: tiles.height + 8
        contentWidth: tiles.width + 8
        contentHeight: height
        clip: false
        interactive: contentWidth > width
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id: tiles
            x: 4
            y: 4
            spacing: Tokens.space.sm
            Repeater {
                model: strip.slots
                WorkspaceThumb {
                    required property var modelData
                    required property int index
                    slot: modelData
                    width: strip.tileWidth
                    height: implicitHeight
                    screenName: strip.screenName
                    live: strip.live
                    selected: strip.selected === index
                    chosen: strip.chosenId === modelData.id
                    veiled: strip.chosenId !== 0 && strip.chosenId !== modelData.id
                    onPicked: strip.pick(modelData.id)
                }
            }
        }

        // Contorno del workspace enfocado: uno solo, se desliza con el resorte.
        Rectangle {
            visible: strip.focusedIndex >= 0 && tiles.children.length > 0
            x: tiles.x - 3 + Math.max(0, strip.focusedIndex) * (strip.tileWidth + Tokens.space.sm)
            y: tiles.y - 3
            width: strip.tileWidth + 6
            height: tiles.height + 6
            radius: Tokens.radius.sm + 3
            color: "transparent"
            border.width: 2
            border.color: Colors.accent
            opacity: strip.chosenId && strip.slots[strip.focusedIndex] && strip.slots[strip.focusedIndex].id !== strip.chosenId ? 0.3 : 1
            Behavior on x {
                enabled: strip.live && Tokens.motion.scale > 0
                SpringAnimation { spring: Tokens.motion.spring.qmlSpring; damping: Tokens.motion.spring.qmlDamping }
            }
        }
    }
}
