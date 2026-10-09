// Fondo de una vista del reproductor (Fase 12 B2; de MediaHero, P4 B7): la
// portada difuminada, cruzada con la portada (images = las dos capas de
// MediaCover), con un velo hacia el lado del texto para que se lea siempre.
// En una capa: el desenfoque se recalcula solo cuando cambia la portada o su
// cruce, no en cada cuadro.
import QtQuick
import QtQuick.Effects
import ".." // Colors.qml, Tokens.qml

Item {
    id: root
    property var images: []
    property real radius: Tokens.radius.md

    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: backdropMask
    }
    Rectangle {
        anchors.fill: parent
        color: Colors.surfaceHigh
    }
    Repeater {
        model: root.images
        MultiEffect {
            required property Image modelData
            anchors.fill: parent
            visible: modelData.status === Image.Ready
            source: modelData
            opacity: modelData.opacity * 0.75
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 0.1
            brightness: -0.2
        }
    }
    // Velo hacia la derecha: el texto siempre sobre una base legible.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Colors.tint(Colors.surfaceHigh, Tokens.opacity.scrimImage / 2) }
            GradientStop { position: 0.3; color: Colors.tint(Colors.surfaceHigh, Tokens.tint.overlay) }
            GradientStop { position: 1.0; color: Colors.tint(Colors.surfaceHigh, Tokens.tint.overlay) }
        }
    }
    Item {
        id: backdropMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: root.radius
        }
    }
}
