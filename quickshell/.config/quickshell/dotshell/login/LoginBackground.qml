// Fondo del bloqueo y del greeter (Fase 9 B3): el wallpaper (nunca una copia
// del escritorio), difuminado y con el velo, segun `amount` (0 = nitido como el
// escritorio, 1 = difuminado). M1/M2 lo mueven en la entrada y la salida.
// En modo claro (P5.5) el texto es oscuro: el fondo se aclara en vez de oscurecerse
// (Colors.veil y el brillo con el signo del modo).
// QtQuick puro: lo usan el bloqueo (Quickshell) y el greeter (SDDM).
import QtQuick
import QtQuick.Effects
import ".." // Colors.qml, Tokens.qml

Item {
    id: bg
    property real amount: 1

    Rectangle {
        anchors.fill: parent
        color: Colors.background
    }
    Image {
        id: wallpaper
        anchors.fill: parent
        source: Colors.image ? "file://" + Colors.image : ""
        fillMode: Image.PreserveAspectCrop
        // Sincronica: el primer cuadro ya trae el fondo (V0-7c).
        asynchronous: false
        // El mismo tamano en todas las pantallas: una sola decodificacion compartida.
        sourceSize.width: 1920   // px-ok: decodificacion
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        blurEnabled: bg.amount > 0
        blur: 0.45 * bg.amount
        blurMax: 64
        brightness: (Colors.light ? 0.08 : -0.08) * bg.amount
    }
    Rectangle {
        anchors.fill: parent
        color: Colors.tint(Colors.veil, (Colors.light ? Tokens.opacity.veilLight : Tokens.opacity.scrim) * bg.amount)
    }
}
