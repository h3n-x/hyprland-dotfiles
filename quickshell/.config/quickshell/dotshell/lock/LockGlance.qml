// Lo que el bloqueo muestra "de un vistazo" (Fase 9 B2, P9.3): clima, musica,
// bateria y avisos, mas el aviso de Bloq Mayus. Una sola instancia por
// bloqueo (lock.qml), compartida por las vistas de todas las pantallas.
//
// Solo lectura y por eventos, nada consulta periodicamente:
//   clima    la cache que escribe weather-fetch (la shell la refresca; el
//            bloqueo nunca toca la red); vieja de mas de 2 h = no se muestra
//   musica   MediaState (Mpris, sin procesos): el titulo que suena y el
//            artista (o el reproductor); sin portada
//   bateria  BatteryState (UPower): solo funcionando con bateria
//   avisos   $XDG_RUNTIME_DIR/dotfiles-notifications.json, que escribe
//            NotificationState al llegar cada aviso: cuantos llegaron desde
//            que se bloqueo, nunca el contenido; con No molestar, nada
//   Bloq May una lectura de hyprctl al empezar y despues las propias teclas
// Cada elemento existe solo si tiene algo que decir; cada uno se apaga en
// Opciones (lock.glance.*). No usa WeatherState, NotificationState ni
// SystemState: buscan red, son duenos del servicio de avisos o muestrean.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Scope {
    id: root

    // ---- Bloq Mayus -----------------------------------------------------------------------
    property bool capsLock: false
    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kb = JSON.parse(this.text).keyboards.find(k => k.main);
                    if (kb) root.capsLock = kb.capsLock;
                } catch (e) {}
            }
        }
    }
    // Cada tecla del bloqueo pasa por aca: la propia Bloq Mayus la invierte y
    // una letra la corrige (mayuscula sin Shift o minuscula con Shift = activo).
    function noteKey(event: var): void {
        if (event.key === Qt.Key_CapsLock) {
            root.capsLock = !root.capsLock;
            return;
        }
        const t = event.text;
        if (t && t.length === 1 && t.toLowerCase() !== t.toUpperCase()) {
            const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
            root.capsLock = (t === t.toUpperCase()) !== shift;
        }
    }

    // ---- Clima ----------------------------------------------------------------------------
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    property var weatherCache: null
    FileView {
        path: Quickshell.env("LOCK_WEATHER_CACHE") || (Quickshell.env("HOME") + "/.cache/dotfiles/weather.json")
        watchChanges: true
        printErrors: false
        onFileChanged: this.reload()
        onLoaded: {
            try { root.weatherCache = JSON.parse(this.text()); } catch (e) { root.weatherCache = null; }
        }
        onLoadFailed: root.weatherCache = null
    }
    readonly property var weather: {
        if (!SettingsState.value("lock.glance.weather")) return null;
        const c = root.weatherCache;
        const cur = c && c.data ? c.data.current : null;
        if (!cur || !c.fetched_at) return null;
        if (clock.date.getTime() / 1000 - c.fetched_at > 2 * 3600) return null;
        const d = WeatherText.describe(cur.weather_code, cur.is_day === 1);
        return { icon: d.icon, temp: Math.round(cur.temperature_2m), text: d.text };
    }

    // ---- Musica ---------------------------------------------------------------------------
    readonly property bool playing: SettingsState.value("lock.glance.media") === true
        && !!MediaState.active && MediaState.active.isPlaying

    // ---- Bateria --------------------------------------------------------------------------
    readonly property bool onBattery: SettingsState.value("lock.glance.battery") === true
        && BatteryState.present && !BatteryState.onAc

    // ---- Avisos ---------------------------------------------------------------------------
    property int received: -1
    property int atLock: -1
    property bool dnd: false
    FileView {
        path: Quickshell.env("LOCK_NOTIFICATIONS_FILE") || ((Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/dotfiles-notifications.json")
        watchChanges: true
        printErrors: false
        onFileChanged: this.reload()
        onLoaded: {
            let s = null;
            try { s = JSON.parse(this.text()); } catch (e) {}
            if (!s) return;
            root.dnd = s.dnd === true;
            root.received = s.received;
            // El primer valor es el de antes de bloquear; si la shell se reinicio
            // (el contador volvio a empezar), se cuenta desde cero.
            if (root.atLock < 0 || s.received < root.atLock) root.atLock = root.atLock < 0 ? s.received : 0;
        }
    }
    readonly property int notifications: SettingsState.value("lock.glance.notifications") === true && !root.dnd && root.atLock >= 0
        ? Math.max(0, root.received - root.atLock) : 0

    // ---- Tarjetas, en orden fijo ----------------------------------------------------------
    readonly property var tiles: {
        const r = [];
        if (root.weather) r.push({ key: "weather", icon: root.weather.icon, title: root.weather.temp + "°", sub: root.weather.text, tone: "" });
        if (root.playing) {
            // El titulo de lo que suena (a pedido, 2026-10-04; antes solo
            // "Reproduciendo"); sin titulo, "Música". Debajo, el artista o el
            // reproductor.
            const p = MediaState.active;
            r.push({ key: "music", icon: "music_note", title: p.trackTitle || "Música",
                     sub: p.trackArtist || MediaState.nameOf(p) || "Reproduciendo", tone: "" });
        }
        if (root.onBattery) r.push({
            key: "battery",
            icon: BatteryState.critical || BatteryState.warning ? "battery_alert" : "battery_android_full",
            title: Math.round(BatteryState.pct * 100) + " %",
            sub: BatteryState.critical ? "Batería crítica" : BatteryState.warning ? "Batería baja" : "Con batería",
            tone: BatteryState.critical ? "danger" : BatteryState.warning ? "warning" : "" });
        if (root.notifications > 0) r.push({ key: "notifications", icon: "notifications", title: root.notifications + (root.notifications === 1 ? " aviso" : " avisos"), sub: "Nuevos", tone: "" });
        return r;
    }
}
