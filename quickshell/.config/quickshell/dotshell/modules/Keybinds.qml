// Guia de atajos (Fase 4 B10, P4.11): SUPER+/ en el monitor enfocado. Los
// atajos salen de Hyprland (KeybindState <- scripts/keybinds <- hyprctl binds
// -j), agrupados por la descripcion de cada uno en binds.lua; las familias
// (flechas, 1-0, volumen) en una sola fila. Solo lectura: no ejecuta nada.
//
// Misma tarjeta que el launcher y los selectores (nivel 3, radio xl, entrada
// con Presence); grupos como zonas del dashboard, repartidos en columnas
// equilibradas. Se escribe para buscar (descripcion, grupo o tecla); Esc
// borra la busqueda y, vacia, cierra.
//
// El contenido existe solo con la guia abierta (Loader).
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, KeybindState.qml

OverlayWindow {
    id: window

    open: KeybindState.visible
    targetScreen: KeybindState.screen
    onDismissed: KeybindState.close()
    Component.onCompleted: KeybindState.watchReloads = true

    Loader {
        anchors.fill: parent
        active: window.visible || window.shouldShow
        sourceComponent: Item {
            id: content

            // Columnas: la opcion, o segun el ancho disponible.
            readonly property int maxWidth: Math.min(Tokens.px(1240), content.width - 2 * Tokens.screenEdge)
            readonly property int columns: KeybindState.options.columns > 0 ? KeybindState.options.columns
                : content.maxWidth >= Tokens.px(1100) ? 4 : content.maxWidth >= Tokens.px(820) ? 3 : 2
            // Reparto equilibrado: los grupos mas grandes primero, cada uno a la
            // columna mas corta; dentro de cada columna, el orden de siempre.
            readonly property var layoutCols: {
                const groups = KeybindState.filtered;
                const cols = [];
                const heights = [];
                for (let i = 0; i < content.columns; i++) {
                    cols.push([]);
                    heights.push(0);
                }
                const bySize = groups.map((g, i) => i).sort((a, b) => groups[b].items.length - groups[a].items.length || a - b);
                for (const i of bySize) {
                    let best = 0;
                    for (let c = 1; c < content.columns; c++) if (heights[c] < heights[best]) best = c;
                    cols[best].push(i);
                    heights[best] += groups[i].items.length + 1.6;
                }
                // Columnas en el orden de su primer grupo: se lee de izquierda a derecha.
                return cols.filter(c => c.length).map(c => c.sort((a, b) => a - b)).sort((a, b) => a[0] - b[0]).map(c => c.map(i => groups[i]));
            }

            Connections {
                target: window
                function onShouldShowChanged() {
                    if (window.shouldShow) search.focusInput();
                }
            }
            Component.onCompleted: search.focusInput()
            // La consulta vive en KeybindState (abrir la limpia); el campo la sigue.
            Connections {
                target: KeybindState
                function onQueryChanged() {
                    if (search.text !== KeybindState.query) search.text = KeybindState.query;
                }
            }

            function handleKey(event: var): bool {
                if (event.key === Qt.Key_Escape) {
                    if (KeybindState.query) KeybindState.query = "";
                    else KeybindState.close();
                    return true;
                }
                return false;
            }

            component T: Text {
                property int size: Tokens.type.body
                property int wt: Tokens.weight.regular
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: size
                font.weight: wt
                elide: Text.ElideRight
            }

            Surface {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: content.maxWidth
                height: Math.min(col.implicitHeight + 2 * Tokens.space.lg, content.height - 2 * Tokens.screenEdge)
                level: 3
                translucent: true
                radius: Tokens.radius.xl
                opacity: window.presence.progress
                scale: window.presence.contentScale

                // Sin esto un clic en el padding atravesaria y cerraria la guia.
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: col
                    x: Tokens.space.lg
                    y: Tokens.space.lg
                    width: parent.width - 2 * Tokens.space.lg
                    height: parent.height - 2 * Tokens.space.lg
                    spacing: Tokens.space.md

                    // Cabecera: que es, cuantos, buscar.
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.space.md
                        Icon { name: "keyboard"; size: Tokens.icon.lg; color: Colors.accent }
                        T { text: I18n.tr("Shortcuts"); size: Tokens.type.headline; wt: Tokens.weight.semibold }
                        T {
                            Layout.fillWidth: true
                            size: Tokens.type.label
                            color: Colors.border
                            text: !KeybindState.data ? I18n.tr("Reading the Hyprland shortcuts…")
                                : KeybindState.query ? I18n.trn("%n result", "%n results", KeybindState.shownCount)
                                : I18n.trn("%n shortcut · read from Hyprland when opening", "%n shortcuts · read from Hyprland when opening", KeybindState.total)
                        }
                        SearchField {
                            id: search
                            Layout.preferredWidth: Tokens.px(320)
                            placeholder: I18n.tr("Search a shortcut…")
                            keyHandler: (event) => content.handleKey(event)
                            onTextChanged: KeybindState.query = search.text
                        }
                    }

                    // Grupos en columnas; si no entran, se desplazan.
                    Flickable {
                        id: scroller
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: columnsRow.implicitHeight
                        contentWidth: width
                        contentHeight: columnsRow.implicitHeight
                        interactive: contentHeight > height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        // Indicador de desplazamiento (solo si no entra), como en el dashboard.
                        Rectangle {
                            parent: scroller
                            visible: scroller.interactive
                            x: scroller.width - 3
                            y: scroller.visibleArea.yPosition * scroller.height
                            width: 3
                            height: scroller.visibleArea.heightRatio * scroller.height
                            radius: 1.5
                            color: Colors.border
                            opacity: 0.6
                        }

                        RowLayout {
                            id: columnsRow
                            width: scroller.width
                            spacing: Tokens.space.md
                            Repeater {
                                model: content.layoutCols
                                ColumnLayout {
                                    id: column
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    Layout.alignment: Qt.AlignTop
                                    spacing: Tokens.space.md
                                    Repeater {
                                        model: column.modelData
                                        KeybindGroup {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            group: modelData
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Sin resultados
                    T {
                        visible: !!KeybindState.data && KeybindState.shownCount === 0
                        Layout.alignment: Qt.AlignHCenter
                        text: I18n.tr("No shortcut matches “%1”", KeybindState.query)
                        color: Colors.textMuted
                    }
                    T {
                        Layout.alignment: Qt.AlignHCenter
                        text: I18n.tr("Type to search · Esc closes · the descriptions come from binds.lua")
                        size: Tokens.type.caption
                        color: Colors.border
                    }
                }
            }
        }
    }
}
