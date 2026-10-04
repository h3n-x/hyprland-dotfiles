// Lista para agregar una distribucion (Fase 10 B3; ver LayoutList): busqueda
// por nombre o codigo, una fila por distribucion o variante. Emite chosen(id)
// y closed().
import QtQuick
import ".." // Colors.qml, Tokens.qml

Column {
    id: root

    property var entries: []
    property var taken: []
    signal chosen(string id)
    signal closed

    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        const pool = root.entries.filter(e => root.taken.indexOf(e.id) < 0);
        return q ? pool.filter(e => e.label.toLowerCase().indexOf(q) >= 0 || e.id.toLowerCase().indexOf(q) >= 0) : pool;
    }

    spacing: Tokens.space.xs
    onVisibleChanged: if (visible) { search.text = ""; Qt.callLater(search.focusInput); }

    SearchField {
        id: search
        width: parent.width
        size: "regular"
        placeholder: "Buscar una distribución (spanish, latam, dvorak…)"
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
            Text {
                anchors.left: parent.left
                anchors.leftMargin: Tokens.space.md
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
                text: opt.modelData.id
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
