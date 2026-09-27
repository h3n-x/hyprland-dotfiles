// Miniatura de una captura o grabacion (Fase 4 B8): la imagen como una
// ventana en Escritorios (radio md, borde fino) sobre un fondo tenue, el tipo
// en una etiqueta y, en videos, reproducir y la duracion. La usa la vista
// previa (CapturePreview.qml) y la puede usar un historial futuro: solo
// necesita la ruta.
//
// Una captura se ajusta entera dentro del recuadro (se ve lo que se capturo);
// un video lo llena (su miniatura sale de ffmpeg, ver scripts/record).
import QtQuick
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml, CaptureState.qml

Item {
    id: thumb
    property string path: ""
    property string kind: "region"     // region | window | full | recording
    property int duration: 0           // ms, videos
    property bool badge: true
    // false: la imagen no se dibuja (mientras vuela la de la vista previa).
    property bool imageVisible: true

    readonly property bool video: thumb.kind === "recording"
    readonly property string source: thumb.path === "" ? "" : "file://" + (thumb.video ? CaptureState.thumbFor(thumb.path) : thumb.path)
    readonly property bool ready: img.status === Image.Ready
    readonly property size imageSize: Qt.size(img.implicitWidth, img.implicitHeight)
    // Rectangulo donde se dibuja la imagen, en coordenadas de la miniatura.
    readonly property rect imageRect: {
        const inset = thumb.video ? 0 : Tokens.space.sm;
        const bw = thumb.width - 2 * inset, bh = thumb.height - 2 * inset;
        if (thumb.video || !thumb.ready || img.implicitWidth <= 0 || img.implicitHeight <= 0)
            return Qt.rect(inset, inset, bw, bh);
        const k = Math.min(bw / img.implicitWidth, bh / img.implicitHeight, 1);
        const w = Math.round(img.implicitWidth * k), h = Math.round(img.implicitHeight * k);
        return Qt.rect(Math.round((thumb.width - w) / 2), Math.round((thumb.height - h) / 2), w, h);
    }
    readonly property int imageRadius: thumb.video ? Tokens.radius.md : Tokens.radius.sm

    readonly property var kinds: ({
        region: { icon: "crop", label: "Región" },
        window: { icon: "web_asset", label: "Ventana" },
        full: { icon: "desktop_windows", label: "Pantalla" },
        recording: { icon: "videocam", label: "Grabación" }
    })

    function clock(ms: int): string {
        const s = Math.round(ms / 1000);
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radius.md
        color: Colors.tint(Colors.surfaceHighest, Tokens.tint.well)
    }

    ClippingRectangle {
        x: thumb.imageRect.x
        y: thumb.imageRect.y
        width: thumb.imageRect.width
        height: thumb.imageRect.height
        radius: thumb.imageRadius
        color: "transparent"
        visible: thumb.imageVisible && thumb.ready

        // Se decodifica una vez (cache compartida con la imagen que vuela).
        Image {
            id: img
            anchors.fill: parent
            source: thumb.source
            asynchronous: true
            fillMode: thumb.video ? Image.PreserveAspectCrop : Image.Stretch
            smooth: true
            mipmap: true
        }
    }
    Rectangle {
        x: thumb.imageRect.x
        y: thumb.imageRect.y
        width: thumb.imageRect.width
        height: thumb.imageRect.height
        radius: thumb.imageRadius
        color: "transparent"
        border.width: 1
        border.color: Colors.divider
        visible: thumb.imageVisible && thumb.ready
    }

    // Tipo
    Rectangle {
        visible: thumb.badge && !!thumb.kinds[thumb.kind]
        x: Tokens.space.sm
        y: Tokens.space.sm
        height: 24
        width: kindRow.implicitWidth + Tokens.space.lg
        radius: Tokens.radius.pill(height)
        color: Colors.tint(Colors.surfaceHighest, Tokens.tint.overlay)

        Row {
            id: kindRow
            anchors.centerIn: parent
            spacing: Tokens.space.xs
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: thumb.kinds[thumb.kind] ? thumb.kinds[thumb.kind].icon : ""
                size: Tokens.icon.sm - 2
                color: Colors.accent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: thumb.kinds[thumb.kind] ? thumb.kinds[thumb.kind].label : ""
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                font.weight: Tokens.weight.medium
            }
        }
    }

    // Video: reproducir y duracion
    Rectangle {
        visible: thumb.video
        anchors.centerIn: parent
        width: 52
        height: 52
        radius: 26
        color: Colors.tint(Colors.surfaceHighest, Tokens.tint.overlay)
        Icon {
            anchors.centerIn: parent
            name: "play_arrow"
            filled: true
            size: 30
        }
    }
    Rectangle {
        visible: thumb.video && thumb.duration > 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.space.sm
        height: 22
        width: durText.implicitWidth + 14
        radius: Tokens.radius.pill(height)
        color: Colors.tint(Colors.surfaceHighest, Tokens.tint.overlay)
        Text {
            id: durText
            anchors.centerIn: parent
            text: thumb.clock(thumb.duration)
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
            font.weight: Tokens.weight.semibold
            font.features: Tokens.tabularNumbers
        }
    }
}
