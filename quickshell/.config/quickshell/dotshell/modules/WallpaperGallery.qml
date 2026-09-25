// Galeria de wallpapers (Fase 3 B3: P3.1, P3.2, P3.4, P3.6 por nombre) --
// reemplaza al selector de rofi en SUPER+SHIFT+W (rofi queda en SUPER+ALT+W
// mientras la galeria madura, decision W8).
//
// Lee la cache de hypr/.config/hypr/scripts/wallpaper-cache.sh (miniaturas y
// paletas) y el estado de ThemeState.qml. No escribe nada por su cuenta:
// aplicar y marcar favoritos pasan por theme-apply.sh, que es el unico que
// escribe el estado (con lock). Al abrir, refresca la cache en segundo plano
// (incremental: casi instantaneo si no hay wallpapers nuevos).
//
// Misma estructura que Launcher.qml: ventana a pantalla completa en la capa
// quickshell-panel (blur), velo, tarjeta Surface de nivel 3, entrada/salida
// con Presence (superficie grande y centrada: dur.long, sin desplazamiento) y
// HyprlandFocusGrab para el teclado.
//
// Teclado: flechas mueven, Enter aplica, F marca favorito, T agrega una
// etiqueta, / busca (Abajo o Enter vuelven a la grilla), Esc cierra.
//
// Etiquetas (Fase 3 B4): la busqueda encuentra por nombre o por etiqueta
// (texto normal, decision B4a); la fila de chips filtra por una etiqueta a la
// vez (B4b).
//
// Historial (Fase 3 B5): el chip Recientes muestra los wallpapers aplicados
// en orden cronologico real (el mas reciente primero). Todos, Favoritos y
// Recientes son interruptores independientes que se combinan entre si y con
// la busqueda y la etiqueta (Todos los apaga). Deshacer vuelve al tema
// anterior (theme-apply.sh --undo) y cierra la galeria, igual que Aplicar.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml, GalleryState.qml, ThemeState.qml

PanelWindow {
    id: window

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-panel"

    // THEME_SCRIPTS_DIR: otra copia de los scripts para pruebas.
    readonly property string scriptsDir: Quickshell.env("THEME_SCRIPTS_DIR") || (Quickshell.env("HOME") + "/.config/hypr/scripts")
    readonly property string wallpapersDir: Quickshell.env("WALLPAPERS_DIR") || (Quickshell.env("HOME") + "/Pictures/Wallpapers")
    readonly property string cacheDir: Quickshell.env("WALLPAPER_CACHE_DIR") || (Quickshell.env("HOME") + "/.cache/dotfiles/wallpapers")

    readonly property bool shouldShow: GalleryState.visible
    Presence { id: presence; open: window.shouldShow; enterDuration: Tokens.motion.long; slide: false }
    visible: presence.shown

    HyprlandFocusGrab {
        windows: [window]
        active: window.visible
        onCleared: GalleryState.visible = false
    }

    // ---- Datos -------------------------------------------------------------

    // Indice de la cache: nombre -> {mtime, size, thumb, colors}.
    property var index: ({})
    FileView {
        id: cacheFile
        path: window.cacheDir + "/palettes.json"
        watchChanges: true
        onFileChanged: reload()
        printErrors: false
        onLoaded: {
            try {
                window.index = JSON.parse(cacheFile.text());
            } catch (e) {
                window.index = {};
            }
        }
    }

    readonly property var names: Object.keys(window.index).sort()
    readonly property string currentPath: ThemeState.current ? ThemeState.current.wallpaper : ""

    property string query: ""
    property bool onlyFavorites: false
    property bool onlyRecent: false
    property string activeTag: ""

    // Wallpapers del historial en orden cronologico (solo los que estan en la cache).
    readonly property var recentNames: (ThemeState.recent || [])
        .map(e => e.wallpaper.split("/").pop())
        .filter(n => window.index[n] !== undefined)

    readonly property var filtered: {
        const q = window.query.trim().toLowerCase();
        const favs = ThemeState.favorites || [];
        const tags = ThemeState.tags || {};
        const base = window.onlyRecent ? window.recentNames : window.names;
        return base.filter(n => {
            const t = tags[window.pathOf(n)] || [];
            if (q && n.toLowerCase().indexOf(q) < 0 && !t.some(x => x.indexOf(q) >= 0)) return false;
            if (window.onlyFavorites && favs.indexOf(window.pathOf(n)) < 0) return false;
            if (window.activeTag && t.indexOf(window.activeTag) < 0) return false;
            return true;
        });
    }

    function pathOf(name: string): string {
        return window.wallpapersDir + "/" + name;
    }
    function thumbOf(name: string): string {
        return window.cacheDir + "/thumbs/" + name + ".jpg";
    }

    readonly property string selectedName: grid.currentIndex >= 0 && grid.currentIndex < window.filtered.length
        ? window.filtered[grid.currentIndex] : ""

    function apply(): void {
        if (!window.selectedName) return;
        Quickshell.execDetached([window.scriptsDir + "/theme-apply.sh", window.pathOf(window.selectedName), "--source", "gallery"]);
        GalleryState.visible = false;
    }
    function toggleFavorite(): void {
        if (!window.selectedName) return;
        Quickshell.execDetached([window.scriptsDir + "/theme-apply.sh", "--favorite", window.pathOf(window.selectedName), "toggle"]);
    }
    function undo(): void {
        if (!ThemeState.canUndo) return;
        Quickshell.execDetached([window.scriptsDir + "/theme-apply.sh", "--undo", "--no-notify"]);
        GalleryState.visible = false;
    }

    // "Aplicado hace ..." (B5c). now se refresca cada 30 s con la galeria abierta.
    property real now: Date.now()
    Timer {
        interval: 30000
        repeat: true
        running: window.visible
        triggeredOnStart: true
        onTriggered: window.now = Date.now()
    }
    function ago(iso: string): string {
        if (!iso) return "";
        const s = Math.max(0, (window.now - Date.parse(iso)) / 1000);
        if (s < 60) return "hace unos segundos";
        if (s < 3600) return "hace " + Math.floor(s / 60) + " min";
        if (s < 86400) return "hace " + Math.floor(s / 3600) + " h";
        const d = Math.floor(s / 86400);
        return d === 1 ? "hace 1 dia" : "hace " + d + " dias";
    }

    function setTag(op: string, tag: string): void {
        if (!window.selectedName) return;
        Quickshell.execDetached([window.scriptsDir + "/theme-apply.sh", "--tag", window.pathOf(window.selectedName), op, tag]);
    }

    // Al abrir, la seleccion arranca sobre el wallpaper aplicado. La cache y el
    // estado se cargan de forma asincrona, asi que el salto queda pendiente y
    // se reintenta cuando llegan los datos; cualquier tecla, busqueda o click
    // lo cancela para no pelear con el usuario.
    property bool jumpPending: false
    function jumpToCurrent(): void {
        if (!window.jumpPending) return;
        const i = window.filtered.indexOf(window.currentPath.split("/").pop());
        if (i < 0 || grid.count <= i) return;
        grid.currentIndex = i;
        // Centrado tras el layout de la grilla (antes quedaba cortado abajo).
        Qt.callLater(() => grid.positionViewAtIndex(i, GridView.Center));
        window.jumpPending = false;
    }
    // Diferido: al poblarse el modelo, GridView vuelve currentIndex a 0 despues
    // de emitir countChanged y pisaria el salto.
    onFilteredChanged: Qt.callLater(window.jumpToCurrent)
    onCurrentPathChanged: Qt.callLater(window.jumpToCurrent)

    onShouldShowChanged: {
        if (!window.shouldShow) return;
        window.query = "";
        searchField.text = "";
        window.onlyFavorites = false;
        window.onlyRecent = false;
        window.activeTag = "";
        window.jumpPending = true;
        window.jumpToCurrent();
        grid.forceActiveFocus();
        // Cache al dia (incremental).
        Quickshell.execDetached([window.scriptsDir + "/wallpaper-cache.sh"]);
    }

    // ---- Interfaz ----------------------------------------------------------

    // Velo sobre el escritorio.
    Rectangle {
        anchors.fill: parent
        color: Colors.m3scrim
        opacity: Tokens.opacity.scrim * presence.progress
    }

    // Click afuera de la tarjeta cierra (z -1: no tapa los clicks de la tarjeta).
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: GalleryState.visible = false
    }

    Surface {
        id: card
        anchors.fill: parent
        anchors.margins: Tokens.space.xxl
        level: 3
        translucent: true
        radius: Tokens.radius.xl
        opacity: presence.progress
        scale: presence.contentScale

        // Sin esto, un click en el padding de la tarjeta atravesaria hasta el
        // MouseArea de fondo y cerraria la galeria.
        MouseArea { anchors.fill: parent }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Tokens.space.md
            spacing: Tokens.space.lg

            // -- Izquierda: busqueda, filtros, grilla --
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Tokens.space.md

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.space.sm

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Tokens.row.height
                        radius: Tokens.radius.md
                        color: Colors.m3surfaceContainerHighest
                        border.color: searchField.activeFocus ? Colors.m3primary : Colors.m3outlineVariant
                        Behavior on border.color { ColorAnimation { duration: Tokens.motion.fast } }

                        Icon {
                            id: searchIcon
                            anchors.left: parent.left
                            anchors.leftMargin: Tokens.space.md
                            anchors.verticalCenter: parent.verticalCenter
                            name: "search"
                            color: Colors.m3onSurfaceVariant
                        }
                        TextInput {
                            id: searchField
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.space.md + searchIcon.width + Tokens.space.sm
                            anchors.rightMargin: Tokens.space.md
                            verticalAlignment: TextInput.AlignVCenter
                            color: Colors.m3onSurface
                            selectionColor: Colors.m3primary
                            selectedTextColor: Colors.m3onPrimary
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            clip: true
                            onTextChanged: {
                                window.query = searchField.text;
                                if (searchField.activeFocus) window.jumpPending = false;
                                grid.currentIndex = 0;
                            }
                            Keys.onDownPressed: grid.forceActiveFocus()
                            Keys.onReturnPressed: grid.forceActiveFocus()
                            Keys.onEscapePressed: GalleryState.visible = false
                        }
                        Text {
                            visible: searchField.text.length === 0
                            anchors.left: parent.left
                            anchors.leftMargin: searchField.anchors.leftMargin
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Buscar por nombre o etiqueta  ( / )"
                            color: Colors.m3onSurfaceVariant
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onClicked: searchField.forceActiveFocus()
                        }
                    }

                    // Filtros: Favoritos y Recientes son interruptores independientes
                    // (se combinan); Todos los apaga a ambos.
                    Repeater {
                        model: [["Todos", "all", ""], ["Favoritos", "fav", "favorite"], ["Recientes", "recent", "history"]]
                        Rectangle {
                            id: chip
                            required property var modelData
                            readonly property bool selected: chip.modelData[1] === "all" ? (!window.onlyFavorites && !window.onlyRecent)
                                : chip.modelData[1] === "fav" ? window.onlyFavorites : window.onlyRecent
                            implicitHeight: Tokens.row.height
                            implicitWidth: chipRow.implicitWidth + Tokens.pad.pillH * 2
                            radius: Tokens.radius.sm
                            color: chip.selected ? Colors.m3secondaryContainer : "transparent"
                            border.color: chip.selected ? Colors.m3secondaryContainer : Colors.m3outlineVariant
                            Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }
                            StateLayer {
                                hovered: chipMouse.containsMouse
                                pressed: chipMouse.pressed
                                contentColor: chip.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                            }
                            Row {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: Tokens.space.xs
                                Icon {
                                    visible: chip.modelData[2] !== ""
                                    name: chip.modelData[2]
                                    filled: chip.selected
                                    size: Tokens.icon.sm
                                    color: chip.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: chip.modelData[0]
                                    color: chip.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.label
                                    font.weight: chip.selected ? Tokens.weight.semibold : Tokens.weight.medium
                                }
                            }
                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.jumpPending = false;
                                    if (chip.modelData[1] === "all") {
                                        window.onlyFavorites = false;
                                        window.onlyRecent = false;
                                    } else if (chip.modelData[1] === "fav") {
                                        window.onlyFavorites = !window.onlyFavorites;
                                    } else {
                                        window.onlyRecent = !window.onlyRecent;
                                    }
                                    grid.currentIndex = 0;
                                    grid.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Filtro por etiqueta: una a la vez, click de nuevo para quitarlo.
                ListView {
                    id: tagBar
                    visible: count > 0
                    Layout.fillWidth: true
                    implicitHeight: Tokens.pill.height
                    orientation: ListView.Horizontal
                    spacing: Tokens.space.xs
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: presence.shown ? ThemeState.allTags : []
                    delegate: Rectangle {
                        id: tagFilter
                        required property var modelData
                        readonly property bool selected: window.activeTag === tagFilter.modelData.tag
                        height: Tokens.pill.height
                        width: tagFilterText.implicitWidth + Tokens.pad.pillH * 2
                        radius: Tokens.radius.sm
                        color: tagFilter.selected ? Colors.m3secondaryContainer : "transparent"
                        border.color: tagFilter.selected ? Colors.m3secondaryContainer : Colors.m3outlineVariant
                        Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }
                        StateLayer {
                            hovered: tagFilterMouse.containsMouse
                            pressed: tagFilterMouse.pressed
                            contentColor: tagFilter.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                        }
                        Text {
                            id: tagFilterText
                            anchors.centerIn: parent
                            text: tagFilter.modelData.tag + "  " + tagFilter.modelData.count
                            color: tagFilter.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            font.weight: tagFilter.selected ? Tokens.weight.semibold : Tokens.weight.medium
                        }
                        MouseArea {
                            id: tagFilterMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.jumpPending = false;
                                window.activeTag = tagFilter.selected ? "" : tagFilter.modelData.tag;
                                grid.currentIndex = 0;
                                grid.forceActiveFocus();
                            }
                        }
                    }
                }

                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    // Sin delegados con la galeria cerrada: no retiene miniaturas.
                    model: presence.shown ? window.filtered : []
                    cellWidth: Math.floor(width / 4)
                    cellHeight: Math.round(cellWidth * 9 / 16)
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: Tokens.motion.fast
                    keyNavigationWraps: false

                    Keys.onReturnPressed: window.apply()
                    Keys.onEnterPressed: window.apply()
                    Keys.onEscapePressed: GalleryState.visible = false
                    onCountChanged: Qt.callLater(window.jumpToCurrent)

                    Keys.onPressed: (event) => {
                        window.jumpPending = false;
                        if (event.key === Qt.Key_F) {
                            window.toggleFavorite();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_T) {
                            preview.focusTagInput();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Slash) {
                            searchField.forceActiveFocus();
                            event.accepted = true;
                        }
                    }

                    delegate: Item {
                        id: cell
                        required property int index
                        required property string modelData
                        readonly property bool selected: cell.index === grid.currentIndex
                        readonly property string path: window.pathOf(cell.modelData)
                        width: grid.cellWidth
                        height: grid.cellHeight

                        ClippingRectangle {
                            id: frame
                            anchors.fill: parent
                            anchors.margins: Tokens.space.xs
                            radius: Tokens.radius.md
                            color: Colors.m3surfaceContainerHighest

                            Image {
                                anchors.fill: parent
                                source: "file://" + window.thumbOf(cell.modelData)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(480, 270)
                            }

                            StateLayer { hovered: cellMouse.containsMouse; pressed: cellMouse.pressed }

                            // Aplicado ahora.
                            Rectangle {
                                visible: cell.path === window.currentPath
                                anchors { left: parent.left; bottom: parent.bottom; margins: Tokens.space.xs }
                                implicitHeight: Tokens.icon.md
                                implicitWidth: badgeRow.implicitWidth + Tokens.space.sm
                                radius: Tokens.radius.pill(height)
                                color: Colors.m3primary
                                Row {
                                    id: badgeRow
                                    anchors.centerIn: parent
                                    spacing: Tokens.space.hair
                                    Icon { name: "check"; size: Tokens.icon.sm; color: Colors.m3onPrimary }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Actual"
                                        color: Colors.m3onPrimary
                                        font.family: Tokens.font.ui
                                        font.pixelSize: Tokens.type.caption
                                        font.weight: Tokens.weight.semibold
                                    }
                                }
                            }

                            // Favorito, sobre un circulo para que se lea en cualquier miniatura.
                            Rectangle {
                                visible: ThemeState.isFavorite(cell.path)
                                anchors { right: parent.right; top: parent.top; margins: Tokens.space.xs }
                                width: Tokens.icon.md; height: width; radius: width / 2
                                color: Colors.m3surfaceContainerHigh
                                Icon { anchors.centerIn: parent; name: "favorite"; filled: true; size: Tokens.icon.sm; color: Colors.m3primary }
                            }
                        }

                        // Seleccionado: anillo primary por encima de la miniatura.
                        Rectangle {
                            anchors.fill: frame
                            radius: Tokens.radius.md
                            color: "transparent"
                            border.width: cell.selected ? 2 : 0
                            border.color: Colors.m3primary
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.jumpPending = false;
                                grid.currentIndex = cell.index;
                                grid.forceActiveFocus();
                            }
                            onDoubleClicked: {
                                grid.currentIndex = cell.index;
                                window.apply();
                            }
                        }
                    }

                    Text {
                        visible: window.filtered.length === 0
                        anchors.centerIn: parent
                        text: window.query || window.activeTag ? "Sin resultados"
                            : window.onlyRecent && window.recentNames.length === 0 ? "Todavia no hay historial"
                            : window.onlyFavorites ? "Todavia no hay favoritos (F para marcar)" : "Sin resultados"
                        color: Colors.m3onSurfaceVariant
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: window.filtered.length + " de " + window.names.length + " wallpapers   ·   ↑↓←→ mover   ⏎ aplicar   F favorito   T etiqueta   / buscar   esc cerrar"
                    elide: Text.ElideRight
                    color: Colors.m3onSurfaceVariant
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                }
            }

            // -- Derecha: vista previa del seleccionado --
            GalleryPreview {
                id: preview
                Layout.fillWidth: false
                Layout.preferredWidth: Tokens.panel.widthLg
                Layout.fillHeight: true
                name: window.selectedName
                thumb: window.selectedName ? window.thumbOf(window.selectedName) : ""
                colors: window.selectedName && window.index[window.selectedName] ? window.index[window.selectedName].colors : null
                isCurrent: window.selectedName !== "" && window.pathOf(window.selectedName) === window.currentPath
                isFavorite: window.selectedName !== "" && ThemeState.isFavorite(window.pathOf(window.selectedName))
                tags: window.selectedName ? ThemeState.tagsOf(window.pathOf(window.selectedName)) : []
                onApplyRequested: window.apply()
                onFavoriteToggled: window.toggleFavorite()
                onTagAdded: (tag) => window.setTag("add", tag)
                onTagRemoved: (tag) => window.setTag("remove", tag)
                onTagInputDone: grid.forceActiveFocus()
                appliedAgo: window.selectedName ? window.ago(ThemeState.lastAppliedOf(window.pathOf(window.selectedName))) : ""
                canUndo: ThemeState.canUndo
                undoTarget: ThemeState.previous ? ThemeState.previous.wallpaper.split("/").pop() : ""
                onUndoRequested: window.undo()
            }
        }
    }
}
