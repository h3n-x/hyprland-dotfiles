// Panel del reloj (Fase 4 B6: calendario + clima; B7 lo convierte en el
// dashboard). Abierto/cerrado y en que pantalla: lo escriben el reloj de la
// barra (clic) y el IpcHandler "dashboard"; ClockPanel.qml (uno por barra)
// lee de aca. Mismo patron que el hub de MediaState.
pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool visible: false
    property string screen: ""

    function open(screenName: string): void {
        if (screenName) {
            root.screen = screenName;
            root.visible = true;
            return;
        }
        FocusedScreen.request(name => {
            root.screen = name;
            root.visible = true;
        });
    }
    function close(): void {
        root.visible = false;
    }
    function toggle(screenName: string): void {
        if (root.visible && (!screenName || root.screen === screenName)) root.close();
        else root.open(screenName);
    }
}
