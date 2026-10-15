// Lista para agregar algo a una lista de opciones, debajo de su fila (Fase 10
// B3 para las distribuciones del teclado, LayoutList; Fase 11 B5 tambien para
// las aplicaciones fijadas, ChipList): busqueda por nombre o codigo, una fila
// por entrada { id, label, detail?, icon? (ruta de imagen) }. Emite chosen(id)
// y closed().
import QtQuick
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml

Column {
    id: root

    property var entries: []
    property var taken: []
    property string placeholder: I18n.tr("Search…")
    signal chosen(string id)
    signal closed

    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        const pool = root.entries.filter(e => root.taken.indexOf(e.id) < 0);
        return q ? pool.filter(e => e.label.toLowerCase().indexOf(q) >= 0 || e.id.toLowerCase().indexOf(q) >= 0
            || (e.detail || "").toLowerCase().indexOf(q) >= 0) : pool;
    }

    spacing: Tokens.space.xs
    onVisibleChanged: if (visible) { search.text = ""; Qt.callLater(search.focusInput); }

    SearchField {
        id: search
        width: parent.width
        size: "regular"
        placeholder: root.placeholder
        keyHandler: (event) => {
            if (event.key === Qt.Key_Escape) { root.closed(); return true; }
            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.shown.length) {
                root.chosen(root.shown[0].id);
                root.closed();
                return true;
            }
            return false;
        }
    }
    ListView {
        id: list
        width: parent.width
        height: Math.min(contentHeight, 7 * (Tokens.row.height + Tokens.space.xs))
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.shown
        // La misma barra que la pagina del centro (fija sobre la lista).
        Scrollbar {
            parent: list
            flickable: list
            x: list.width - width
            height: list.height
        }
        delegate: Rectangle {
            id: opt
            required property var modelData
            width: list.width
            height: Tokens.row.height + Tokens.space.xs
            radius: Tokens.radius.sm
            color: "transparent"
            StateLayer { hovered: optMouse.containsMouse; pressed: optMouse.pressed }
            IconImage {
                id: optIcon
                visible: !!opt.modelData.icon
                anchors.left: parent.left
                anchors.leftMargin: Tokens.space.md
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: visible ? Tokens.icon.md : 0
                source: opt.modelData.icon || ""
            }
            Text {
                anchors.left: optIcon.right
                anchors.leftMargin: optIcon.visible ? Tokens.space.sm : 0
                anchors.right: code.left
                anchors.rightMargin: Tokens.space.md
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: opt.modelData.label
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
            }
            Text {
                id: code
                anchors.right: parent.right
                anchors.rightMargin: Tokens.space.md
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, opt.width / 2)
                elide: Text.ElideRight
                text: opt.modelData.detail !== undefined ? opt.modelData.detail : opt.modelData.id
                color: Colors.textMuted
                font.family: Tokens.font.mono
                font.pixelSize: Tokens.type.caption
            }
            MouseArea {
                id: optMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.chosen(opt.modelData.id); root.closed(); }
            }
        }
    }
}
