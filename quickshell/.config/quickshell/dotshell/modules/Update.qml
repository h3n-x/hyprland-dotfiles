// Pill de actualizaciones: la barra informa (Fase 4 B9). Icono del ultimo
// chequeo de MaintenanceState (el mismo del dashboard): actualizaciones, al
// dia, error o reinicio pendiente. Clic: actualizar en una terminal visible;
// clic derecho: revisar ya.
import QtQuick
import Quickshell
import ".." // Colors.qml, Tokens.qml, MaintenanceState.qml

Item {
    id: root
    // Oculto desde el centro de configuracion (bar.show.updates, Fase 10 B4).
    // Si se muestra, segun su propio estado y la opcion bar.show.* (Fase 10 B4).
    // La barra lee shown, no visible: visible depende del padre y una pill
    // oculta nunca volveria a mostrarse.
    readonly property bool shown: SettingsState.value("bar.show.updates") !== false
    visible: shown

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Icon {
        id: label
        name: MaintenanceState.pillIcon
        filled: MaintenanceState.pillIcon === "download" || MaintenanceState.pillIcon === "restart_alt"
    }

    // Hover por control (P2.4, Q2 = A).
    HoverHalo { hovered: hoverArea.containsMouse; pressed: hoverArea.pressed }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) MaintenanceState.refresh(true);
            else MaintenanceState.act("update", "", "");
        }
    }
}
