// Lista de fuentes de FontPicker (Fase 10 B2): busqueda y una fila por
// familia, cada nombre escrito en su fuente con una muestra; la elegida con
// fondo y check. Alto acotado (siete filas) y desplazable. Emite chosen(f)
// solo si cambia y closed() siempre.
import QtQuick
import ".." // Colors.qml, Tokens.qml

Column {
    id: root

    property var families: []
    property string current: ""
    property string sample: "Aa Bb 0123 ¿Qué tal?"
    signal chosen(string family)
    signal closed

    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        return q ? root.families.filter(f => f.toLowerCase().indexOf(q) >= 0) : root.families;
    }

    spacing: Tokens.space.xs
    onVisibleChanged: if (visible) { search.text = ""; Qt.callLater(search.focusInput); }

    SearchField {
        id: search
        width: parent.width
        size: "regular"
        placeholder: root.families.length ? "Buscar entre " + root.families.length + " fuentes" : "Buscando fuentes…"
        keyHandler: (event) => {
            if (event.key === Qt.Key_Escape) { root.closed(); return true; }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.shown.length) {
                    if (root.shown[0] !== root.current) root.chosen(root.shown[0]);
                    root.closed();
                }
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
        delegate: Rectangle {
            id: opt
            required property string modelData
            readonly property bool sel: opt.modelData === root.current
            width: list.width
            height: Tokens.row.height + Tokens.space.xs
            radius: Tokens.radius.sm
            color: opt.sel ? Colors.accentAltContainer : "transparent"
            StateLayer { hovered: optMouse.containsMouse; pressed: optMouse.pressed }
            Row {
                anchors.left: parent.left
                anchors.leftMargin: Tokens.space.sm
                anchors.right: parent.right
                anchors.rightMargin: Tokens.space.sm
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.space.xs
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "check"
                    size: Tokens.icon.sm
                    opacity: opt.sel ? 1 : 0
                    color: Colors.textOnAccentAltContainer
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.45
                    elide: Text.ElideRight
                    text: opt.modelData
                    color: opt.sel ? Colors.textOnAccentAltContainer : Colors.text
                    font.family: opt.modelData
                    font.pixelSize: Tokens.type.body
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.5
                    elide: Text.ElideRight
                    text: root.sample
                    color: opt.sel ? Colors.textOnAccentAltContainer : Colors.textMuted
                    font.family: opt.modelData
                    font.pixelSize: Tokens.type.label
                }
            }
            MouseArea {
                id: optMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!opt.sel) root.chosen(opt.modelData);
                    root.closed();
                }
            }
        }
    }
    Text {
        visible: root.families.length > 0 && root.shown.length === 0
        text: "Ninguna fuente instalada coincide."
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
    }
}
