// Selector de ventanas (Fase 4 B4, P4.4), la unica interfaz para cambiar de
// ventana. OverlayWindow + Picker
// en rejilla de tarjetas: vista previa capturada al abrir (WindowPreview,
// una sola vez, tambien de otros workspaces), insignia del workspace (S =
// especial; con varias pantallas, tambien el monitor), icono y titulo. Orden
// por uso reciente (focusHistoryID de hyprctl clients): la ventana actual
// primero y elegida la anterior.
//
// Dos modos en uno (decision B4-a):
//   - hold: SUPER+TAB abre con Super apretado; SUPER+TAB / SUPER+SHIFT+TAB
//     (binds de Hyprland -> IPC) mueven y SOLTAR SUPER cambia de ventana. Un
//     SUPER+TAB rapido vuelve a la ventana anterior.
//   - browse: si llega una tecla sin Super (flechas, escribir) el panel queda
//     abierto: flechas, Enter o clic cambian; escribir filtra.
// Siempre: Esc o clic afuera cancelan (el foco no cambia), Supr cierra la
// ventana elegida (B4-d).
//
// Cambiar = hl.dsp.focus({ window = "address:0x..." }) en el acto: Hyprland
// mueve el foco (y el workspace), el focus grab del panel se libera y el panel
// se cierra solo (DesktopState.focusWindow: a los 250 ms comprueba que la
// ventana quedo activa y si no repite una vez). DESKTOP_DRY=1 (solo pruebas)
// registra los comandos. Vista previa: WindowPreview (la misma de las
// miniaturas de Escritorios).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml, SwitcherState.qml, DesktopState.qml, AppInfo.qml

OverlayWindow {
    id: window

    open: SwitcherState.visible
    targetScreen: SwitcherState.screen
    onDismissed: SwitcherState.close()

    readonly property int columns: 4
    readonly property int cardWidth: Tokens.px(264)
    readonly property int cardHeight: Tokens.px(214)
    // Tamano fijo de la vista previa (no depende del layout).
    readonly property size previewSize: Qt.size(window.cardWidth - Tokens.px(24), window.cardHeight - Tokens.px(64))

    // true mientras se supone Super apretado (soltarlo cambia de ventana).
    property bool hold: true
    // Ventanas de DesktopState (hyprctl), por uso reciente. Las que miden
    // menos de 24x24 no se capturan (capturable, KI-L18): muestran el icono.
    property var clients: []
    property bool loaded: false
    // Pasos (SUPER+TAB) que llegaron antes de tener la lista.
    property int pendingSteps: 0

    readonly property bool multiMonitor: Quickshell.screens.length > 1

    // La lista llega de DesktopState. Mientras el selector se ve sigue sus
    // eventos (Fase 8 B3, D5): si una ventana se abre o se cierra, la lista se
    // actualiza y la elegida se conserva por su direccion.
    property Subscription live: Subscription { demand: DesktopState.live; active: window.shouldShow }
    function fromDesktop(): var {
        return DesktopState.windows
            .slice()
            .sort((a, b) => a.history - b.history)
            .map(c => ({
                address: c.address,
                title: c.title,
                cls: c.cls,
                ws: c.special ? "S" : c.ws,
                monitor: c.monitor,
                urgent: c.urgent,
                focused: c.focused,
                capturable: c.capturable
            }));
    }
    Connections {
        target: DesktopState
        function onUpdated(): void {
            if (!window.shouldShow) return;
            if (window.loaded) {
                const cur = body.item ? body.item.current : null;
                window.clients = window.fromDesktop();
                if (body.item && cur) body.item.selectAddress(cur.address);
                return;
            }
            window.clients = window.fromDesktop();
            window.loaded = true;
            // La anterior (o la unica) + los SUPER+TAB que ya llegaron.
            const n = window.clients.length;
            if (body.item && n > 0) body.item.select(((Math.min(1, n - 1) + window.pendingSteps) % n + n) % n);
            window.pendingSteps = 0;
        }
    }

    Connections {
        target: SwitcherState
        function onStep(delta: int): void {
            if (!window.loaded) window.pendingSteps += delta;
            else if (body.item) body.item.move(delta);
        }
    }

    onShouldShowChanged: {
        if (!window.shouldShow) return;
        window.hold = true;
        window.loaded = false;
        window.clients = [];
        window.pendingSteps = 0;
        DesktopState.refresh();
    }

    // Cambiar a la ventana elegida.
    function activate(c: var): void {
        SwitcherState.close();
        if (!c || c.focused) return;
        DesktopState.focusWindow(c.address);
    }

    // Cerrar la ventana elegida (Supr): se quita de la lista enseguida.
    function closeWindow(c: var): void {
        if (!c) return;
        DesktopState.closeWindow(c.address);
        window.clients = window.clients.filter(x => x.address !== c.address);
    }

    function handleKey(key: int, modifiers: int, isAutoRepeat: bool): bool {
        return body.item ? body.item.handleKey(key, modifiers, isAutoRepeat) : false;
    }
    function handleRelease(key: int, modifiers: int): bool {
        return body.item ? body.item.handleRelease(key, modifiers) : false;
    }

    // Tarjetas solo con el panel abierto: al cerrar se liberan las capturas.
    Loader {
        id: body
        anchors.fill: parent
        active: window.visible || window.shouldShow
        sourceComponent: Item {
            id: content

            Component.onCompleted: picker.reset()
            Connections {
                target: window
                function onShouldShowChanged() {
                    if (window.shouldShow) picker.reset();
                }
            }

            readonly property var shown: {
                const q = picker.query.trim().toLowerCase();
                if (!q) return window.clients;
                return window.clients.filter(c => (c.title + " " + c.cls).toLowerCase().includes(q));
            }
            readonly property var current: content.shown[picker.currentIndex] || null

            function select(i: int): void {
                picker.currentIndex = i;
            }
            // Tras actualizar la lista: la misma ventana si sigue, si no la
            // que quedo en su lugar.
            function selectAddress(address: string): void {
                const i = content.shown.findIndex(c => c.address === address);
                const n = content.shown.length;
                if (i >= 0) picker.currentIndex = i;
                else if (n > 0) picker.currentIndex = Math.min(picker.currentIndex, n - 1);
            }
            function move(delta: int): void {
                const n = content.shown.length;
                if (n > 0) picker.currentIndex = ((picker.currentIndex + delta) % n + n) % n;
            }

            function handleKey(key: int, modifiers: int, isAutoRepeat: bool): bool {
                if (!window.shouldShow) return false;
                // Una tecla sin Super: Super ya se solto, modo browse.
                if ((modifiers & Qt.MetaModifier) === 0) window.hold = false;
                if (key === Qt.Key_Tab) { content.move(1); return true; }
                if (key === Qt.Key_Backtab) { content.move(-1); return true; }
                if (key === Qt.Key_Delete) {
                    if (!isAutoRepeat) window.closeWindow(content.current);
                    return true;
                }
                return false;
            }
            // Soltar Super en modo hold = cambiar a la elegida. Soltar otra
            // tecla sin Super = Super ya no esta apretado: modo browse (las
            // flechas tienen su propio manejador en Picker y no pasan por
            // handleKey, pero su liberacion si llega aca).
            function handleRelease(key: int, modifiers: int): bool {
                if (!window.shouldShow) return false;
                const isSuper = key === Qt.Key_Super_L || key === Qt.Key_Super_R || key === Qt.Key_Meta;
                if (isSuper) {
                    if (!window.hold) return false;
                    window.activate(content.current);
                    return true;
                }
                if ((modifiers & Qt.MetaModifier) === 0) window.hold = false;
                return false;
            }

            Picker {
                id: picker
                anchors.centerIn: parent
                presence: window.presence
                layout: "grid"
                columns: window.columns
                cellSize: window.cardWidth
                cellHeight: window.cardHeight
                maxVisibleRows: 2
                // Sin reusar celdas: cada tarjeta mantiene su captura.
                reuseCells: false
                listWidth: window.columns * window.cardWidth + Tokens.space.md * 2
                model: content.shown
                placeholder: window.hold ? "Suelta Super para cambiar · escribe para filtrar" : "Buscar ventanas..."
                emptyText: window.loaded ? (window.clients.length === 0 ? "No hay ventanas abiertas" : "Sin resultados") : ""
                hints: window.hold
                    ? "super+tab siguiente   super+shift+tab anterior   soltar super cambia   supr cerrar ventana   esc cancelar"
                    : "←↑↓→ navegar   ⏎ cambiar   supr cerrar ventana   esc cancelar"
                keyHandler: (event) => content.handleKey(event.key, event.modifiers, event.isAutoRepeat)
                keyReleaseHandler: (event) => content.handleRelease(event.key, event.modifiers)
                onAccepted: (item) => window.activate(item)
                onDismissed: SwitcherState.close()

                delegate: Item {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property bool selected: card.index === picker.currentIndex
                    width: window.cardWidth
                    height: window.cardHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Tokens.space.xs
                        radius: Tokens.radius.lg
                        color: card.selected ? Colors.accentAltContainer : "transparent"
                        border.width: card.selected ? 2 : 0
                        // El anillo de la elegida, con el acento de su app (P5.6; sin uno, el de siempre).
                        border.color: AppColors.accent(card.modelData.cls)
                        Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }

                        StateLayer { hovered: cardMouse.containsMouse; pressed: cardMouse.pressed }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Tokens.space.sm
                            spacing: Tokens.space.sm

                        // Vista previa (una captura al abrir); sin captura, el icono.
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Tokens.radius.md
                                color: Colors.surfaceHighest
                                clip: true

                                WindowPreview {
                                    anchors.fill: parent
                                    address: card.modelData.address
                                    cls: card.modelData.cls
                                    capturable: card.modelData.capturable
                                    constraintSize: window.previewSize
                                    iconSize: Tokens.space.xxl * 2
                                }

                                // Workspace (S = especial), monitor si hay varios, urgente.
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.margins: Tokens.space.xs
                                    width: badge.implicitWidth + Tokens.space.sm * 2
                                    height: Tokens.px(22)
                                    radius: Tokens.px(11)
                                    color: card.modelData.urgent ? Colors.danger : Colors.accentContainer
                                    Text {
                                        id: badge
                                        anchors.centerIn: parent
                                        text: card.modelData.ws + (window.multiMonitor ? " · " + card.modelData.monitor : "")
                                        color: card.modelData.urgent ? Colors.textOnDanger : Colors.textOnAccentContainer
                                        font.family: Tokens.font.ui
                                        font.pixelSize: Tokens.type.caption
                                        font.weight: Tokens.weight.semibold
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.space.sm
                                // Fondito del icono con el color de la app (P5.6), solo si lo tiene.
                                // (detras del icono y sin ocupar lugar).
                                Item {
                                    implicitWidth: Tokens.px(20)
                                    implicitHeight: Tokens.px(20)
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: -Tokens.space.xs
                                        radius: Tokens.radius.sm
                                        visible: AppColors.has(card.modelData.cls)
                                        color: AppColors.container(card.modelData.cls)
                                    }
                                    IconImage {
                                        anchors.fill: parent
                                        implicitSize: Tokens.px(20)
                                        source: AppInfo.icon(card.modelData.cls)
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: card.modelData.title
                                    color: card.selected ? Colors.textOnAccentAltContainer : Colors.text
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.label
                                    font.weight: card.selected ? Tokens.weight.semibold : Tokens.weight.medium
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Sin elegir al pasar el raton: el panel aparece bajo el
                        // cursor y eso cambiaria la ventana preelegida.
                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.activate(card.modelData)
                        }
                    }
                }
            }
        }
    }
}
