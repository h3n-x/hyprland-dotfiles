// La unica ventana que pide no contar inactividad (Fase 10 B3; desde la
// Fase 11 B6 para las dos razones): "no entrar en reposo mientras suena algo"
// (power.inhibitWhileMedia y algo sonando, MediaState) y "mantener despierto"
// (IdleState: el modulo de la barra y el ajuste rapido). Una ventana de 1x1
// transparente y sin entrada con IdleInhibitor (protocolo idle-inhibit;
// hypridle lo respeta); existe solo mientras alguna razon vale. Si la shell
// se cae, la ventana se va con ella: nunca queda inhibido de mas.
import QtQuick
import Quickshell
import Quickshell.Wayland

LazyLoader {
    active: IdleState.active
        || (SettingsState.value("power.inhibitWhileMedia") === true && !!MediaState.active && MediaState.active.isPlaying)

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
