// Paso a paso para enteros de rango corto (Fase 10 B1): una pildora con
// "menos", el valor y "mas", con el mismo borde que Segmented y Select. En los
// extremos el boton queda atenuado. No guarda estado: el consumidor da
// `value` y recibe moved(v). Teclado: flechas, Inicio/Fin.
//
//   Stepper { from: 1; to: 10; value: x; labels: {"0": "Automático"}; onMoved: v => x = v }
import QtQuick
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root

    property int from: 0
    property int to: 10
    property int value: 0
    property string unit: ""
    property var labels: ({})
    signal moved(int value)

    function format(v: int): string {
        if (root.labels && root.labels.hasOwnProperty(String(v))) return root.labels[String(v)];
        return v + (root.unit ? " " + root.unit : "");
    }
    function go(v: int): void {
        const c = Math.max(root.from, Math.min(root.to, v));
        if (c !== root.value) root.moved(c);
    }

    implicitHeight: Tokens.pill.height
    implicitWidth: 2 * implicitHeight + valueText.width
    radius: Tokens.radius.pill(height)
    color: "transparent"
    border.color: root.activeFocus ? Colors.accent : Colors.divider
    activeFocusOnTab: true

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) root.go(root.value - 1);
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) root.go(root.value + 1);
        else if (event.key === Qt.Key_Home) root.go(root.from);
        else if (event.key === Qt.Key_End) root.go(root.to);
        else return;
        event.accepted = true;
    }

    component StepButton: Item {
        id: b
        property string icon
        property bool enabled2: true
        signal clicked
        width: root.height
        height: root.height
        StateLayer {
            radius: width / 2
            hovered: bm.containsMouse && b.enabled2
            pressed: bm.pressed && b.enabled2
        }
        Icon {
            anchors.centerIn: parent
            name: b.icon
            size: Tokens.icon.sm
            color: Colors.text
            opacity: b.enabled2 ? 1 : Tokens.opacity.disabled
        }
        MouseArea {
            id: bm
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: b.enabled2 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (b.enabled2) b.clicked()
        }
    }

    StepButton {
        anchors.left: parent.left
        icon: "remove"
        enabled2: root.value > root.from
        onClicked: root.go(root.value - 1)
    }
    Text {
        id: valueText
        anchors.centerIn: parent
        width: Math.max(Tokens.px(56), metrics.advanceWidth + Tokens.space.sm)
        horizontalAlignment: Text.AlignHCenter
        text: root.format(root.value)
        color: Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.body
        font.features: Tokens.tabularNumbers
    }
    // Ancho fijo para el texto mas largo posible: el control no salta.
    TextMetrics {
        id: metrics
        font: valueText.font
        text: {
            let w = "";
            for (const v of [root.from, root.to].concat(Object.keys(root.labels || {}).map(Number))) {
                const t = root.format(v);
                if (t.length > w.length) w = t;
            }
            return w;
        }
    }
    StepButton {
        anchors.right: parent.right
        icon: "add"
        enabled2: root.value < root.to
        onClicked: root.go(root.value + 1)
    }
}
