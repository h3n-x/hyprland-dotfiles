// Watcher de brillo -- sin UI propia (se saco el icono de la barra a
// pedido del usuario, ya esta el OSD). Instanciado sin pantalla directo en
// shell.qml: su unico trabajo es mirar /sys/class/backlight/*/brightness
// y disparar OsdState.show() en cada cambio, sea cual sea el origen (una
// tecla de brillo del teclado, brightnessctl a mano, etc.) -- no hay
// servicio nativo de backlight en Quickshell (a diferencia de audio/red/
// bluetooth/bateria), de ahi el FileView+watchChanges en vez de un
// servicio ya hecho. El nombre del device se resuelve una vez al arrancar
// (no se hardcodea "amdgpu_bl1": distinta GPU, distinto nombre).
import QtQuick
import Quickshell.Io
import ".." // OsdState.qml

Item {
    id: root

    readonly property int current: parseInt(brightnessFile.text()) || 0
    readonly property int max: parseInt(maxFile.text()) || 1
    readonly property real pct: root.current / root.max

    readonly property var icons: ["", "", "", "", "", "", "", "", ""]
    readonly property string icon: root.icons[Math.min(root.icons.length - 1, Math.floor(root.pct * root.icons.length))]

    property bool armed: false
    Component.onCompleted: Qt.callLater(() => root.armed = true)
    onPctChanged: {
        if (root.armed) OsdState.show(root.icon, root.pct, Math.round(root.pct * 100) + "%");
    }

    Process {
        id: findDevice
        command: ["sh", "-c", "ls /sys/class/backlight | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const name = this.text.trim();
                if (!name) return;
                brightnessFile.path = "/sys/class/backlight/" + name + "/brightness";
                maxFile.path = "/sys/class/backlight/" + name + "/max_brightness";
            }
        }
    }

    FileView {
        id: brightnessFile
        watchChanges: true
        onFileChanged: this.reload()
    }
    FileView {
        id: maxFile
    }
}
