// Portada de una vista del reproductor (Fase 12 B2; de MediaHero, P4 B5):
// dos imagenes que se cruzan cuando la nueva ya cargo (nunca un hueco en
// blanco), recortadas con la forma elegida (CoverShape, media.cover.shape),
// un borde fino para que una portada muy oscura no se pierda y, si halo, la
// misma portada difuminada detras. Con cada cambio de cancion la forma gira
// un paso (una animacion; nunca continuo).
//
// images: las dos capas, para el fondo difuminado de la vista (MediaBackdrop).
import QtQuick
import QtQuick.Effects
import ".." // Colors.qml, Tokens.qml, SettingsState.qml

Item {
    id: cover
    property MediaSession session
    property bool halo: true
    property string shape: SettingsState.value("media.cover.shape") || "rounded"
    property int size: Tokens.cover.music
    implicitWidth: cover.size
    implicitHeight: cover.size
    scale: cover.session ? cover.session.coverScale : 1
    transformOrigin: Item.Center

    readonly property var images: [artA, artB]
    property bool frontIsA: true
    readonly property Image front: cover.frontIsA ? artA : artB
    readonly property Image back: cover.frontIsA ? artB : artA
    readonly property bool hasArt: cover.front.status === Image.Ready && cover.front.opacity > 0
    // La forma, para quien dibuja alrededor (B3).
    readonly property alias outline: mask

    readonly property string url: cover.session ? cover.session.art : ""
    onUrlChanged: cover.show(cover.url)
    Component.onCompleted: cover.show(cover.url)

    function show(url: string): void {
        if (url === cover.front.source.toString() && cover.front.status === Image.Ready) return;
        if (!url) {
            fade.stop();
            cover.front.opacity = 0;
            cover.back.opacity = 0;
            cover.back.source = "";
            return;
        }
        cover.back.opacity = 0;
        cover.back.source = url;
    }
    function backReady(): void {
        fade.stop();
        fade.target = cover.back;
        fadeOld.target = cover.front;
        cover.frontIsA = !cover.frontIsA; // la nueva pasa adelante
        fade.restart();
        fadeOld.restart();
    }
    NumberAnimation { id: fade; property: "opacity"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
    NumberAnimation { id: fadeOld; property: "opacity"; to: 0; duration: Tokens.motion.medium }

    // Un paso de giro por cancion (formas onduladas; el cuadrado y el circulo no cambian).
    readonly property int changes: cover.session ? cover.session.changes : 0
    property real turn: 0
    onChangesChanged: {
        turnAnim.to = cover.turn + 360 / 18;
        turnAnim.restart();
    }
    NumberAnimation { id: turnAnim; target: cover; property: "turn"; duration: Tokens.motion.long; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEmphasized }

    // Halo: la portada del frente difuminada (se recalcula solo al cambiar).
    MultiEffect {
        visible: cover.halo && cover.hasArt
        anchors.centerIn: parent
        width: parent.width * 1.2
        height: parent.height * 1.2
        source: cover.front
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: 0.2
        // Tope para portadas muy claras: un halo, no un foco.
        brightness: -0.1
        opacity: 0.5
    }

    // Recorte con la forma: capa con mascara, recalculada solo cuando cambia
    // la portada, su cruce o el giro.
    Rectangle {
        anchors.fill: parent
        color: Colors.surfaceHighest
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskLayer
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        Icon {
            anchors.centerIn: parent
            visible: !cover.hasArt
            name: "music_note"
            size: cover.size >= Tokens.px(120) ? Tokens.icon.xl : Tokens.icon.md
            color: Colors.textMuted
        }
        Image {
            id: artA
            anchors.fill: parent
            opacity: 0
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(cover.size * 2, cover.size * 2)
            asynchronous: true
            onStatusChanged: if (artA.status === Image.Ready && cover.back === artA) cover.backReady()
        }
        Image {
            id: artB
            anchors.fill: parent
            opacity: 0
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(cover.size * 2, cover.size * 2)
            asynchronous: true
            onStatusChanged: if (artB.status === Image.Ready && cover.back === artB) cover.backReady()
        }
    }
    Item {
        id: maskLayer
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.samples: 4
        CoverShape {
            id: mask
            anchors.fill: parent
            kind: cover.shape
            turn: cover.turn
        }
    }
    // Borde fino con la misma forma.
    CoverShape {
        anchors.fill: parent
        kind: cover.shape
        turn: cover.turn
        fill: "transparent"
        stroke: Colors.divider
    }
}
