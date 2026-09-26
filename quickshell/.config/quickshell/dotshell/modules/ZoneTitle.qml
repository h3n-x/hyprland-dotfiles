// Titulo de una zona del dashboard (Fase 4 B7): nombre, un detalle opcional
// en tono bajo y, si la zona abre una vista, un chevron.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml

RowLayout {
    id: title
    property string text
    property string detail: ""
    property bool opens: false
    spacing: Tokens.space.sm

    Text {
        text: title.text
        color: Colors.m3onSurfaceVariant
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
        font.weight: Tokens.weight.semibold
    }
    Text {
        Layout.fillWidth: true
        text: title.detail
        color: Colors.m3outline
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
        elide: Text.ElideRight
    }
    Icon {
        visible: title.opens
        name: "chevron_right"
        size: Tokens.icon.sm
        color: Colors.m3outline
    }
}
