// Avatar (Fase 11 B5): ~/.face en un circulo, releido cuando cambia (lo rehace
// theme-apply.sh: del fondo o la imagen propia, Fase 10 B2). Lo usan la
// tarjeta del avatar en Configuracion y la zona Perfil de Inicio. Sin imagen
// legible, un icono de persona.
//
//   Avatar { size: 56 }
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml

ClippingRectangle {
    id: root
    property int size: 72
    readonly property string face: Quickshell.env("HOME") + "/.face"
    property int rev: 0

    implicitWidth: root.size
    implicitHeight: root.size
    radius: width / 2
    color: Colors.surfaceHigh

    // Solo se vigila: el archivo cambia cuando theme-apply.sh lo rehace.
    FileView {
        path: root.face
        preload: false
        watchChanges: true
        printErrors: false
        onFileChanged: root.rev++
    }
    Icon {
        anchors.centerIn: parent
        visible: img.status !== Image.Ready
        name: "person"
        size: Math.round(root.size * 0.5)
        color: Colors.textMuted
    }
    Image {
        id: img
        anchors.fill: parent
        source: "file://" + root.face + "?v=" + root.rev
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.size * 2
        cache: false
        asynchronous: true
    }
}
