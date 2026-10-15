// Temporizadores de Inicio (Fase 11 B5b, P11.6): pomodoro, cronometro y
// cuenta atras, independientes, con un solo dueno. El estado son marcas de
// tiempo en ~/.local/state/dotfiles/timer.json (StateFile, version 1), asi
// que una recarga de la shell no pierde nada.
//
// Costo (D-B5-3): nada hace tic mientras nadie mira. El fin de una fase o de
// la cuenta atras lo dispara UN temporizador de un solo disparo armado para
// ese momento (aviso y siguiente fase). La hora que se muestra avanza solo con
// una Demand: `seconds` (la zona Temporizador a la vista) o `minutes` (el
// modulo de la barra), y solo mientras algo corre.
//
// Cada cambio de fase avisa (notify-send, nunca en silencio) y, si se pide,
// suena (pw-play y el tema de sonidos freedesktop, si estan). Pruebas:
// TIMER_MINUTE_MS (largo de un minuto), TIMER_NOTIFY (en vez de notify-send).
pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    // ---- Opciones ---------------------------------------------------------------------
    // Un minuto en ms (TIMER_MINUTE_MS lo acorta en las pruebas).
    readonly property real unit: Number(Quickshell.env("TIMER_MINUTE_MS")) || 60000
    readonly property real focusMs: (SettingsState.value("dashboard.timer.focusMinutes") || 25) * root.unit
    readonly property real breakMs: (SettingsState.value("dashboard.timer.breakMinutes") || 5) * root.unit
    readonly property real longBreakMs: (SettingsState.value("dashboard.timer.longBreakMinutes") || 15) * root.unit
    readonly property int cycles: SettingsState.value("dashboard.timer.cycles") || 4
    readonly property bool autoContinue: SettingsState.value("dashboard.timer.autoContinue") !== false
    readonly property bool sound: SettingsState.value("dashboard.timer.sound") === true

    // ---- Estado (archivo) -----------------------------------------------------------------
    // Siempre abierto: es chico y una fase puede terminar con el dashboard cerrado.
    property StateFile file: StateFile {
        name: "timer.json"
        enabled: true
    }
    readonly property var blank: ({
        version: 1, mode: "pomodoro",
        pomodoro: { running: false, phase: "focus", cycle: 0, endsAt: 0, left: 0 },
        stopwatch: { running: false, startedAt: 0, elapsed: 0, laps: [] },
        countdown: { running: false, endsAt: 0, left: 0, total: 10 * root.unit }
    })
    readonly property var st: {
        const d = root.file.data || {};
        const b = root.blank;
        return {
            mode: ["pomodoro", "stopwatch", "countdown"].indexOf(d.mode) >= 0 ? d.mode : b.mode,
            pomodoro: Object.assign({}, b.pomodoro, d.pomodoro || {}),
            stopwatch: Object.assign({}, b.stopwatch, d.stopwatch || {}),
            countdown: Object.assign({}, b.countdown, d.countdown || {})
        };
    }
    // Listo para usar: el archivo leido y las opciones (duraciones) cargadas.
    readonly property bool ready: root.file.loaded && SettingsState.ready
    // Al arrancar, el almacen da primero los valores de fabrica y enseguida los
    // tuyos: lo que termino con la shell cerrada se procesa un momento despues.
    onReadyChanged: if (root.ready) settle.start()
    property Timer settle: Timer {
        interval: 1500
        onTriggered: root.due()
    }
    function put(part: string, value: var): void {
        if (!root.ready) return;
        const n = Object.assign({ version: 1 }, root.st);
        n[part] = value;
        root.file.save(n);
        Qt.callLater(root.arm);
    }
    readonly property string mode: root.st.mode
    function setMode(m: string): void {
        if (m !== root.mode) root.put("mode", m);
    }

    // ---- Hora mostrada ---------------------------------------------------------------------
    property real now: Date.now()
    property Demand seconds: Demand { name: "timer.seconds"; onActiveChanged: root.tick() }
    property Demand minutes: Demand { name: "timer.minutes"; onActiveChanged: root.tick() }
    readonly property bool anyRunning: root.st.pomodoro.running || root.st.stopwatch.running || root.st.countdown.running
    readonly property bool ticking: root.anyRunning && (root.seconds.active || root.minutes.active)
    onTickingChanged: root.tick()
    // Alineado al segundo (o al minuto): se rearma en cada disparo.
    function tick(): void {
        root.now = Date.now();
        if (!root.ticking) {
            ticker.stop();
            return;
        }
        const step = root.seconds.active ? 1000 : 60000;
        ticker.interval = step - root.now % step + 5;
        ticker.restart();
    }
    property Timer ticker: Timer {
        repeat: false
        onTriggered: root.tick()
    }

    // ---- Pomodoro --------------------------------------------------------------------------
    readonly property var pomodoro: root.st.pomodoro
    function phaseMs(phase: string): real {
        return phase === "long" ? root.longBreakMs : phase === "break" ? root.breakMs : root.focusMs;
    }
    readonly property real pomodoroLeft: root.pomodoro.running ? Math.max(0, root.pomodoro.endsAt - root.now)
        : (root.pomodoro.left > 0 ? root.pomodoro.left : root.phaseMs(root.pomodoro.phase))
    readonly property real pomodoroFraction: 1 - root.pomodoroLeft / Math.max(1, root.phaseMs(root.pomodoro.phase))
    readonly property string phaseLabel: root.pomodoro.phase === "long" ? I18n.tr("Long break") : root.pomodoro.phase === "break" ? I18n.tr("Break") : I18n.tr("Focus")
    function togglePomodoro(): void {
        const p = Object.assign({}, root.pomodoro);
        if (p.running) {
            p.left = Math.max(0, p.endsAt - Date.now());
            p.running = false;
        } else {
            p.endsAt = Date.now() + (p.left > 0 ? p.left : root.phaseMs(p.phase));
            p.left = 0;
            p.running = true;
        }
        root.put("pomodoro", p);
    }
    function resetPomodoro(): void {
        root.put("pomodoro", Object.assign({}, root.blank.pomodoro));
    }
    function skipPhase(): void {
        root.put("pomodoro", root.nextPhase(root.pomodoro, Date.now(), root.pomodoro.running));
    }
    // La fase que sigue a p, empezando en t.
    function nextPhase(p: var, t: real, run: bool): var {
        const n = Object.assign({}, p);
        if (p.phase === "focus") {
            n.cycle = (p.cycle || 0) + 1;
            n.phase = n.cycle % root.cycles === 0 ? "long" : "break";
        } else {
            n.phase = "focus";
            if (p.phase === "long") n.cycle = 0;
        }
        n.running = run;
        n.left = run ? 0 : root.phaseMs(n.phase);
        n.endsAt = run ? t + root.phaseMs(n.phase) : 0;
        return n;
    }

    // ---- Cronometro -------------------------------------------------------------------------
    readonly property var stopwatch: root.st.stopwatch
    readonly property real stopwatchElapsed: root.stopwatch.running ? Math.max(0, root.now - root.stopwatch.startedAt) : root.stopwatch.elapsed
    function toggleStopwatch(): void {
        const s = Object.assign({}, root.stopwatch);
        if (s.running) {
            s.elapsed = Math.max(0, Date.now() - s.startedAt);
            s.running = false;
        } else {
            s.startedAt = Date.now() - s.elapsed;
            s.running = true;
        }
        root.put("stopwatch", s);
    }
    function lap(): void {
        if (!root.stopwatch.running) return;
        const s = Object.assign({}, root.stopwatch);
        s.laps = [Date.now() - s.startedAt].concat(s.laps || []).slice(0, 10);
        root.put("stopwatch", s);
    }
    function resetStopwatch(): void {
        root.put("stopwatch", Object.assign({}, root.blank.stopwatch));
    }

    // ---- Cuenta atras ------------------------------------------------------------------------
    readonly property var countdown: root.st.countdown
    readonly property real countdownLeft: root.countdown.running ? Math.max(0, root.countdown.endsAt - root.now)
        : (root.countdown.left > 0 ? root.countdown.left : root.countdown.total)
    readonly property real countdownFraction: 1 - root.countdownLeft / Math.max(1, root.countdown.total)
    // Sin empezar (o recien reiniciada): se puede elegir cuanto.
    readonly property bool countdownIdle: !root.countdown.running && !(root.countdown.left > 0)
    function setCountdown(minutes: int): void {
        if (!root.countdownIdle) return;
        root.put("countdown", Object.assign({}, root.countdown, { total: Math.max(1, Math.min(600, minutes)) * root.unit }));   // minutos (px-ok)
    }
    function toggleCountdown(): void {
        const c = Object.assign({}, root.countdown);
        if (c.running) {
            c.left = Math.max(0, c.endsAt - Date.now());
            c.running = false;
        } else {
            c.endsAt = Date.now() + (c.left > 0 ? c.left : c.total);
            c.left = 0;
            c.running = true;
        }
        root.put("countdown", c);
    }
    function resetCountdown(): void {
        root.put("countdown", Object.assign({}, root.countdown, { running: false, endsAt: 0, left: 0 }));
    }

    // ---- El modo elegido (la zona, la barra, IPC) -------------------------------------------
    function toggle(): void {
        if (root.mode === "stopwatch") root.toggleStopwatch();
        else if (root.mode === "countdown") root.toggleCountdown();
        else root.togglePomodoro();
    }
    function reset(): void {
        if (root.mode === "stopwatch") root.resetStopwatch();
        else if (root.mode === "countdown") root.resetCountdown();
        else root.resetPomodoro();
    }
    // Lo que corre, para la barra y "Ahora": { mode, label, left (ms) | elapsed (ms) } o null.
    readonly property var active: root.pomodoro.running ? { mode: "pomodoro", label: root.phaseLabel, left: root.pomodoroLeft }
        : root.countdown.running ? { mode: "countdown", label: I18n.tr("Countdown"), left: root.countdownLeft }
                    : root.stopwatch.running ? { mode: "stopwatch", label: I18n.tr("Stopwatch"), elapsed: root.stopwatchElapsed }
        : null

    // ---- Fin de fase: un solo disparo ----------------------------------------------------------
    property Timer alarm: Timer {
        repeat: false
        onTriggered: root.due()
    }
    function arm(): void {
        alarm.stop();
        if (!root.ready) return;
        const ends = [];
        if (root.pomodoro.running) ends.push(root.pomodoro.endsAt);
        if (root.countdown.running) ends.push(root.countdown.endsAt);
        if (!ends.length) return;
        alarm.interval = Math.max(1, Math.min(...ends) - Date.now());
        alarm.start();
    }
    // Lo que ya termino (tambien al arrancar o al volver de una suspension).
    function due(): void {
        const t = Date.now();
        let p = root.pomodoro;
        if (p.running && p.endsAt <= t) {
            // Varias fases pasadas (equipo suspendido): se avanza hasta la actual, un solo aviso.
            let from = p.phase, guard = 0;
            while (p.running && p.endsAt <= t && guard++ < 50) {
                const end = p.endsAt;
                p = root.nextPhase(p, end, root.autoContinue);
            }
            root.put("pomodoro", p);
            const what = p.phase === "focus" ? I18n.tr("Time to focus: %1 min", Math.round(root.focusMs / root.unit))
                : p.phase === "long" ? I18n.tr("Long break: %1 min", Math.round(root.longBreakMs / root.unit)) : I18n.tr("Break: %1 min", Math.round(root.breakMs / root.unit));
            const done = from === "focus" ? I18n.tr("Focus time is over.") : I18n.tr("The break is over.");
            root.notify(I18n.tr("Pomodoro"), done + I18n.trc("sentence separator", " ") + (p.running ? I18n.tr("%1.", what) : I18n.tr("%1 (paused: press start).", what)));
        }
        const c = root.countdown;
        if (c.running && c.endsAt <= t) {
            root.put("countdown", Object.assign({}, c, { running: false, endsAt: 0, left: 0 }));
            root.notify(I18n.tr("Countdown"), I18n.tr("Finished: %1.", root.format(c.total)));
        }
        root.now = t;
        root.arm();
    }
    function notify(title: string, body: string): void {
        Quickshell.execDetached([Quickshell.env("TIMER_NOTIFY") || "notify-send", "-a", I18n.tr("Timer"), "-i", "alarm", title, body]);
        if (root.sound)
            Quickshell.execDetached(["sh", "-c", "f=/usr/share/sounds/freedesktop/stereo/complete.oga; [ -f \"$f\" ] && command -v pw-play >/dev/null && exec pw-play \"$f\""]);
    }

    // ---- Formato -----------------------------------------------------------------------------
    // "24:59", "1:02:03".
    function format(ms: real): string {
        const s = Math.ceil(Math.max(0, ms) / 1000);
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), x = s % 60;
        const two = n => (n < 10 ? "0" : "") + n;
        return h > 0 ? h + ":" + two(m) + ":" + two(x) : two(m) + ":" + two(x);
    }
    // "12 min", "menos de 1 min", "1 h 05".
    function short(ms: real): string {
        const m = Math.ceil(Math.max(0, ms) / 60000);
        if (m <= 1 && ms < 60000) return I18n.tr("< 1 min");
        return m >= 60 ? I18n.tr("%1 h %2", Math.floor(m / 60), (m % 60 < 10 ? "0" : "") + m % 60) : I18n.trn("%n min", "%n min", m);
    }
}
