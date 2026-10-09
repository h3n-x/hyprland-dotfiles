// La pantalla de entrada compartida por el bloqueo y el greeter (Fase 9 B3):
// fondo, hora apilada a la izquierda, tarjetas y tarjeta de la contrasena a
// la derecha. La tarjeta de la contrasena tiene un lugar fijo; las tarjetas
// crecen hacia arriba (y se desplazan suave cuando cambia la cantidad de filas).
//
// Secuencia (la misma en toda la cadena Plymouth -> greeter -> sesion ->
// bloqueo): M1 entrada = el fondo se difumina (desde `blurFrom`: 1 en el
// greeter, que viene del fondo difuminado de Plymouth; 0 en el bloqueo, que
// viene del escritorio) y entran reloj -> tarjetas -> tarjeta de la
// contrasena, escalonados; M2 salida (leave()) = salen al reves y el fondo
// queda nitido: el ultimo cuadro es el wallpaper del escritorio. Con "reducir
// movimiento" todo es inmediato. Nada se mueve si nada cambia.
//
// QtQuick puro: lo usan lock/LockView.qml y el greeter de SDDM.
import QtQuick
import ".." // Colors.qml, Tokens.qml

Item {
    id: stage

    required property var auth
    property url avatar
    property string user: ""
    property string subtitle: ""
    property bool capsLock: false
    property bool success: false
    property string successText: ""
    property date date: new Date()
    property var tiles: []
    property string tilesTitle: ""
    property bool tilesActionable: false
    property real blurFrom: 0

    signal tileActivated(string key)
    // Cada tecla, antes de manejarla (el bloqueo sigue el estado de Bloq Mayus).
    signal keyPressed(var event)
    signal exitFinished()

    // ---- M1 / M2 -----------------------------------------------------------------------------
    property real enter: 0
    property real leave: 0
    readonly property bool leaving: leaveAnim.running || stage.leave > 0
    function clamp01(x: real): real { return Math.max(0, Math.min(1, x)); }
    function ease(x: real): real { return 1 - Math.pow(1 - x, 3); }
    // 0 reloj, 1 tarjetas, 2 tarjeta de la contrasena: entran en ese orden, salen al reves.
    function inP(i: int): real { return stage.ease(stage.clamp01((stage.enter - i * 0.15) / 0.7)); }
    function outP(i: int): real { return stage.ease(stage.clamp01((stage.leave - (2 - i) * 0.15) / 0.7)); }
    function shown(i: int): real { return stage.inP(i) * (1 - stage.outP(i)); }
    function rise(i: int): real { return 24 * (1 - stage.inP(i)) - 16 * stage.outP(i); }
    readonly property real blurAmount: (stage.blurFrom + (1 - stage.blurFrom) * stage.ease(stage.clamp01(stage.enter / 0.5)))
        * (1 - stage.ease(stage.clamp01((stage.leave - 0.3) / 0.7)))

    NumberAnimation {
        id: enterAnim
        target: stage
        property: "enter"
        from: 0
        to: 1
        duration: Math.round(Tokens.motion.long / 0.7)
    }
    NumberAnimation {
        id: leaveAnim
        target: stage
        property: "leave"
        to: 1
        duration: Math.round(Tokens.motion.long / 0.7)
        onFinished: stage.exitFinished()
    }
    function start(): void {
        enterAnim.restart();
    }
    function exit(): void {
        if (leaveAnim.running || stage.leave >= 1) return;
        leaveAnim.restart();
    }
    // La entrada arranca al terminar la creacion: para entonces "reducir
    // movimiento" (un Binding del anfitrion) ya se aplico.
    Component.onCompleted: {
        Qt.callLater(stage.start);
        keys.forceActiveFocus();
    }

    // ---- Fondo -------------------------------------------------------------------------------
    LoginBackground {
        anchors.fill: parent
        amount: stage.blurAmount
    }

    // ---- Contenido ----------------------------------------------------------------------------
    readonly property int gap: Tokens.px(120)
    readonly property int cardWidth: Tokens.px(530)
    readonly property real left0: Math.round((width - clock.implicitWidth - stage.gap - stage.cardWidth) / 2)

    LoginClock {
        id: clock
        x: stage.left0
        anchors.verticalCenter: parent.verticalCenter
        date: stage.date
        opacity: stage.shown(0)
        transform: Translate { y: stage.rise(0) }
    }

    LoginTiles {
        id: tileColumn
        x: stage.left0 + clock.implicitWidth + stage.gap
        width: stage.cardWidth
        // Crecen hacia arriba desde la tarjeta; el salto de una fila se anima.
        y: card.y - Tokens.space.lg - height
        Behavior on y { NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
        items: stage.tiles
        title: stage.tilesTitle
        actionable: stage.tilesActionable
        opacity: stage.shown(1)
        transform: Translate { y: stage.rise(1) }
        onActivated: key => stage.tileActivated(key)
    }

    LoginCard {
        id: card
        x: stage.left0 + clock.implicitWidth + stage.gap
        y: Math.round(stage.height / 2) + Tokens.space.sm
        width: stage.cardWidth
        auth: stage.auth
        avatar: stage.avatar
        user: stage.user
        subtitle: stage.subtitle
        capsLock: stage.capsLock
        success: stage.success
        successText: stage.successText
        opacity: stage.shown(2)
        transform: Translate { y: stage.rise(2) }
    }

    // ---- Teclado -------------------------------------------------------------------------------
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            stage.keyPressed(event);
            if (stage.leaving) { event.accepted = true; return; }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) stage.auth.submit();
            else if (event.key === Qt.Key_Backspace) {
                if (event.modifiers & Qt.ControlModifier) stage.auth.clear();
                else stage.auth.erase();
            } else if (event.key === Qt.Key_Escape) stage.auth.clear();
            else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) stage.auth.type(event.text);
            event.accepted = true;
        }
    }
    function focusField(): void {
        keys.forceActiveFocus();
    }
}
