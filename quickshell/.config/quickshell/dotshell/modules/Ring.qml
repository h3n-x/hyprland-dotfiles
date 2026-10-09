// Anillo de nivel (Fase 12 B3, estilo "Anillos" de Sistema, D-B3-2): un arco
// lleno hasta fraction y el resto tenue, separados por un hueco, con puntas
// redondas (como el progreso circular de Material 3). outer (0..1, NaN = no
// hay) dibuja un arco fino por fuera: la temperatura. Se desliza solo cuando
// el valor cambia (motion.medium); con movimiento reducido salta.
// El contenido (la cifra) va adentro, como hijos.
import QtQuick
import QtQuick.Shapes
import ".." // Colors.qml, Tokens.qml

Item {
    id: ring
    property real fraction: 0
    property real outer: NaN
    property color color: Colors.accent
    property color outerColor: Colors.accentAlt
    property int thickness: Tokens.space.sm
    implicitWidth: Tokens.px(96)
    implicitHeight: Tokens.px(96)

    property real shown: Math.max(0, Math.min(1, ring.fraction))
    Behavior on shown { enabled: Tokens.motion.scale > 0; NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
    property real outerShown: isNaN(ring.outer) ? 0 : Math.max(0, Math.min(1, ring.outer))
    Behavior on outerShown { enabled: Tokens.motion.scale > 0; NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }

    readonly property bool hasOuter: !isNaN(ring.outer)
    readonly property real outerWidth: Math.max(2, Math.round(ring.thickness / 3))
    // El anillo principal deja lugar al de afuera (su grosor y un hueco).
    readonly property real r: Math.min(ring.width, ring.height) / 2 - ring.thickness / 2
        - (ring.hasOuter ? ring.outerWidth + Tokens.space.xs : 0)
    readonly property real rOuter: Math.min(ring.width, ring.height) / 2 - ring.outerWidth / 2
    // Hueco entre lo lleno y lo vacio, en grados (el grosor y un poco mas).
    readonly property real gap: (ring.thickness * 1.5) / Math.max(1, ring.r) * 180 / Math.PI   // grados (px-ok)
    readonly property real filled: 360 * ring.shown

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        // Lo vacio.
        ShapePath {
            strokeWidth: ring.filled > 359 ? 0 : ring.thickness   // grados (px-ok)
            strokeColor: Colors.tint(Colors.textMuted, Tokens.tint.track)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2; centerY: ring.height / 2
                radiusX: ring.r; radiusY: ring.r
                startAngle: -90 + ring.filled + (ring.filled > 0 ? ring.gap : 0)
                sweepAngle: Math.max(0.01, 360 - ring.filled - (ring.filled > 0 ? 2 * ring.gap : 0))
            }
        }
        // Lo lleno.
        ShapePath {
            strokeWidth: ring.filled > 0.5 ? ring.thickness : 0
            strokeColor: ring.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2; centerY: ring.height / 2
                radiusX: ring.r; radiusY: ring.r
                startAngle: -90
                sweepAngle: Math.max(0.01, ring.filled)
            }
        }
        // Por fuera: la temperatura (fina).
        ShapePath {
            strokeWidth: ring.hasOuter ? ring.outerWidth : 0
            strokeColor: Colors.tint(Colors.textMuted, Tokens.tint.track)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2; centerY: ring.height / 2
                radiusX: ring.rOuter; radiusY: ring.rOuter
                startAngle: -90; sweepAngle: 359.9
            }
        }
        ShapePath {
            strokeWidth: ring.hasOuter && ring.outerShown > 0.005 ? ring.outerWidth : 0
            strokeColor: ring.outerColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2; centerY: ring.height / 2
                radiusX: ring.rOuter; radiusY: ring.rOuter
                startAngle: -90; sweepAngle: Math.max(0.01, 360 * ring.outerShown)
            }
        }
    }
}
