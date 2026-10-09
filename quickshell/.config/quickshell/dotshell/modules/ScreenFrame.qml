// Marco alrededor de la pantalla (Fase 13 B1, D-P13-1..3; bar.style "marco"):
// la barra es su lado grueso y estos son los otros tres, Tokens.frame.thickness
// de grosor, en el mismo color que la barra solida. Las cuatro esquinas de
// adentro son redondas (Tokens.frame.radius), tambien las dos donde la barra se
// junta con el marco.
//
// Ventanas por pantalla (no una ventana a pantalla completa):
// - un trozo por lado, sin recibir clics (mascara vacia) y sin reservar nada:
//   los lados "largos" (los de la barra y su opuesto) de punta a punta, los
//   "cortos" entre ellos, asi nada se superpone;
// - una ventana de 1 px por lado que reserva el grosor (exclusiveZone), asi las
//   ventanas quedan adentro del marco con los gaps de siempre; tambien la del
//   lado de la barra, con su grosor: la barra no reserva (Bar.qml), asi nada
//   la corre de lugar;
// - cuatro esquinas: un cuarto de circulo concavo en cada esquina de adentro.
// Con la barra oculta (Super+Mayus+B, o mientras no asoma con bar.peek), su
// lado tambien es un lado fino y el anillo sigue cerrado. Sobre una ventana a
// pantalla completa Hyprland no muestra la capa Top: el marco se va con la barra.
// Quieto: nada anima ni consulta; se redibuja solo si cambian el tema, el borde
// o los tamanos.
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import ".." // Colors.qml, Tokens.qml, BarVisibility.qml, SettingsState.qml

Scope {
    id: frame
    required property var screen

    readonly property bool active: Tokens.frame.on && BarVisibility.onScreen(frame.screen)
    readonly property string edge: Tokens.bar.edge
    readonly property bool horizontal: !Tokens.bar.vertical
    // La barra se ve (asoma con peek solo mientras se mantiene Super: entonces cuenta como oculta).
    readonly property bool barShown: BarVisibility.barSeen
    readonly property int t: Tokens.frame.thickness
    readonly property int r: Tokens.frame.radius
    readonly property color fill: Colors.surfaceLow

    // Grosor de cada lado (BarVisibility.edgeSize: el mismo que usan los paneles pegados).
    function th(side: string): int {
        return BarVisibility.edgeSize(side);
    }
    // Lados largos: los de la barra y su opuesto (de punta a punta).
    function isLong(side: string): bool {
        return frame.horizontal ? (side === "top" || side === "bottom") : (side === "left" || side === "right");
    }

    // ---- Un lado fino --------------------------------------------------------------
    component Side: PanelWindow {
        id: side
        required property string where
        screen: frame.screen
        visible: frame.active && !(side.where === frame.edge && frame.barShown)
        WlrLayershell.namespace: "quickshell-frame"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        color: "transparent"
        anchors {
            top: side.where !== "bottom"
            bottom: side.where !== "top"
            left: side.where !== "right"
            right: side.where !== "left"
        }
        readonly property bool vert: side.where === "left" || side.where === "right"
        implicitWidth: side.vert ? frame.t : 0
        implicitHeight: side.vert ? 0 : frame.t
        // Los cortos van entre los largos.
        margins {
            top: side.vert && !frame.isLong(side.where) ? frame.th("top") : 0
            bottom: side.vert && !frame.isLong(side.where) ? frame.th("bottom") : 0
            left: !side.vert && !frame.isLong(side.where) ? frame.th("left") : 0
            right: !side.vert && !frame.isLong(side.where) ? frame.th("right") : 0
        }
        Rectangle {
            anchors.fill: parent
            color: frame.fill
        }
    }
    // ---- La reserva de un lado (1 px, invisible) -------------------------------------
    component Reserve: PanelWindow {
        id: res
        required property string where
        screen: frame.screen
        visible: frame.active
        WlrLayershell.namespace: "quickshell-frame-zone"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: frame.th(res.where)
        mask: Region {}
        color: "transparent"
        anchors {
            top: res.where === "top"
            bottom: res.where === "bottom"
            left: res.where === "left"
            right: res.where === "right"
        }
        implicitWidth: 1
        implicitHeight: 1
    }
    // ---- Una esquina de adentro -------------------------------------------------------
    component Corner: PanelWindow {
        id: corner
        required property string v      // "top" | "bottom"
        required property string h      // "left" | "right"
        screen: frame.screen
        visible: frame.active && frame.r > 0
        WlrLayershell.namespace: "quickshell-frame"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        color: "transparent"
        anchors {
            top: corner.v === "top"
            bottom: corner.v === "bottom"
            left: corner.h === "left"
            right: corner.h === "right"
        }
        margins {
            top: corner.v === "top" ? frame.th("top") : 0
            bottom: corner.v === "bottom" ? frame.th("bottom") : 0
            left: corner.h === "left" ? frame.th("left") : 0
            right: corner.h === "right" ? frame.th("right") : 0
        }
        implicitWidth: frame.r
        implicitHeight: frame.r
        FrameCorner {
            anchors.fill: parent
            v: corner.v
            h: corner.h
            color: frame.fill
        }
    }

    Side { where: "top" }
    Side { where: "bottom" }
    Side { where: "left" }
    Side { where: "right" }
    Reserve { where: "top" }
    Reserve { where: "bottom" }
    Reserve { where: "left" }
    Reserve { where: "right" }
    Corner { v: "top"; h: "left" }
    Corner { v: "top"; h: "right" }
    Corner { v: "bottom"; h: "left" }
    Corner { v: "bottom"; h: "right" }
}
