// Contenido de la ventana "Configuración" (Fase 10 B1, P10.1-P10.2): titulo
// y busqueda arriba, el riel de paginas (SettingsModel.pages) a la izquierda
// y la pagina a la derecha; arriba de la pagina, el aviso de reinicio cuando
// un cambio lo pide. Teclado: Ctrl+F busca, Ctrl+Tab / Ctrl+AvPag siguiente
// pagina, Ctrl+Mayus+Tab / Ctrl+RePag anterior, Tab entre controles (la
// pagina se desplaza hasta el que tiene el foco), flechas / RePag / AvPag /
// Inicio / Fin desplazan la pagina (las que un control no usa), Esc borra la
// busqueda y despues cierra. La barra de la derecha se arrastra o se cliquea.
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import ".." // Colors.qml, Tokens.qml, SettingsState.qml
import "../modules"

Rectangle {
    id: win

    property string page: "home"
    // Opcion iluminada (resultado de busqueda o enlace directo).
    property string highlightKey: ""
    // El texto de la busqueda (las pruebas lo escriben aca).
    property alias query: search.text
    signal closeRequested

    readonly property SettingsModel model: SettingsModel {}
    readonly property var restartKeys: SettingsState.pendingRestart.filter(k => (win.model.keys[k] || {}).apply === "reload-shell")

    // Una pagina ("home", "about" o una categoria) o una clave; lo demas no hace nada.
    function open(target: string): bool {
        if (!target) return true;
        if (win.model.page(target)) {
            win.go(target);
            return true;
        }
        if (win.model.keys[target]) {
            win.reveal(target);
            return true;
        }
        console.warn("settings: destino desconocido " + target);
        return false;
    }
    function go(id: string): void {
        if (!win.model.page(id) || id === win.page) return;
        // Pagina nueva de cero (sin el estado de la anterior: avanzadas, confirmacion).
        body.active = false;
        win.page = id;
        body.active = true;
        flick.contentY = 0;
        content.forceActiveFocus();
    }
    function step(dir: int): void {
        const ps = win.model.pages;
        const i = ps.findIndex(p => p.id === win.page);
        win.go(ps[(i + dir + ps.length) % ps.length].id);
    }
    // Lleva a la pagina de la clave, la centra y la ilumina una vez.
    function reveal(key: string): void {
        const m = win.model.keys[key];
        if (!m) return;
        search.text = "";
        win.highlightKey = "";
        if (win.page !== m.category) win.go(m.category);
        Qt.callLater(() => {
            const pageItem = body.item;
            const row = pageItem && pageItem.rowFor ? pageItem.rowFor(key) : null;
            // Las avanzadas recien desplegadas se crean en este ciclo.
            Qt.callLater(() => {
                const r = row || (pageItem && pageItem.rowFor ? pageItem.rowFor(key) : null);
                if (r) {
                    const y = r.mapToItem(flick.contentItem, 0, 0).y;
                    flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, y - (flick.height - r.height) / 3));
                }
                win.highlightKey = key;
            });
        });
    }

    // ---- Desplazamiento con el teclado ---------------------------------------------------------
    readonly property real maxY: Math.max(0, flick.contentHeight - flick.height)
    function scrollTo(y: real): void {
        const to = Math.max(0, Math.min(win.maxY, y));
        scrollAnim.stop();
        flick.cancelFlick();
        scrollAnim.to = to;
        scrollAnim.start();
    }
    function scrollBy(dy: real): void {
        // Con la tecla sostenida, cada paso parte de donde iba el anterior.
        win.scrollTo((scrollAnim.running ? scrollAnim.to : flick.contentY) + dy);
    }
    NumberAnimation {
        id: scrollAnim
        target: flick
        property: "contentY"
        duration: Tokens.motion.fast
        easing.type: Easing.OutCubic
    }
    // Tab: el control con el foco queda a la vista (con un margen).
    readonly property Item focusItem: Window.activeFocusItem
    onFocusItemChanged: {
        const it = win.focusItem;
        if (!it) return;
        for (let p = it.parent; p; p = p.parent) {
            if (p !== flick.contentItem) continue;
            const y = it.mapToItem(flick.contentItem, 0, 0).y;
            const m = Tokens.space.xl;
            if (y - m < flick.contentY) win.scrollTo(y - m);
            else if (y + it.height + m > flick.contentY + flick.height) win.scrollTo(y + it.height + m - flick.height);
            return;
        }
    }

    color: Colors.surfaceLowest

    Shortcut { sequence: "Ctrl+F"; onActivated: search.focusInput() }
    Shortcut { sequences: ["Ctrl+Tab", "Ctrl+PgDown"]; onActivated: win.step(1) }
    Shortcut { sequences: ["Ctrl+Shift+Tab", "Ctrl+Backtab", "Ctrl+PgUp"]; onActivated: win.step(-1) }
    Shortcut {
        sequence: "Esc"
        onActivated: {
            if (search.text) search.text = "";
            else win.closeRequested();
        }
    }

    // ---- Cabecera ---------------------------------------------------------------------------
    Item {
        id: header
        width: parent.width
        height: 72
        Text {
            x: Tokens.space.xl
            anchors.verticalCenter: parent.verticalCenter
            text: "Configuración"
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.display
            font.weight: Tokens.weight.semibold
        }
        SearchField {
            id: search
            anchors.right: parent.right
            anchors.rightMargin: Tokens.space.xl
            anchors.verticalCenter: parent.verticalCenter
            width: 420
            size: "regular"
            placeholder: "Buscar en la configuración (Ctrl+F)"
            keyHandler: (event) => results.handleKey(event)
        }
    }

    // ---- Riel -------------------------------------------------------------------------------
    Column {
        id: rail
        x: Tokens.space.md
        y: header.height
        width: 220
        spacing: Tokens.space.hair
        Repeater {
            model: win.model.pages
            Rectangle {
                id: item
                required property var modelData
                readonly property bool sel: win.page === item.modelData.id
                width: rail.width
                height: Tokens.row.heightLarge
                radius: Tokens.radius.pill(height)
                color: item.sel ? Colors.accentAltContainer : "transparent"
                StateLayer { hovered: itemMouse.containsMouse; pressed: itemMouse.pressed; contentColor: item.sel ? Colors.textOnAccentAltContainer : Colors.text }
                Row {
                    x: Tokens.space.lg
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space.md
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: item.modelData.icon
                        filled: item.sel
                        color: item.sel ? Colors.textOnAccentAltContainer : Colors.textMuted
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: item.modelData.label
                        color: item.sel ? Colors.textOnAccentAltContainer : Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.weight: item.sel ? Tokens.weight.semibold : Tokens.weight.regular
                    }
                }
                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.go(item.modelData.id)
                }
            }
        }
    }

    // ---- Contenido -----------------------------------------------------------------------------
    Rectangle {
        id: content
        x: rail.x + rail.width + Tokens.space.md
        y: header.height
        width: win.width - x - Tokens.space.md
        height: win.height - y - Tokens.space.md
        radius: Tokens.radius.xl
        color: Colors.surfaceLow
        clip: true
        // Recibe las teclas que los controles de la pagina no usan.
        focus: true
        Component.onCompleted: content.forceActiveFocus()
        Keys.onPressed: (event) => {
            if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier)) return;
            const step = 3 * Tokens.row.height;
            const pageStep = flick.height * 0.85;
            switch (event.key) {
            case Qt.Key_Down: win.scrollBy(step); break;
            case Qt.Key_Up: win.scrollBy(-step); break;
            case Qt.Key_PageDown: win.scrollBy(pageStep); break;
            case Qt.Key_PageUp: win.scrollBy(-pageStep); break;
            case Qt.Key_Home: win.scrollTo(0); break;
            case Qt.Key_End: win.scrollTo(win.maxY); break;
            default: return;
            }
            event.accepted = true;
        }

        // Aviso: hay cambios que se aplican al reiniciar la shell.
        Rectangle {
            id: banner
            visible: win.restartKeys.length > 0
            x: Tokens.space.lg
            y: Tokens.space.lg
            width: parent.width - 2 * Tokens.space.lg
            height: visible ? Tokens.row.heightLarge + Tokens.space.sm : 0
            radius: Tokens.radius.pill(height)
            color: Colors.warningContainer
            Row {
                x: Tokens.space.lg
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.space.md
                Icon { anchors.verticalCenter: parent.verticalCenter; name: "restart_alt"; color: Colors.textOnWarningContainer }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.restartKeys.length === 1 ? "1 cambio se aplica al reiniciar la shell"
                        : win.restartKeys.length + " cambios se aplican al reiniciar la shell"
                    color: Colors.textOnWarningContainer
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                }
            }
            Button {
                anchors.right: parent.right
                anchors.rightMargin: Tokens.space.sm
                anchors.verticalCenter: parent.verticalCenter
                activeFocusOnTab: banner.visible
                ink: Colors.textOnWarningContainer
                edge: Colors.textOnWarningContainer
                icon: "restart_alt"
                label: "Reiniciar la shell"
                onClicked: {
                    Quickshell.execDetached(["qs", "-c", "dotshell", "ipc", "call", "shell", "reload"]);
                    SettingsState.pendingRestart = SettingsState.pendingRestart.filter(k => win.restartKeys.indexOf(k) < 0);
                }
            }
        }

        Flickable {
            id: flick
            y: banner.visible ? banner.y + banner.height : 0
            width: parent.width
            height: parent.height - y
            contentHeight: body.implicitHeight + 2 * Tokens.space.xl
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            // Clic en un lugar vacio de la pagina: el teclado vuelve a desplazarla.
            MouseArea {
                z: -1
                width: flick.width
                height: Math.max(flick.height, flick.contentHeight)
                onPressed: (m) => { content.forceActiveFocus(); m.accepted = false; }
            }
            Loader {
                id: body
                x: Tokens.space.xl
                y: Tokens.space.xl
                width: flick.width - 2 * Tokens.space.xl
                sourceComponent: win.page === "home" ? homePage : win.page === "about" ? aboutPage : categoryPage
            }
        }
        // Barra de desplazamiento (solo si hay algo que desplazar).
        Scrollbar {
            flickable: flick
            x: parent.width - width
            y: flick.y
            height: flick.height
        }
    }

    // Resultados, por encima de todo.
    SettingsSearch {
        id: results
        z: 10
        x: search.x
        y: header.height - Tokens.space.sm
        width: search.width
        model: win.model
        query: search.text
        onChosen: (key) => win.reveal(key)
    }

    Component {
        id: homePage
        HomePage {
            model: win.model
            onOpenPage: (id) => win.go(id)
            onReveal: (key) => win.reveal(key)
        }
    }
    Component {
        id: categoryPage
        CategoryPage {
            category: win.page
            model: win.model
            // Apariencia (Fase 10 B2): tema actual y avatar arriba de sus secciones.
            extras: win.page === "appearance" ? { "Color": themeCard, "Avatar": avatarCard }
                : win.page === "keybinds" ? { "_top": keybindsBrowser } : ({})
            highlightKey: win.highlightKey
        }
    }
    Component {
        id: themeCard
        ThemeCard { model: win.model }
    }
    Component {
        id: keybindsBrowser
        KeybindsBrowser {}
    }
    Component {
        id: avatarCard
        AvatarCard {}
    }
    Component {
        id: aboutPage
        AboutPage {
            model: win.model
        }
    }
}
