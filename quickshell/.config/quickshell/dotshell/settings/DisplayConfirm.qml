// "¿Mantener esta configuración?" (Fase 10 B5): mientras hay una prueba de
// pantallas en curso ($XDG_RUNTIME_DIR/dotfiles/display-pending.json, la
// escribe scripts/settings-apply al guardar display.outputs), una franja en lo
// alto de la ventana con la cuenta atras, Mantener y Revertir. La cuenta la
// lleva un vigilante aparte (revierte aunque esta ventana no este o la
// pantalla quede negra); aca solo se muestra. Se mira al abrir y cada vez que
// display.outputs cambia (probar, mantener, revertir: todo pasa por el almacen);
// la ventana ve el valor nuevo antes de que el motor termine de probarlo, asi
// que tras un cambio se vuelve a mirar unas veces (300 ms, hasta 4,5 s).
import QtQuick
import Quickshell
import Quickshell.Io
import ".." // Colors.qml, Tokens.qml, SettingsState.qml
import "../modules"

Rectangle {
    id: bar

    readonly property string pendingPath: (Quickshell.env("SETTINGS_APPLY_RUN") || (Quickshell.env("XDG_RUNTIME_DIR") + "/dotfiles")) + "/display-pending.json"
    readonly property string applier: Quickshell.env("SETTINGS_APPLY_CMD") || (Quickshell.env("HOME") + "/.config/hypr/scripts/settings-apply")
    property var pending: null
    property int remaining: 0
    readonly property var outputs: SettingsState.value("display.outputs")
    // Solo tras un cambio escrito desde esta ventana (Aplicar, Automatica, Tus
    // cambios: queda pendiente en SettingsState) se vuelve a mirar unas veces;
    // al abrir o cuando el vigilante revierte, basta una.
    onOutputsChanged: {
        probe.left = SettingsState.pending.hasOwnProperty("display.outputs") ? 15 : 0;
        check.running = true;
    }
    Component.onCompleted: check.running = true

    function tick(): void {
        bar.remaining = bar.pending ? Math.max(0, Math.ceil(bar.pending.deadline - Date.now() / 1000)) : 0;
        // Vencida: el vigilante revierte y el almacen cambia; por si acaso, se vuelve a mirar.
        if (bar.pending && bar.remaining === 0) check.running = true;
    }

    visible: bar.pending !== null
    height: visible ? Tokens.row.heightLarge + Tokens.space.sm : 0
    radius: Tokens.radius.pill(height)
    color: Colors.warningContainer

    Process {
        id: check
        command: ["cat", bar.pendingPath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    bar.pending = JSON.parse(this.text);
                } catch (e) {
                    bar.pending = null;
                }
                bar.tick();
            }
        }
        onExited: (code) => {
            if (code !== 0) bar.pending = null;
            if (!bar.pending && probe.left > 0) probe.restart();
        }
    }
    Timer {
        id: probe
        property int left: 0
        interval: 300
        onTriggered: { probe.left--; check.running = true; }
    }
    Process {
        id: act
        onExited: { probe.left = 0; check.running = true; }
    }
    Timer {
        interval: 1000
        repeat: true
        running: bar.pending !== null
        onTriggered: bar.tick()
    }

    Row {
        x: Tokens.space.lg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.space.sm
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "monitor"
            size: Tokens.icon.sm
            color: Colors.textOnWarningContainer
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "¿Mantener esta configuración? Vuelve la anterior en " + bar.remaining + " s"
            color: Colors.textOnWarningContainer
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
            font.weight: Tokens.weight.medium
        }
    }
    Row {
        anchors.right: parent.right
        anchors.rightMargin: Tokens.space.sm
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.space.sm
        // Contorno en el color de la franja, como "Reiniciar la shell".
        Button {
            objectName: "display-revert"
            ink: Colors.textOnWarningContainer
            edge: Colors.textOnWarningContainer
            label: "Revertir"
            icon: "undo"
            onClicked: { act.command = [bar.applier, "display-revert"]; act.running = true; }
        }
        Button {
            objectName: "display-keep"
            label: "Mantener"
            icon: "check"
            ink: Colors.textOnWarningContainer
            edge: Colors.textOnWarningContainer
            onClicked: { act.command = [bar.applier, "display-keep"]; act.running = true; }
        }
    }
}
