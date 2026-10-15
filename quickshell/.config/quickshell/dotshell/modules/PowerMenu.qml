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
        { id: "lock", icon: "lock", label: I18n.tr("Lock"), key: "L" },
        { id: "suspend", icon: "bedtime", label: I18n.tr("Suspend"), key: "S" },
        { id: "logout", icon: "logout", label: I18n.tr("Log out"), key: "E" },
        { id: "reboot", icon: "restart_alt", label: I18n.tr("Restart"), key: "R" },
        { id: "poweroff", icon: "power_settings_new", label: I18n.tr("Shut down"), key: "A" }]
    readonly property var confirmText: ({
        logout: [I18n.tr("Log out?"), I18n.tr("Applications are closed before leaving Hyprland."), I18n.tr("Log out")],
        reboot: [I18n.tr("Restart the computer?"), I18n.tr("Applications are closed before restarting."), I18n.tr("Restart")],
        poweroff: [I18n.tr("Shut down the computer?"), I18n.tr("Applications are closed before shutting down."), I18n.tr("Shut down")] })
    readonly property var commands: ({
        lock: [Quickshell.env("HOME") + "/.config/hypr/scripts/lock", "--user"],
        suspend: ["systemctl", "suspend"],
        logout: ["hyprshutdown", "-t", I18n.tr("Logging out...")],
        reboot: ["hyprshutdown", "-t", I18n.tr("Restarting..."), "-p", "systemctl reboot"],
        poweroff: ["hyprshutdown", "-t", I18n.tr("Shutting down..."), "-p", "systemctl poweroff"] })

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
        border.color: Colors.tint(hint.fg, Tokens.tint.hairline)
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
                    implicitWidth: Tokens.px(112)
                    implicitHeight: Tokens.px(116)
                    radius: Tokens.radius.lg
                    color: tile.selected ? Colors.accentAltContainer : "transparent"
                    Behavior on color { ColorAnimation { duration: Tokens.motion.fast } }

                    StateLayer {
                        hovered: tileMouse.containsMouse
                        pressed: tileMouse.pressed
                        contentColor: tile.selected ? Colors.textOnAccentAltContainer : Colors.text
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Tokens.space.sm
                        Icon {
                            Layout.alignment: Qt.AlignHCenter
                            name: tile.modelData.icon
                            size: Tokens.icon.xl
                            filled: tile.selected
                            color: tile.selected ? Colors.textOnAccentAltContainer : Colors.textMuted
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: tile.modelData.label
                            color: tile.selected ? Colors.textOnAccentAltContainer : Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: tile.selected ? Tokens.weight.semibold : Tokens.weight.medium
                        }
                        KeyHint {
                            Layout.alignment: Qt.AlignHCenter
                            text: tile.modelData.key
                            fg: tile.selected ? Colors.textOnAccentAltContainer : Colors.textMuted
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
                implicitWidth: Tokens.px(56)
                implicitHeight: Tokens.px(56)
                radius: width / 2
                color: Colors.dangerContainer
                Icon {
                    anchors.centerIn: parent
                    name: window.confirmAction ? window.confirmAction.icon : ""
                    size: Tokens.icon.lg
                    filled: true
                    color: Colors.textOnDangerContainer
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: window.confirming ? window.confirmText[window.confirming][0] : ""
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.title
                font.weight: Tokens.weight.semibold
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: window.confirming ? window.confirmText[window.confirming][1] : ""
                color: Colors.textMuted
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
                    border.color: Colors.divider
                    StateLayer { hovered: cancelMouse.containsMouse; pressed: cancelMouse.pressed }
                    Row {
                        id: cancelRow
                        anchors.centerIn: parent
                        spacing: Tokens.space.sm
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.tr("Cancel")
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                        }
                        KeyHint { anchors.verticalCenter: parent.verticalCenter; text: "Esc"; fg: Colors.textMuted }
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
                    color: Colors.danger
                    StateLayer { hovered: okMouse.containsMouse; pressed: okMouse.pressed; contentColor: Colors.textOnDanger }
                    Row {
                        id: okRow
                        anchors.centerIn: parent
                        spacing: Tokens.space.sm
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: window.confirmAction ? window.confirmAction.icon : ""
                            size: Tokens.icon.sm
                            color: Colors.textOnDanger
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: window.confirming ? window.confirmText[window.confirming][2] : ""
                            color: Colors.textOnDanger
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: Tokens.weight.semibold
                        }
                        KeyHint { anchors.verticalCenter: parent.verticalCenter; text: "Enter"; fg: Colors.textOnDanger }
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
