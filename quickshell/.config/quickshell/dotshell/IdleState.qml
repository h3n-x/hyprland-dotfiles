// "Mantener despierto" (Fase 11 B6): un solo estado para todas las pantallas,
// el modulo de la barra (IdleToggle) y el ajuste rapido del centro de
// control. La ventana que lo cumple es IdleInhibit (shell.qml), la misma de
// "no entrar en reposo mientras suena algo". Antes cada barra tenia su propio
// inhibidor (dos pantallas = dos estados distintos).
pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool active: false
    function toggle(): void {
        root.active = !root.active;
    }
}
