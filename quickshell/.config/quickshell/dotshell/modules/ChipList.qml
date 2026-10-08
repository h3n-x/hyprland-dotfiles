// Lista ordenada de aplicaciones o carpetas fijadas (Fase 11 B5, kinds "apps"
// y "folders" del esquema: dashboard.quick.*). Una ficha por elemento con su
// icono y nombre; la flecha la adelanta un lugar y la cruz la quita.
// "Agregar": aplicaciones -> la lista de busqueda debajo de la fila
// (PickList, como las distribuciones del teclado); carpetas -> el selector
// del portal (scripts/pick-file). No guarda estado: el consumidor da `value`
// y recibe edited(lista).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml, AppInfo.qml

Item {
    id: root

    property var value: []
    property int maxItems: 12
    // "apps" o "folders".
    property string mode: "apps"
    property bool open: false
    signal edited(var list)

    readonly property string home: Quickshell.env("HOME")
    // Aplicaciones para elegir (solo mientras la lista esta abierta).
    readonly property var entries: root.mode === "apps" && root.open
        ? DesktopEntries.applications.values.filter(e => !e.noDisplay)
            .map(e => ({ id: e.id, label: e.name, detail: e.genericName || "", icon: AppInfo.entryIcon(e) }))
            .sort((a, b) => a.label.localeCompare(b.label))
        : []

    function labelOf(v: string): string {
        if (root.mode === "apps") {
            const e = AppInfo.entry(v);
            return e ? e.name : v + " (no instalada)";
        }
        return v === root.home ? "Carpeta personal" : v.startsWith(root.home + "/") ? "~" + v.slice(root.home.length) : v;
    }
    function remove(i: int): void {
        const l = root.value.slice();
        l.splice(i, 1);
        root.edited(l);
    }
    function forward(i: int): void {
        if (i <= 0) return;
        const l = root.value.slice();
        const [x] = l.splice(i, 1);
        l.splice(i - 1, 0, x);
        root.edited(l);
    }
    function add(v: string): void {
        if (v && root.value.indexOf(v) < 0 && root.value.length < root.maxItems) root.edited(root.value.concat([v]));
    }

    // Selector de carpetas del portal: corre solo mientras esta abierto.
    property Process picker: Process {
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/pick-file", "--folder", "--start", root.home]
        stdout: StdioCollector {
            onStreamFinished: root.add(this.text.trim())
        }
    }

    // A lo ancho de la fila (va apilada bajo el titulo; la fila le da el ancho).
    implicitWidth: 360
    implicitHeight: flow.implicitHeight

    Flow {
        id: flow
        width: root.width
        spacing: Tokens.space.xs

        Repeater {
            model: root.value
            Rectangle {
                id: chip
                required property string modelData
                required property int index
                height: Tokens.pill.height - Tokens.space.xs
                width: chipRow.implicitWidth + Tokens.space.md
                radius: Tokens.radius.pill(height)
                color: "transparent"
                border.color: Colors.divider
                Row {
                    id: chipRow
                    x: Tokens.space.sm
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space.xs
                    IconImage {
                        visible: root.mode === "apps"
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: Tokens.icon.sm
                        source: root.mode === "apps" ? AppInfo.icon(chip.modelData) : ""
                    }
                    Icon {
                        visible: root.mode === "folders"
                        anchors.verticalCenter: parent.verticalCenter
                        name: "folder"
                        size: Tokens.icon.sm
                        color: Colors.textMuted
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 220)
                        elide: Text.ElideMiddle
                        text: root.labelOf(chip.modelData)
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                    }
                    ChipButton { visible: chip.index > 0; icon: "arrow_back"; onClicked: root.forward(chip.index) }
                    ChipButton { icon: "close"; onClicked: root.remove(chip.index) }
                }
            }
        }
        Rectangle {
            visible: root.value.length < root.maxItems
            height: Tokens.pill.height - Tokens.space.xs
            width: addRow.implicitWidth + Tokens.space.md * 2
            radius: Tokens.radius.pill(height)
            color: root.open ? Colors.accentAltContainer : "transparent"
            border.color: root.open ? "transparent" : root.activeFocus ? Colors.accent : Colors.divider
            StateLayer { hovered: addMouse.containsMouse; pressed: addMouse.pressed }
            Row {
                id: addRow
                anchors.centerIn: parent
                spacing: Tokens.space.xs
                Icon { anchors.verticalCenter: parent.verticalCenter; name: "add"; size: Tokens.icon.sm; color: root.open ? Colors.textOnAccentAltContainer : Colors.textMuted }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.mode === "apps" ? "Agregar" : "Elegir carpeta…"
                    color: root.open ? Colors.textOnAccentAltContainer : Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
            }
            MouseArea {
                id: addMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.mode === "apps") root.open = !root.open;
                    else if (!root.picker.running) root.picker.running = true;
                }
            }
        }

    }

    component ChipButton: Item {
        id: b
        property string icon
        signal clicked
        width: Tokens.icon.sm + Tokens.space.xs
        height: width
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        StateLayer { radius: width / 2; hovered: bm.containsMouse; pressed: bm.pressed }
        Icon { anchors.centerIn: parent; name: b.icon; size: Tokens.icon.sm - 2; color: Colors.textMuted }
        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
    }
}
