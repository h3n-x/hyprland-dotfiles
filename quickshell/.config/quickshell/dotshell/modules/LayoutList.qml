// Distribuciones del teclado (Fase 10 B3, input.keyboard.layouts): una ficha
// por distribucion, la primera es la principal; cada ficha se quita o pasa a
// ser la principal; "Agregar" abre la lista (XkbList, debajo de la fila, como
// la de Select). Nombres y variantes de /usr/share/X11/xkb/rules/base.xml,
// leido una vez. Hasta 4 (xkb). No guarda estado: el consumidor da `value`
// (["us", "latam:deadtilde"]) y recibe edited(lista).
import QtQuick
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml

Flow {
    id: root

    property var value: []
    property int maxItems: 4
    property bool open: false
    // [{ id: "latam:deadtilde", label: "Spanish (Latin American, dead tilde)" }]
    property var entries: []
    readonly property var labels: {
        const m = {};
        for (const e of root.entries) m[e.id] = e.label;
        return m;
    }
    signal edited(var list)

    function labelOf(id: string): string {
        return root.labels[id] || id;
    }
    function remove(i: int): void {
        const l = root.value.slice();
        l.splice(i, 1);
        if (l.length) root.edited(l);
    }
    function makeMain(i: int): void {
        const l = root.value.slice();
        const [x] = l.splice(i, 1);
        root.edited([x].concat(l));
    }
    function add(id: string): void {
        if (root.value.indexOf(id) < 0 && root.value.length < root.maxItems) root.edited(root.value.concat([id]));
    }

    property FileView xml: FileView {
        path: "/usr/share/X11/xkb/rules/base.xml"
        printErrors: false
        onLoaded: {
            const out = [];
            const lays = this.text().match(/<layout>[\s\S]*?<\/layout>/g) || [];
            for (const l of lays) {
                const n = l.match(/<configItem>[\s\S]*?<name>([^<]+)<\/name>[\s\S]*?<description>([^<]+)<\/description>/);
                if (!n) continue;
                out.push({ id: n[1], label: n[2] });
                const vs = l.match(/<variant>[\s\S]*?<\/variant>/g) || [];
                for (const v of vs) {
                    const m = v.match(/<name>([^<]+)<\/name>[\s\S]*?<description>([^<]+)<\/description>/);
                    if (m) out.push({ id: n[1] + ":" + m[1], label: m[2] });
                }
            }
            root.entries = out;
        }
    }

    spacing: Tokens.space.xs
    width: 360

    Repeater {
        model: root.value
        Rectangle {
            id: chip
            required property string modelData
            required property int index
            readonly property bool main: chip.index === 0
            height: Tokens.pill.height - Tokens.space.xs
            width: chipRow.implicitWidth + Tokens.space.md
            radius: Tokens.radius.pill(height)
            color: chip.main ? Colors.accentAltContainer : "transparent"
            border.color: chip.main ? "transparent" : Colors.divider
            Row {
                id: chipRow
                x: Tokens.space.sm
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.space.xs
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 220)
                    elide: Text.ElideRight
                    text: root.labelOf(chip.modelData)
                    color: chip.main ? Colors.textOnAccentAltContainer : Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                    font.weight: chip.main ? Tokens.weight.semibold : Tokens.weight.regular
                }
                // Pasar a principal (solo las que no lo son) y quitar.
                ChipButton { visible: !chip.main; icon: "arrow_upward"; onClicked: root.makeMain(chip.index) }
                ChipButton { visible: root.value.length > 1; icon: "close"; onClicked: root.remove(chip.index) }
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
                text: "Agregar"
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
            onClicked: root.open = !root.open
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
