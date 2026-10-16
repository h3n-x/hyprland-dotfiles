// Tarjeta elevada de las superficies flotantes (P2.1-P2.3; decisiones D5, D6,
// E1-E3): color de superficie segun el nivel, borde sutil, translucidez y la
// sombra neutra de Tokens. Profundidad discreta, no efecto cristal.
//
// La ventana que la contiene reserva shadowMargin alrededor para que la sombra
// no se recorte, y enmascara la entrada a la tarjeta (mask) para que ese margen
// transparente no se coma los clicks.
//
//   Surface { level: 3; radius: Tokens.radius.lg; translucent: true }
import QtQuick
import QtQuick.Effects
import ".." // Colors.qml, Tokens.qml

Rectangle {
    id: root
    // 2 = desplegables y centro de control, 3 = toasts, OSD y launcher (el
    // nivel 1 es la barra, que no usa Surface: sin blur ni sombra, E3).
    property int level: 2
    // Solo con blur del compositor detras (P2.3): translucida sin blur se ve
    // peor que opaca (el contenido de atras se cuela como ruido, P1.6).
    property bool translucent: false
    property bool shadowEnabled: true
    // Pegada al marco (Fase 13 B2): del color del marco, opaca, sin borde ni
    // sombra, asi tarjeta y marco se ven como una sola forma.
    property bool framed: false

    readonly property var shadowSpec: Tokens.elevationShadow[root.level] ?? null
    // Alcance de la sombra fuera de la tarjeta: desenfoque + desplazamiento.
    readonly property int shadowMargin: root.shadowEnabled && !root.framed && root.shadowSpec ? root.shadowSpec.blur + root.shadowSpec.offsetY : 0
    readonly property color baseColor: root.level >= 3 ? Colors.surfaceHigh : Colors.surface

    color: root.framed ? Colors.frame : root.translucent ? Colors.tint(root.baseColor, Tokens.opacity.surface) : root.baseColor
    border.color: Colors.divider
    border.width: root.framed ? 0 : 1

    // MultiEffect: shadowBlur es relativo a blurMax, de ahi blur / 32.
    layer.enabled: root.shadowEnabled && !root.framed && !!root.shadowSpec
    layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: 32
        shadowBlur: root.shadowSpec ? root.shadowSpec.blur / 32 : 0
        shadowVerticalOffset: root.shadowSpec ? root.shadowSpec.offsetY : 0
        shadowOpacity: root.shadowSpec ? root.shadowSpec.opacity : 0
        shadowColor: Colors.shadow
    }
}
