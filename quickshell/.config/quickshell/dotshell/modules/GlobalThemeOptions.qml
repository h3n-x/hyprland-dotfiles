// Opciones de color de TODOS los wallpapers (Fase 3 B8b): esquema
// predeterminado y contraste (decisiones B8b y B8d: 0 / 0.33 / 0.66 / 1).
// Contenido del panel "Tema global" de la galeria. Elegir guarda la
// preferencia al instante; se usa en el proximo cambio de tema (no se
// reaplica nada, B8b-5).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml

ColumnLayout {
    id: root

    property string scheme: "scheme-content"
    property real contrast: 0

    signal schemeChosen(string scheme)
    signal contrastChosen(real contrast)

    readonly property var schemes: [
        ["scheme-content", "Contenido"], ["scheme-tonal-spot", "Tonal"], ["scheme-vibrant", "Vibrante"],
        ["scheme-expressive", "Expresivo"], ["scheme-fidelity", "Fidelidad"], ["scheme-neutral", "Neutro"],
        ["scheme-monochrome", "Monocromo"], ["scheme-rainbow", "Arcoíris"], ["scheme-fruit-salad", "Macedonia"]]
    readonly property var levels: [[0, "Estándar"], [0.33, "Medio"], [0.66, "Alto"], [1, "Máximo"]]
    property bool listOpen: false

    function nameOf(s: string): string {
        for (const e of root.schemes)
            if (e[0] === s) return e[1];
        return s;
    }

    spacing: Tokens.space.sm

    Text {
        text: "TODOS LOS WALLPAPERS"
        color: Colors.m3onSurfaceVariant
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.caption
        font.weight: Tokens.weight.semibold
        font.letterSpacing: 0.6
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Esquema predeterminado"
            color: Colors.m3onSurface
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
        }
        Item { Layout.fillWidth: true }
        Rectangle {
            implicitHeight: Tokens.pill.height - Tokens.space.xs
            implicitWidth: pickRow.implicitWidth + Tokens.space.md * 2
            radius: Tokens.radius.pill(height)
            color: root.listOpen ? Colors.m3secondaryContainer : "transparent"
            border.color: root.listOpen ? "transparent" : Colors.m3outlineVariant
            StateLayer { hovered: pickMouse.containsMouse; pressed: pickMouse.pressed }
            Row {
                id: pickRow
                anchors.centerIn: parent
                spacing: Tokens.space.hair
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.nameOf(root.scheme)
                    color: root.listOpen ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
                Icon {
                    name: root.listOpen ? "arrow_drop_up" : "arrow_drop_down"
                    size: Tokens.icon.sm
                    color: root.listOpen ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                }
            }
            MouseArea {
                id: pickMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.listOpen = !root.listOpen
            }
        }
    }

    // Lista de esquemas (se despliega en el panel).
    Column {
        visible: root.listOpen
        Layout.fillWidth: true
        Repeater {
            model: root.schemes
            Rectangle {
                id: opt
                required property var modelData
                readonly property bool sel: opt.modelData[0] === root.scheme
                width: parent.width
                height: Tokens.row.height - Tokens.space.xs
                radius: Tokens.radius.sm
                color: opt.sel ? Colors.m3secondaryContainer : "transparent"
                StateLayer { hovered: optMouse.containsMouse; pressed: optMouse.pressed }
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.space.sm
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space.xs
                    Icon {
                        name: "check"
                        size: Tokens.icon.sm
                        opacity: opt.sel ? 1 : 0
                        color: Colors.m3onSecondaryContainer
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: opt.modelData[1]
                        color: opt.sel ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                    }
                }
                MouseArea {
                    id: optMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!opt.sel) root.schemeChosen(opt.modelData[0]);
                        root.listOpen = false;
                    }
                }
            }
        }
    }

    Text {
        text: "Contraste"
        color: Colors.m3onSurface
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
    }
    // Control segmentado: la seleccion es una pildora dentro del segmento.
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Tokens.pill.height + Tokens.space.xs
        radius: Tokens.radius.pill(height)
        color: "transparent"
        border.color: Colors.m3outlineVariant
        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 0
            Repeater {
                model: root.levels
                Item {
                    id: seg
                    required property var modelData
                    required property int index
                    readonly property bool sel: Math.abs(root.contrast - seg.modelData[0]) < 0.01
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Rectangle {
                        anchors.fill: parent
                        radius: Tokens.radius.pill(height)
                        color: seg.sel ? Colors.m3secondaryContainer : "transparent"
                        StateLayer {
                            radius: parent.radius
                            hovered: segMouse.containsMouse
                            pressed: segMouse.pressed
                            contentColor: seg.sel ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                        }
                    }
                    Row {
                        anchors.centerIn: parent
                        spacing: Tokens.space.hair
                        Icon { visible: seg.sel; name: "check"; size: Tokens.icon.sm; color: Colors.m3onSecondaryContainer }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: seg.modelData[1]
                            color: seg.sel ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            font.weight: seg.sel ? Tokens.weight.semibold : Tokens.weight.regular
                        }
                    }
                    MouseArea {
                        id: segMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (!seg.sel) root.contrastChosen(seg.modelData[0])
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Se usan en el próximo cambio de tema."
        color: Colors.m3onSurfaceVariant
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.caption
        wrapMode: Text.WordWrap
    }
}
