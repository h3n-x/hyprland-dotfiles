// Estado de aparicion/desaparicion de una superficie (P2.5-P2.7; guia de
// transiciones en DESIGN_TOKENS.md 3.6.1). Mantiene la ventana mapeada
// mientras su contenido anima la salida -- sin esto la superficie de
// layer-shell se desmapea al instante y no hay salida que animar.
//
//   Presence { id: presence; open: ControlCenterState.visible }
//   PanelWindow { visible: presence.shown
//       Surface { opacity: presence.progress; scale: presence.contentScale
//                 transform: Translate { y: presence.offsetY }
//                 transformOrigin: Item.TopRight } }
//
// Interrumpible: al invertir a mitad de camino parte del valor actual y la
// duracion se acorta en proporcion a lo que falta. Con movimiento reducido
// (Tokens.motion.scale 0) las duraciones son 0: aparece y desaparece al instante.
import QtQuick
import ".." // Tokens.qml

Item {
    id: root
    property bool open: false
    // Entrada: dur.medium para paneles, dur.short para el OSD, dur.long para
    // el launcher. La salida dura exitFor() de la entrada.
    property int enterDuration: Tokens.motion.medium
    readonly property int exitDuration: Tokens.motion.exitFor(root.enterDuration)
    // false en superficies sin anclaje (launcher centrado): sin desplazamiento.
    property bool slide: true

    // 0 = cerrada, 1 = abierta. Solo la escribe la animacion.
    property real progress: 0
    // Ligar el visible de la ventana a esto, no a open.
    readonly property bool shown: root.open || root.progress > 0

    // Transformacion del contenido (guia 3.6.1): sube space.sm hacia su
    // anclaje y crece desde 0.98.
    readonly property real offsetY: root.slide ? (1 - root.progress) * Tokens.space.sm : 0
    readonly property real contentScale: 0.98 + 0.02 * root.progress

    // Cierre sin animacion: para cuando la ventana ya se cerro por fuera (un
    // popup con grabFocus que Quickshell cierra al clickear afuera; Hyprland
    // ya funde el popup al desmapearlo).
    function snapClosed() {
        root._snapping = true;
        anim.stop();
        root.open = false;
        root.progress = 0;
        root._snapping = false;
    }

    property bool _snapping: false

    function run() {
        anim.stop();
        const target = root.open ? 1 : 0;
        const full = root.open ? root.enterDuration : root.exitDuration;
        anim.to = target;
        anim.duration = Math.round(full * Math.abs(target - root.progress));
        anim.easing.bezierCurve = root.open ? Tokens.motion.easeEnter : Tokens.motion.easeExit;
        anim.start();
    }

    onOpenChanged: if (!root._snapping) root.run()
    Component.onCompleted: if (root.open) root.run()

    NumberAnimation {
        id: anim
        target: root
        property: "progress"
        easing.type: Easing.BezierSpline
    }
}
