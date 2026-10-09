// Deslizador de un valor numerico (Fase 10 B1): riel, relleno y perilla con
// el mismo dibujo que la barra de progreso de la musica (MediaHero), y el
// valor a la derecha. Clic en el valor = escribirlo (lo valida quien lo
// guarda: el motor de opciones muestra el motivo si no vale). No guarda
// estado: el consumidor da `value` y recibe moved(v) al soltar, con cada
// tecla y al confirmar el texto; mientras se arrastra solo cambia lo que se ve.
//
//   Slider { from: 2; to: 30; step: 1; unit: "s"; value: x; onMoved: v => x = v }
//
// Rangos muy anchos (to/from >= 50, p. ej. 0,1-100 GiB o 15-1440 min) van en escala
// logaritmica: cada decada ocupa lo mismo y los valores se redondean a dos
// cifras. Teclado: flechas un paso, RePag/AvPag diez, Inicio/Fin los extremos.
import QtQuick
import ".." // Colors.qml, Tokens.qml

Item {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    // 0 = el paso por defecto: 1 entero, o una centesima redonda del rango.
    property real step: 0
    property bool integer: false
    property string unit: ""
    // Textos para valores concretos ({"0": "Automático"}).
    property var labels: ({})
    // Fraccion mostrada como porcentaje (1 = "100 %"; Fase 12, tamano del texto).
    property bool percent: false
    signal moved(real value)

    readonly property bool log: root.from > 0 && root.to / root.from >= 50
    readonly property real stepSize: root.step > 0 ? root.step
        : root.integer ? 1 : Math.pow(10, Math.floor(Math.log10((root.to - root.from) / 100)))
    readonly property bool dragging: mouse.pressed
    property real dragValue: 0
    readonly property real shown: root.dragging ? root.dragValue : root.value
    readonly property real frac: root.fracOf(root.shown)

    function fracOf(v: real): real {
        const c = Math.max(root.from, Math.min(root.to, v));
        if (root.log) return Math.log(c / root.from) / Math.log(root.to / root.from);
        return root.to > root.from ? (c - root.from) / (root.to - root.from) : 0;
    }
    // Cifras decimales de un paso (0,1 -> 1), para no arrastrar 0,30000000004.
    function decimals(x: real): int {
        const s = String(x);
        return s.indexOf(".") < 0 ? 0 : s.length - s.indexOf(".") - 1;
    }
    function snap(v: real): real {
        let q = root.stepSize;
        // Logaritmica: dos cifras significativas (0,12 / 1,2 / 12 / 120).
        if (root.log) q = Math.max(root.integer ? 1 : 0, Math.pow(10, Math.floor(Math.log10(Math.max(v, 1e-9))) - 1)) || root.stepSize;
        const r = Number((Math.round(v / q) * q).toFixed(Math.max(root.decimals(q), 0)));
        return Math.max(root.from, Math.min(root.to, r));
    }
    function valueAt(f: real): real {
        const t = Math.max(0, Math.min(1, f));
        return root.snap(root.log ? root.from * Math.pow(root.to / root.from, t) : root.from + t * (root.to - root.from));
    }
    function format(v: real): string {
        if (root.labels && root.labels.hasOwnProperty(String(v))) return root.labels[String(v)];
        if (root.percent) return Math.round(v * 100) + " %";
        const d = root.log ? (v < 1 ? 2 : v < 10 ? 1 : 0) : root.decimals(root.stepSize);
        const n = Number(v.toFixed(d));
        return String(n).replace(".", ",") + (root.unit ? " " + root.unit : "");
    }
    // Un paso (o diez) en la direccion pedida; en escala logaritmica, en
    // fraccion del riel.
    function nudge(dir: int, big: bool): void {
        let v;
        if (root.log)
            v = root.valueAt(root.fracOf(root.value) + dir * (big ? 0.1 : 0.02));
        else
            v = root.snap(root.value + dir * root.stepSize * (big ? 10 : 1));
        if (v !== root.value) root.moved(v);
    }

    implicitWidth: Tokens.px(200) + Tokens.space.md + valueBox.width
    implicitHeight: Tokens.pill.height
    activeFocusOnTab: true

    Keys.onPressed: (event) => {
        if (edit.activeFocus) return;
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) root.nudge(-1, false);
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) root.nudge(1, false);
        else if (event.key === Qt.Key_PageDown) root.nudge(-1, true);
        else if (event.key === Qt.Key_PageUp) root.nudge(1, true);
        else if (event.key === Qt.Key_Home) root.moved(root.from);
        else if (event.key === Qt.Key_End) root.moved(root.to);
        else return;
        event.accepted = true;
    }

    Item {
        id: track
        anchors.left: parent.left
        anchors.right: valueBox.left
        anchors.rightMargin: Tokens.space.md
        anchors.verticalCenter: parent.verticalCenter
        height: Tokens.px(16)

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Colors.tint(Colors.textMuted, Tokens.tint.track)
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * root.frac
            height: 4
            radius: 2
            color: Colors.accent
        }
        // Halo de foco del teclado y de hover alrededor de la perilla.
        Rectangle {
            visible: root.activeFocus || mouse.containsMouse
            x: knob.x + knob.width / 2 - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.pill.height
            height: width
            radius: width / 2
            color: Colors.tint(Colors.accent, root.activeFocus ? Tokens.stateLayer.focus : Tokens.stateLayer.hover)
        }
        Rectangle {
            id: knob
            x: parent.width * root.frac - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: mouse.pressed ? Tokens.px(18) : (mouse.containsMouse ? Tokens.px(16) : Tokens.px(14))
            height: width
            radius: width / 2
            color: Colors.accent
            Behavior on width { NumberAnimation { duration: Tokens.motion.fast } }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.topMargin: -Tokens.space.xs
            anchors.bottomMargin: -Tokens.space.xs
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: (m) => {
                root.forceActiveFocus();
                root.dragValue = root.valueAt(m.x / width);
            }
            onPositionChanged: (m) => {
                if (mouse.pressed) root.dragValue = root.valueAt(m.x / width);
            }
            onReleased: if (root.dragValue !== root.value) root.moved(root.dragValue)
        }
    }

    // Valor; clic para escribirlo.
    Rectangle {
        id: valueBox
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Tokens.px(84)
        height: Tokens.pill.height
        radius: Tokens.radius.sm
        color: edit.activeFocus ? Colors.surfaceHighest : "transparent"
        border.width: edit.activeFocus ? 1 : 0
        border.color: Colors.accent
        StateLayer {
            radius: parent.radius
            hovered: valueMouse.containsMouse && !edit.activeFocus
        }
        Text {
            visible: !edit.activeFocus
            anchors.fill: parent
            anchors.rightMargin: Tokens.space.xs
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            text: root.format(root.shown)
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
            font.features: Tokens.tabularNumbers
        }
        TextInput {
            id: edit
            visible: activeFocus
            anchors.fill: parent
            anchors.leftMargin: Tokens.space.xs
            anchors.rightMargin: Tokens.space.xs
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            color: Colors.text
            selectionColor: Colors.accentContainer
            selectedTextColor: Colors.textOnAccentContainer
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
            font.features: Tokens.tabularNumbers
            selectByMouse: true
        // Cursor fijo, como SearchField: el parpadeo repinta sin parar.
        cursorDelegate: Rectangle {
            width: 2
            color: Colors.accent
            visible: edit.cursorVisible
        }
            // Enter confirma, Esc deja el valor como estaba.
            Keys.onEscapePressed: (event) => {
                event.accepted = true;
                root.forceActiveFocus();
            }
            onAccepted: {
                const n = Number(edit.text.trim().replace(",", "."));
                root.forceActiveFocus();
                if (edit.text.trim() !== "" && n !== root.value) root.moved(n);
            }
        }
        MouseArea {
            id: valueMouse
            visible: !edit.activeFocus
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.IBeamCursor
            onClicked: {
                edit.text = String(Number(root.value.toFixed(6))).replace(".", ",");
                edit.forceActiveFocus();
                edit.selectAll();
            }
        }
    }
}
