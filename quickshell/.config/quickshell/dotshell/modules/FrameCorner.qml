// Esquina de adentro del marco (Fase 13 B1): un cuarto de circulo concavo del
// color del marco, para que el borde de adentro sea redondo. Se dibuja la de
// arriba a la izquierda y se refleja para las otras (v, h). La misma forma
// sirve para las "orejas" de los paneles pegados al marco (B2).
import QtQuick
import QtQuick.Shapes
import ".." // Colors.qml

Item {
    id: c
    property string v: "top"      // "top" | "bottom": de que lado esta el borde horizontal
    property string h: "left"     // "left" | "right": de que lado esta el borde vertical
    property color color: Colors.surfaceLow

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            origin.x: c.width / 2
            origin.y: c.height / 2
            xScale: c.h === "right" ? -1 : 1
            yScale: c.v === "bottom" ? -1 : 1
        }
        ShapePath {
            strokeWidth: -1
            fillColor: c.color
            // La esquina, el borde de arriba y el arco hacia el borde izquierdo (centro en la esquina opuesta).
            startX: 0; startY: 0
            PathLine { x: c.width; y: 0 }
            PathArc { x: 0; y: c.height; radiusX: c.width; radiusY: c.height; direction: PathArc.Counterclockwise }
            PathLine { x: 0; y: 0 }
        }
    }
}
