// Zona Temporizador de Inicio (Fase 11 B5b, P11.6): pomodoro, cronometro y
// cuenta atras (TimerState, un solo dueno). Arriba el modo; al centro la hora
// grande y la fase; abajo empezar/pausar, reiniciar y lo propio de cada modo
// (saltar fase, vuelta, minutos de la cuenta atras). El modo: control
// segmentado en la ancha, tres iconos en la compacta. Mientras se ve, la hora
// avanza cada segundo (Demand seconds); cerrada no hace tic.
//
// Teclado: Enter sobre la zona elegida con Tab = empezar / pausar (focusField).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, TimerState.qml

ColumnLayout {
    id: root
    property bool active: false
    property bool wide: false
    readonly property real ideal: root.implicitHeight
    spacing: Tokens.space.sm

    Subscription { demand: TimerState.seconds; active: root.active }

    // Enter (desde el anillo de Inicio): empezar o pausar el modo elegido.
    function focusField(): void {
        TimerState.toggle();
    }

    readonly property string mode: TimerState.mode
    readonly property bool running: root.mode === "stopwatch" ? TimerState.stopwatch.running
        : root.mode === "countdown" ? TimerState.countdown.running : TimerState.pomodoro.running
    readonly property real shownMs: root.mode === "stopwatch" ? TimerState.stopwatchElapsed
        : root.mode === "countdown" ? TimerState.countdownLeft : TimerState.pomodoroLeft
    readonly property string sub: {
        if (root.mode === "stopwatch") {
            const n = (TimerState.stopwatch.laps || []).length;
            return n ? I18n.trn("%n lap · last %1", "%n laps · last %1", n, TimerState.format(TimerState.stopwatch.laps[0])) : I18n.tr("Stopwatch");
        }
        if (root.mode === "countdown") return TimerState.countdownIdle ? I18n.tr("Choose how long") : I18n.tr("of %1", TimerState.short(TimerState.countdown.total));
        // Concentracion: la que va; descanso: la que termino.
        const c = TimerState.pomodoro.cycle || 0;
        const n = TimerState.pomodoro.phase === "focus" ? c % TimerState.cycles + 1 : (Math.max(1, c) - 1) % TimerState.cycles + 1;
        return TimerState.phaseLabel + " · " + I18n.tr("%1 of %2", n, TimerState.cycles);
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space.sm
        ZoneTitle {
            Layout.fillWidth: true
            text: I18n.tr("Timer")
        }
        // Ancha: el control segmentado; compacta (272 px) no entra: iconos.
        Segmented {
            visible: root.wide
            options: [["pomodoro", I18n.tr("Pomodoro")], ["stopwatch", I18n.tr("Stopwatch")], ["countdown", I18n.tr("Countdown")]]
            current: root.mode
            onChosen: (v) => TimerState.setMode(v)
        }
        Row {
            visible: !root.wide
            spacing: Tokens.space.xs
            Repeater {
                model: [["pomodoro", "timer"], ["stopwatch", "av_timer"], ["countdown", "hourglass_top"]]
                Rectangle {
                    id: modeBtn
                    required property var modelData
                    readonly property bool sel: root.mode === modeBtn.modelData[0]
                    width: Tokens.control.sm
                    height: Tokens.control.sm
                    radius: width / 2
                    color: modeBtn.sel ? Colors.accentAltContainer : "transparent"
                    StateLayer { radius: parent.radius; hovered: modeMouse.containsMouse; pressed: modeMouse.pressed }
                    Icon {
                        anchors.centerIn: parent
                        name: modeBtn.modelData[1]
                        size: Tokens.icon.sm
                        color: modeBtn.sel ? Colors.textOnAccentAltContainer : Colors.textMuted
                    }
                    MouseArea {
                        id: modeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TimerState.setMode(modeBtn.modelData[0])
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Text {
            text: TimerState.format(root.shownMs)
            color: root.running ? Colors.text : Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.displayLarge
            font.weight: Tokens.weight.semibold
            font.features: Tokens.tabularNumbers
        }
        Text {
            Layout.fillWidth: true
            text: root.sub
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
            elide: Text.ElideRight
        }
    }
    LevelBar {
        Layout.fillWidth: true
        visible: root.mode !== "stopwatch"
        fraction: root.mode === "countdown" ? TimerState.countdownFraction : TimerState.pomodoroFraction
    }
    Flow {
        Layout.fillWidth: true
        spacing: Tokens.space.xs
        Button {
            label: root.running ? I18n.tr("Pause") : I18n.tr("Start")
            icon: root.running ? "pause" : "play_arrow"
            main: true
            onClicked: TimerState.toggle()
        }
        Button {
            // Compacta: solo el icono (que entren en una linea).
            label: root.wide ? I18n.trc("timer", "Reset") : ""
            icon: "restart_alt"
            onClicked: TimerState.reset()
        }
        Button {
            visible: root.mode === "pomodoro"
            label: root.wide ? I18n.tr("Skip") : ""
            icon: "skip_next"
            onClicked: TimerState.skipPhase()
        }
        Button {
            visible: root.mode === "stopwatch" && root.running
            label: root.wide ? I18n.tr("Lap") : ""
            icon: "flag"
            onClicked: TimerState.lap()
        }
        Repeater {
            model: root.mode === "countdown" && TimerState.countdownIdle ? [5, 10, 15, 30] : []
            Button {
                required property int modelData
                label: I18n.trn("%n min", "%n min", modelData)
                main: false
                ink: Math.round(TimerState.countdown.total / TimerState.unit) === modelData ? Colors.accent : Colors.textMuted
                edge: Math.round(TimerState.countdown.total / TimerState.unit) === modelData ? Colors.accent : Colors.divider
                onClicked: TimerState.setCountdown(modelData)
            }
        }
    }
    // Junto a una zona mas alta: lo de arriba queda arriba.
    Item { Layout.fillHeight: true }
}
