// Lanzador de aplicaciones (SUPER+D, ver binds.lua). Desde la Fase 4 B0 se arma con piezas compartidas:
// OverlayWindow (ventana de pantalla completa en el monitor enfocado) y
// Picker (tarjeta con busqueda y lista); aca queda solo lo propio: las
// aplicaciones (DesktopEntries), el filtro, la fila y lanzar.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml, LauncherState.qml, Fuzzy.qml, AppInfo.qml

OverlayWindow {
    id: window

    open: LauncherState.visible
    targetScreen: LauncherState.screen
    onDismissed: LauncherState.close()

    // Al abrir: busqueda vacia y foco en el campo.
    onShouldShowChanged: if (window.shouldShow) picker.reset()

    // Sin busqueda: orden alfabetico. Con busqueda: coincidencia difusa sobre
    // nombre (prioridad alta) / generic name / keywords, por puntaje.
    readonly property var filtered: {
        const q = picker.query.trim();
        const apps = DesktopEntries.applications.values;

        if (!q) {
            return apps.slice()
                .sort((a, b) => a.name.localeCompare(b.name))
                .map((e) => ({ entry: e, positions: [] }));
        }

        const results = [];
        for (const e of apps) {
            const nameMatch = Fuzzy.match(e.name || "", q);
            if (nameMatch) {
                results.push({ entry: e, score: nameMatch.score + 100, positions: nameMatch.positions });
                continue;
            }
            const genericMatch = e.genericName ? Fuzzy.match(e.genericName, q) : null;
            if (genericMatch) {
                results.push({ entry: e, score: genericMatch.score, positions: [] });
                continue;
            }
            if (e.keywords && e.keywords.some((k) => Fuzzy.match(k, q))) {
                results.push({ entry: e, score: 1, positions: [] });
            }
        }
        results.sort((a, b) => b.score - a.score);
        return results;
    }

    function launch(entry): void {
        entry.execute();
        LauncherState.close();
    }

    Picker {
        id: picker
        anchors.centerIn: parent
        presence: window.presence
        model: window.filtered
        placeholder: "Buscar aplicaciones..."
        hints: "↑↓ navegar   ⏎ abrir   esc cerrar"
        onAccepted: (item) => window.launch(item.entry)
        onDismissed: LauncherState.close()

        delegate: Rectangle {
            id: appRow
            required property var modelData
            required property int index
            readonly property bool selected: appRow.index === ListView.view.currentIndex
            width: ListView.view.width
            height: picker.rowHeight - Tokens.space.hair
            radius: Tokens.radius.md
            // Fila seleccionada en secondary_container (C3); el hover lo da la StateLayer.
            color: appRow.selected ? Colors.accentAltContainer : "transparent"
            Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }

            StateLayer {
                hovered: rowMouse.containsMouse
                pressed: rowMouse.pressed
                contentColor: appRow.selected ? Colors.textOnAccentAltContainer : Colors.text
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.space.sm
                anchors.rightMargin: Tokens.space.md
                spacing: Tokens.space.md

                // Icono de la aplicacion (tema de iconos, no Material: identifica la app).
                // La fila elegida: un fondito del color de la app (P5.6), solo si lo tiene.
                // (detras del icono y sin ocupar lugar: apagado, la fila es la de siempre).
                Item {
                    readonly property string app: appRow.modelData.entry ? appRow.modelData.entry.id : ""
                    readonly property bool tinted: appRow.selected && !!app && AppColors.has(app)
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: Tokens.space.xxl
                    implicitHeight: Tokens.space.xxl
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -Tokens.space.xs
                        radius: Tokens.radius.md
                        visible: parent.tinted
                        color: AppColors.container(parent.app)
                    }
                    IconImage {
                        anchors.fill: parent
                        implicitSize: Tokens.space.xxl
                        source: AppInfo.entryIcon(appRow.modelData.entry)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: appRow.selected
                            ? Fuzzy.escapeHtml(appRow.modelData.entry.name)
                            : Fuzzy.highlight(appRow.modelData.entry.name, appRow.modelData.positions)
                        textFormat: Text.RichText
                        color: appRow.selected ? Colors.textOnAccentAltContainer : Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.weight: appRow.selected ? Tokens.weight.semibold : Tokens.weight.medium
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: !!appRow.modelData.entry.genericName
                        Layout.fillWidth: true
                        text: appRow.modelData.entry.genericName
                        color: appRow.selected ? Colors.textOnAccentAltContainer : Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: window.launch(appRow.modelData.entry)
            }
        }
    }
}
