// "No entrar en reposo mientras suena algo" (Fase 10 B3, power.inhibitWhileMedia):
// mientras la opcion esta encendida y algo suena (MediaState), una ventana de
// 1x1 transparente y sin entrada pide al compositor que no cuente inactividad
// (IdleInhibitor, protocolo idle-inhibit; hypridle lo respeta). Existe solo en
// ese momento. Si la shell se cae, la ventana se va con ella y la inactividad
// vuelve a contar: nunca queda inhibido de mas.
import QtQuick
import Quickshell
import Quickshell.Wayland

LazyLoader {
    active: SettingsState.value("power.inhibitWhileMedia") === true
        && !!MediaState.active && MediaState.active.isPlaying

    PanelWindow {
        id: win
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell-idle-inhibit"
        // Sin entrada: los clics atraviesan.
        mask: Region {}
        IdleInhibitor {
            window: win
            enabled: true
        }
    }
}
