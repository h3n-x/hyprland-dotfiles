// Vuelve a existir con icono propio en la barra (se habia sacado por
// duplicar el de la bandeja -- ver Tray.qml, que ahora filtra "nm-applet"
// a proposito). Razon real esta vez: abrir NetworkDropdown.qml, un panel
// propio en QML en vez de mandar a un menu fzf en una terminal.
// Dispositivos, red activa e icono: NetworkState (compartido con el
// dashboard, Fase 4 B7).
import QtQuick
import Quickshell
import ".." // Colors.qml, NetworkState.qml

Item {
    id: root
    // Oculto desde el centro de configuracion (bar.show.network, Fase 10 B4).
    // Si se muestra, segun su propio estado y la opcion bar.show.* (Fase 10 B4).
    // La barra lee shown, no visible: visible depende del padre y una pill
    // oculta nunca volveria a mostrarse.
    readonly property bool shown: SettingsState.value("bar.show.network") !== false
    visible: shown
    required property var panelWindow

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Icon {
        id: label
        name: NetworkState.icon
        // Relleno = conectado (regla on/off de D10).
        filled: NetworkState.connected
    }

    NetworkDropdown {
        id: dropdown
        anchorItem: root
        panelWindow: root.panelWindow
    }

    // Hover por control (P2.4, Q2 = A).
    HoverHalo { hovered: hoverArea.containsMouse; pressed: hoverArea.pressed }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: dropdown.toggle()
    }
}
