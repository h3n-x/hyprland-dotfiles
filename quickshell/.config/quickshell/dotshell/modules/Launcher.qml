// Reemplaza a "rofi -show drun" (SUPER+D, ver binds.lua) -- fuera de
// alcance a proposito: window-switcher (SUPER+TAB), rofimoji, power-menu,
// clipboard-menu y wallpaper-selector siguen en rofi tal cual, ver Fase D
// del plan.
//
// PanelWindow (no FloatingWindow) a proposito: FloatingWindow es una
// ventana de verdad manejada por Hyprland (necesitaria una window_rule
// para centrarla), PanelWindow es layer-shell y se puede centrar con el
// mismo truco de anchors que Bar.qml/Osd.qml, sin tocar rules.lua.
// HyprlandFocusGrab (protocolo hyprland_focus_grab_v1) queda declarado
// como lo documenta la API, aunque su aporte real es marginal aca: la
// ventana cubre toda la pantalla, asi que el MouseArea de fondo (z:-1) es
// el que realmente cierra al clickear afuera.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import ".." // Colors.qml, LauncherState.qml

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

    // Animacion de apertura/cierre: si "visible" se atara directo a
    // LauncherState.visible, la superficie wlr-layer-shell se desmapea
    // al instante al cerrar y no da tiempo a animar nada. Se mantiene la
    // ventana viva ("closing") un instante mas mientras la card anima su
    // opacity/scale a 0, y recien ahi se desmapea de verdad.
    readonly property bool shouldShow: LauncherState.visible
    property bool closing: false
    visible: window.shouldShow || window.closing

    onShouldShowChanged: {
        if (window.shouldShow) {
            window.closing = false;
            searchField.text = "";
            listView.currentIndex = 0;
            searchField.forceActiveFocus();
        } else {
            window.closing = true;
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer
        interval: 160
        onTriggered: window.closing = false
    }

    HyprlandFocusGrab {
        id: grab
        windows: [window]
        active: window.visible
        onCleared: LauncherState.visible = false
    }

    property string query: ""

    // Fuzzy match tipo "subsecuencia" (los caracteres de la query tienen
    // que aparecer en orden en el texto, no necesariamente juntos) --
    // alcanza para escribir "vsc" y encontrar "Visual Studio Code" sin
    // sumar una libreria externa. Puntaje mas alto para matches
    // consecutivos y matches que arrancan en un limite de palabra.
    // Devuelve null si no matchea, o {score, positions} para resaltar.
    function fuzzyMatch(text, query) {
        if (!query) return { score: 0, positions: [] };
        if (!text) return null;
        const t = text.toLowerCase();
        const q = query.toLowerCase();
        let ti = 0, qi = 0, consecutive = 0, score = 0;
        const positions = [];
        while (ti < t.length && qi < q.length) {
            if (t[ti] === q[qi]) {
                positions.push(ti);
                score += 10 + consecutive * 5;
                if (ti === 0 || t[ti - 1] === " " || t[ti - 1] === "-") score += 15;
                consecutive++;
                qi++;
            } else {
                consecutive = 0;
            }
            ti++;
        }
        if (qi < q.length) return null;
        score -= (t.length - q.length) * 0.1;
        return { score, positions };
    }

    function escapeHtml(s) {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // Marca en Colors.accent los caracteres que matchearon la busqueda --
    // sin busqueda, o sin match en el nombre (matcheo por generic
    // name/keywords), se muestra el nombre tal cual.
    function highlightedName(name, positions) {
        if (!positions || positions.length === 0) return window.escapeHtml(name);
        const posSet = new Set(positions);
        let result = "";
        for (let i = 0; i < name.length; i++) {
            const ch = window.escapeHtml(name[i]);
            result += posSet.has(i) ? ("<b style=\"color:" + Colors.accent + "\">" + ch + "</b>") : ch;
        }
        return result;
    }

    // Sin busqueda: orden alfabetico (antes era el orden arbitrario que
    // da DesktopEntries, sin ningun criterio). Con busqueda: fuzzy match
    // sobre nombre (prioridad alta) / generic name / keywords, ordenado
    // por score.
    readonly property var filtered: {
        const q = window.query.trim();
        const apps = DesktopEntries.applications.values;

        if (!q) {
            return apps.slice()
                .sort((a, b) => a.name.localeCompare(b.name))
                .map((e) => ({ entry: e, positions: [] }));
        }

        const results = [];
        for (const e of apps) {
            const nameMatch = window.fuzzyMatch(e.name || "", q);
            if (nameMatch) {
                results.push({ entry: e, score: nameMatch.score + 100, positions: nameMatch.positions });
                continue;
            }
            const genericMatch = e.genericName ? window.fuzzyMatch(e.genericName, q) : null;
            if (genericMatch) {
                results.push({ entry: e, score: genericMatch.score, positions: [] });
                continue;
            }
            if (e.keywords && e.keywords.some((k) => window.fuzzyMatch(k, q))) {
                results.push({ entry: e, score: 1, positions: [] });
            }
        }
        results.sort((a, b) => b.score - a.score);
        return results;
    }

    function launch(entry) {
        entry.execute();
        LauncherState.visible = false;
    }

    // Click en el fondo transparente (afuera de la card) tambien cierra --
    // z:-1 para no tapar los clicks de la card, que se dibuja despues.
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: LauncherState.visible = false
    }

    // Tamano dinamico: la card crece/encoge segun la cantidad de
    // resultados en vez de ser siempre una caja fija de 560x420 -- hasta
    // 8 filas visibles, con scroll si hay mas.
    readonly property int rowHeight: 46
    readonly property int maxVisibleRows: 8
    readonly property int visibleRows: Math.max(1, Math.min(maxVisibleRows, filtered.length))
    readonly property int listHeight: filtered.length > 0 ? visibleRows * rowHeight : 56

    Item {
        id: card
        anchors.centerIn: parent
        width: 560
        // margenes (16*2) + searchBox + lista/"sin resultados" + footer +
        // dos huecos de "spacing" del ColumnLayout (entre esas 3 filas).
        height: 16 * 2 + searchBox.height + window.listHeight + footerText.implicitHeight + 12 * 2
        // Animacion de apertura/cierre -- ver el comentario largo en
        // "shouldShow"/"closing" mas arriba.
        opacity: window.shouldShow ? 1 : 0
        scale: window.shouldShow ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        // Sombra pobre-pero-honesta: 3 capas semitransparentes cada vez
        // mas grandes detras de la card, sin sumar Qt5Compat.
        // GraphicalEffects (paquete qt5compat, no siempre instalado) solo
        // para un drop-shadow.
        Repeater {
            model: 3
            Rectangle {
                required property int index
                anchors.centerIn: parent
                width: card.width + (index + 1) * 6
                height: card.height + (index + 1) * 6
                radius: 20 + (index + 1) * 3
                color: "black"
                opacity: 0.06 - index * 0.015
                z: -1
            }
        }

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 20
            color: Colors.bg1
            border.color: Colors.br
            border.width: 1

            // Sin esto, clickear el padding de la card (no cubierto por
            // ningun control) atravesaria hacia el MouseArea de fondo
            // (z:-1, arriba) y cerraria el launcher -- un Rectangle solo
            // no consume clicks.
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: 12
                    color: Colors.bg0
                    border.color: searchField.activeFocus ? Colors.accent : Colors.br
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        color: Colors.br
                        font.pixelSize: 15
                    }

                    TextInput {
                        id: searchField
                        anchors.fill: parent
                        anchors.leftMargin: 36
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: Colors.fg
                        font.pixelSize: 15
                        clip: true

                        onTextChanged: {
                            window.query = searchField.text;
                            listView.currentIndex = 0;
                        }
                        Keys.onDownPressed: listView.incrementCurrentIndex()
                        Keys.onUpPressed: listView.decrementCurrentIndex()
                        Keys.onReturnPressed: {
                            const item = window.filtered[listView.currentIndex];
                            if (item) window.launch(item.entry);
                        }
                        Keys.onEscapePressed: LauncherState.visible = false
                    }

                    Text {
                        visible: searchField.text.length === 0
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Buscar aplicaciones..."
                        color: Colors.br
                        font.pixelSize: 14
                    }
                }

                ListView {
                    id: listView
                    visible: window.filtered.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.listHeight
                    clip: true
                    model: window.filtered
                    currentIndex: 0
                    highlightMoveDuration: 80
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: appRow
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === listView.currentIndex
                        width: listView.width
                        height: window.rowHeight - 2
                        radius: 10
                        color: appRow.selected ? Colors.accent : (rowMouse.containsMouse ? Colors.hoverBg : "transparent")
                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 12

                            IconImage {
                                Layout.alignment: Qt.AlignVCenter
                                implicitSize: 32
                                source: appRow.modelData.entry.icon ? Quickshell.iconPath(appRow.modelData.entry.icon, "application-x-executable") : ""
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: appRow.selected
                                        ? window.escapeHtml(appRow.modelData.entry.name)
                                        : window.highlightedName(appRow.modelData.entry.name, appRow.modelData.positions)
                                    textFormat: Text.RichText
                                    color: appRow.selected ? Colors.bg0 : Colors.fg
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: !!appRow.modelData.entry.genericName
                                    Layout.fillWidth: true
                                    text: appRow.modelData.entry.genericName
                                    color: appRow.selected ? Colors.bg0 : Colors.br
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: window.launch(appRow.modelData.entry)
                        }
                    }
                }

                Text {
                    visible: window.filtered.length === 0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: window.listHeight
                    verticalAlignment: Text.AlignVCenter
                    text: "Sin resultados"
                    color: Colors.br
                    font.pixelSize: 13
                }

                Text {
                    id: footerText
                    Layout.alignment: Qt.AlignHCenter
                    text: "↑↓ navegar   ⏎ abrir   esc cerrar"
                    color: Colors.br
                    font.pixelSize: 11
                }
            }
        }
    }
}
