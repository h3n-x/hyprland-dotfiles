// Avatar elegido -> ~/.face (Fase 10 B2). Cuando cambia de donde sale el
// avatar (appearance.avatar, o la imagen con "Imagen propia"), sea quien sea
// el que lo cambio (el centro, `settings set`), rehace ~/.face con
// `theme-apply.sh --face`, que tambien agenda el pase del sistema (greeter y
// Plymouth). Si la imagen no sirve, ~/.face queda como estaba y avisa. Una
// instancia, en la shell (siempre corre); quieto no hace nada.
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string source: !SettingsState.ready ? ""
        : SettingsState.value("appearance.avatar") === "image" ? "image:" + (SettingsState.value("appearance.avatarImage") || "") : "wallpaper"
    // El primero que se ve (al arrancar) no es un cambio.
    property string seen: ""
    onSourceChanged: {
        if (!root.source) return;
        if (root.seen && root.seen !== root.source) face.running = true;
        root.seen = root.source;
    }

    property Process face: Process {
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/theme-apply.sh", "--face"]
        onExited: (code) => {
            if (code !== 0) Quickshell.execDetached(["notify-send", "-a", I18n.tr("Settings"), "-i", "dialog-warning",
                I18n.tr("Couldn't use the avatar image"), I18n.tr("The avatar is still the previous one. Choose another image in Appearance.")]);
        }
    }
}
