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
// Teclado: flechas mueven, Enter aplica, F marca favorito, / busca (Abajo o
// Enter vuelven a la grilla), Esc cierra.
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

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"
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

    readonly property var filtered: {
        const q = window.query.trim().toLowerCase();
        const favs = ThemeState.favorites || [];
        return window.names.filter(n => {
            if (q && n.toLowerCase().indexOf(q) < 0) return false;
            if (window.onlyFavorites && favs.indexOf(window.pathOf(n)) < 0) return false;
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
                            text: "Buscar por nombre  ( / )"
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

                    // Filtros (botones segmentados, mismo lenguaje que los perfiles del
                    // centro de control).
                    Repeater {
                        model: [["Todos", false], ["Favoritos", true]]
                        Rectangle {
                            id: chip
                            required property var modelData
                            readonly property bool selected: window.onlyFavorites === chip.modelData[1]
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
                                    visible: chip.modelData[1]
                                    name: "favorite"
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
                                    window.onlyFavorites = chip.modelData[1];
                                    grid.currentIndex = 0;
                                    grid.forceActiveFocus();
                                }
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
                        text: window.onlyFavorites && !window.query ? "Todavia no hay favoritos (F para marcar)" : "Sin resultados"
                        color: Colors.m3onSurfaceVariant
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: window.filtered.length + " de " + window.names.length + " wallpapers   ·   ↑↓←→ mover   ⏎ aplicar   F favorito   / buscar   esc cerrar"
                    elide: Text.ElideRight
                    color: Colors.m3onSurfaceVariant
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                }
            }

            // -- Derecha: vista previa del seleccionado --
            GalleryPreview {
                Layout.fillWidth: false
                Layout.preferredWidth: Tokens.panel.widthLg
                Layout.fillHeight: true
                name: window.selectedName
                thumb: window.selectedName ? window.thumbOf(window.selectedName) : ""
                colors: window.selectedName && window.index[window.selectedName] ? window.index[window.selectedName].colors : null
                isCurrent: window.selectedName !== "" && window.pathOf(window.selectedName) === window.currentPath
                isFavorite: window.selectedName !== "" && ThemeState.isFavorite(window.pathOf(window.selectedName))
                onApplyRequested: window.apply()
                onFavoriteToggled: window.toggleFavorite()
            }
        }
    }
}
