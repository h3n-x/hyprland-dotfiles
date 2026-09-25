// Menu de energia y sesion (Fase 4 B1, P4.2), SUPER+M. Panel en el monitor
// enfocado con cinco acciones: Bloquear (L), Suspender (S), Cerrar sesion (E),
// Reiniciar (R), Apagar (A). Flechas o Tab mueven, Enter o la letra activan,
// Esc o un clic afuera cierran.
//
// Las tres destructivas piden confirmacion (decision B1-b: tambien SUPER+
// SHIFT+M, que abre directo en "Cerrar la sesion"). En la confirmacion, Enter
// recien vale 400 ms despues de aparecer y se ignora la repeticion de tecla
// (B1-d): un doble Enter no reinicia por accidente. Esc vuelve al menu.
//
// Cerrar sesion, reiniciar y apagar pasan por hyprshutdown (B1-a): pide a las
// aplicaciones que se cierren antes de salir de Hyprland. El panel se cierra
// antes de ejecutar la accion (el bloqueo nunca queda debajo).
//
// POWER_MENU_DRY=1 (solo pruebas) registra el comando en vez de ejecutarlo.
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, PowerState.qml

OverlayWindow {
    id: window

    open: PowerState.visible
    targetScreen: PowerState.screen
    onDismissed: PowerState.close()

    readonly property var actions: [
        { id: "lock", icon: "lock", label: "Bloquear", key: "L" },
        { id: "suspend", icon: "bedtime", label: "Suspender", key: "S" },
        { id: "logout", icon: "logout", label: "Cerrar sesión", key: "E" },
        { id: "reboot", icon: "restart_alt", label: "Reiniciar", key: "R" },
        { id: "poweroff", icon: "power_settings_new", label: "Apagar", key: "A" }]
    readonly property var confirmText: ({
        logout: ["¿Cerrar la sesión?", "Las aplicaciones se cierran antes de salir de Hyprland.", "Cerrar sesión"],
        reboot: ["¿Reiniciar el equipo?", "Las aplicaciones se cierran antes de reiniciar.", "Reiniciar"],
        poweroff: ["¿Apagar el equipo?", "Las aplicaciones se cierran antes de apagar.", "Apagar"] })
    readonly property var commands: ({
        lock: [Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"],
        suspend: ["systemctl", "suspend"],
        logout: ["hyprshutdown", "-t", "Cerrando sesión..."],
        reboot: ["hyprshutdown", "-t", "Reiniciando...", "-p", "systemctl reboot"],
        poweroff: ["hyprshutdown", "-t", "Apagando...", "-p", "systemctl poweroff"] })

    readonly property bool dry: Quickshell.env("POWER_MENU_DRY") === "1"
    // Ultimo comando (modo de prueba).
    property var lastCommand: null

    property int sel: 0
    readonly property string confirming: PowerState.confirming
    readonly property var confirmAction: window.confirming ? window.actions.find(a => a.id === window.confirming) : null
    // Momento en que aparecio la confirmacion (guarda del doble Enter).
    property real confirmSince: 0
    onConfirmingChanged: window.confirmSince = Date.now()

    onShouldShowChanged: {
        if (!window.shouldShow) return;
        window.sel = 0;
        window.confirmSince = Date.now();
        keys.forceActiveFocus();
    }

    function activate(id: string): void {
        if (id === "logout" || id === "reboot" || id === "poweroff")
            PowerState.confirming = id;
        else
            window.run(id);
    }
    function confirm(): void {
        if (!window.confirming || Date.now() - window.confirmSince < 400) return;
        window.run(window.confirming);
    }
    // Cierra el panel y ejecuta al terminar la salida.
    function run(id: string): void {
        PowerState.close();
        pendingCommand = window.commands[id];
        runTimer.restart();
    }
    property var pendingCommand: null
    Timer {
        id: runTimer
        interval: Tokens.motion.exitFor(Tokens.motion.long) + 20
        onTriggered: {
            const cmd = window.pendingCommand;
            window.pendingCommand = null;
            if (!cmd) return;
            if (window.dry) {
                window.lastCommand = cmd;
                console.log("POWER_MENU_DRY " + JSON.stringify(cmd));
            } else {
                Quickshell.execDetached(cmd);
            }
        }
    }

    // Teclado. La logica esta en handleKey (la misma que usa cada tecla real).
    function handleKey(key: int, text: string, isAutoRepeat: bool): bool {
        // Solo con el panel abierto en esta pantalla.
        if (!window.shouldShow) return false;
        if (window.confirming) {
            if (key === Qt.Key_Return || key === Qt.Key_Enter) {
                if (!isAutoRepeat) window.confirm();
            } else if (key === Qt.Key_Escape) {
                PowerState.confirming = "";
            }
            return true;
        }
        if (key === Qt.Key_Left || key === Qt.Key_Backtab) {
            window.sel = (window.sel + window.actions.length - 1) % window.actions.length;
        } else if (key === Qt.Key_Right || key === Qt.Key_Tab) {
            window.sel = (window.sel + 1) % window.actions.length;
        } else if (key === Qt.Key_Return || key === Qt.Key_Enter) {
            if (!isAutoRepeat) window.activate(window.actions[window.sel].id);
        } else if (key === Qt.Key_Escape) {
            PowerState.close();
        } else {
            const a = window.actions.find(x => x.key === text.toUpperCase());
            if (!a) return false;
            window.activate(a.id);
        }
        return true;
    }
    Item {
        id: keys
        focus: true
        Keys.onPressed: (event) => {
            event.accepted = window.handleKey(event.key, event.text, event.isAutoRepeat);
        }
    }

    component KeyHint: Rectangle {
        id: hint
        property string text
        property color fg
        implicitWidth: hintText.implicitWidth + Tokens.space.sm * 2
        implicitHeight: hintText.implicitHeight + Tokens.space.hair * 2
        radius: Tokens.radius.sm
        color: "transparent"
        border.color: Qt.alpha(hint.fg, 0.4)
        Text {
            id: hintText
            anchors.centerIn: parent
            text: hint.text
            color: hint.fg
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
        }
    }

    // Nivel de elevacion 3, como el launcher.
    Surface {
        id: card
        anchors.centerIn: parent
        level: 3
        translucent: true
        radius: Tokens.radius.xl
        width: (window.confirming ? confirmCol.implicitWidth + Tokens.space.xl * 2 : tiles.implicitWidth + Tokens.space.lg * 2)
        height: (window.confirming ? confirmCol.implicitHeight + Tokens.space.xl * 2 : tiles.implicitHeight + Tokens.space.lg * 2)
        opacity: window.presence.progress
        scale: window.presence.contentScale

        // Sin esto, un clic en el borde de la tarjeta cerraria el panel.
        MouseArea { anchors.fill: parent }

        RowLayout {
            id: tiles
            visible: !window.confirming
            anchors.centerIn: parent
            spacing: Tokens.space.sm

            Repeater {
                model: window.actions
                Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool selected: tile.index === window.sel
                    implicitWidth: 112
                    implicitHeight: 116
                    radius: Tokens.radius.lg
                    color: tile.selected ? Colors.m3secondaryContainer : "transparent"
                    Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }

                    StateLayer {
                        hovered: tileMouse.containsMouse
                        pressed: tileMouse.pressed
                        contentColor: tile.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Tokens.space.sm
                        Icon {
                            Layout.alignment: Qt.AlignHCenter
                            name: tile.modelData.icon
                            size: Tokens.icon.xl
                            filled: tile.selected
                            color: tile.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: tile.modelData.label
                            color: tile.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurface
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: tile.selected ? Tokens.weight.semibold : Tokens.weight.medium
                        }
                        KeyHint {
                            Layout.alignment: Qt.AlignHCenter
                            text: tile.modelData.key
                            fg: tile.selected ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant
                        }
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: window.sel = tile.index
                        onClicked: window.activate(tile.modelData.id)
                    }
                }
            }
        }

        ColumnLayout {
            id: confirmCol
            visible: !!window.confirming
            anchors.centerIn: parent
            spacing: Tokens.space.md

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 56
                implicitHeight: 56
                radius: width / 2
                color: Colors.m3errorContainer
                Icon {
                    anchors.centerIn: parent
                    name: window.confirmAction ? window.confirmAction.icon : ""
                    size: Tokens.icon.lg
                    filled: true
                    color: Colors.m3onErrorContainer
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: window.confirming ? window.confirmText[window.confirming][0] : ""
                color: Colors.m3onSurface
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.title
                font.weight: Tokens.weight.semibold
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: window.confirming ? window.confirmText[window.confirming][1] : ""
                color: Colors.m3onSurfaceVariant
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.space.sm
                spacing: Tokens.space.sm

                // Cancelar: vuelve al menu.
                Rectangle {
                    implicitWidth: cancelRow.implicitWidth + Tokens.space.lg * 2
                    implicitHeight: Tokens.row.height
                    radius: Tokens.radius.pill(height)
                    color: "transparent"
                    border.color: Colors.m3outlineVariant
                    StateLayer { hovered: cancelMouse.containsMouse; pressed: cancelMouse.pressed }
                    Row {
                        id: cancelRow
                        anchors.centerIn: parent
                        spacing: Tokens.space.sm
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Cancelar"
                            color: Colors.m3onSurface
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                        }
                        KeyHint { anchors.verticalCenter: parent.verticalCenter; text: "Esc"; fg: Colors.m3onSurfaceVariant }
                    }
                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: PowerState.confirming = ""
                    }
                }
                // Confirmar, en el color de error de la paleta.
                Rectangle {
                    implicitWidth: okRow.implicitWidth + Tokens.space.lg * 2
                    implicitHeight: Tokens.row.height
                    radius: Tokens.radius.pill(height)
                    color: Colors.m3error
                    StateLayer { hovered: okMouse.containsMouse; pressed: okMouse.pressed; contentColor: Colors.m3onError }
                    Row {
                        id: okRow
                        anchors.centerIn: parent
                        spacing: Tokens.space.sm
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: window.confirmAction ? window.confirmAction.icon : ""
                            size: Tokens.icon.sm
                            color: Colors.m3onError
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: window.confirming ? window.confirmText[window.confirming][2] : ""
                            color: Colors.m3onError
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: Tokens.weight.semibold
                        }
                        KeyHint { anchors.verticalCenter: parent.verticalCenter; text: "Enter"; fg: Colors.m3onError }
                    }
                    MouseArea {
                        id: okMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.confirm()
                    }
                }
            }
        }
    }
}
