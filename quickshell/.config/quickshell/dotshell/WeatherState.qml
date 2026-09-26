// Clima (Fase 4 B6, P4.7): ubicacion y ultima respuesta de Open-Meteo, leidas
// de los archivos que escribe scripts/weather-fetch (unico que toca la red).
// Lo usan el reloj de la barra (clima compacto) y WeatherCard.qml.
//
// Consulta cada 30 min solo si hay ubicacion; al abrir el panel, si los datos
// tienen mas de 30 min (despues de suspender, por ejemplo); tras un fallo,
// reintenta a los 5 min. Sin ubicacion no hay ninguna consulta. Todo el texto
// visible sale en espanol (tabla de codigos WMO propia), sea cual sea el
// locale del sistema.
//
// Estado (status) para la tarjeta:
//   setup    sin ubicacion (primera configuracion)
//   loading  con ubicacion, sin datos todavia, consultando
//   offline  sin datos y el ultimo intento fallo por red
//   failed   sin datos y el ultimo intento fallo por la respuesta (HTTP o formato)
//   cached   hay datos pero el ultimo intento fallo por red (usando la cache)
//   error    hay datos pero el ultimo intento fallo por la respuesta
//   stale    hay datos de mas de 60 min (sin error: por ejemplo, tras suspender)
//   ok
// WEATHER_STATE / WEATHER_CACHE cambian los archivos (pruebas).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/weather-fetch"
    readonly property string statePath: Quickshell.env("WEATHER_STATE") || (Quickshell.env("HOME") + "/.local/state/dotfiles/weather.json")
    readonly property string cachePath: Quickshell.env("WEATHER_CACHE") || (Quickshell.env("HOME") + "/.cache/dotfiles/weather.json")

    property var location: null   // { name, detail, lat, lon }
    property var cache: null      // { fetched_at, last_attempt, last_error, place, data }
    property bool fetching: false
    property bool settled: false  // los dos archivos se leyeron (o no existen)

    readonly property bool configured: !!root.location
    readonly property var data: root.cache && root.cache.data ? root.cache.data : null
    readonly property real fetchedAt: root.cache && root.cache.fetched_at ? root.cache.fetched_at : 0
    // Error del ultimo intento, solo si es posterior a los datos.
    readonly property var lastError: root.cache && root.cache.last_error && root.cache.last_error.at >= root.fetchedAt
        ? root.cache.last_error : null

    // Estado segun la hora "now" (segundos) que pasa quien lo muestra.
    function status(now: real): string {
        if (!root.configured) return "setup";
        const err = root.lastError;
        if (!root.data) {
            if (root.fetching && !err) return "loading";
            if (err) return err.kind === "offline" ? "offline" : "failed";
            return "loading";
        }
        if (err) return err.kind === "offline" ? "cached" : "error";
        if (now - root.fetchedAt > 3600) return "stale";
        return "ok";
    }

    // ---- Consultas ------------------------------------------------------------
    function refresh(): void {
        if (!root.configured || root.fetching) return;
        root.fetching = true;
        fetchProc.running = true;
    }
    // Al abrir el panel: datos de mas de 30 min -> consultar.
    function ensureFresh(): void {
        if (root.configured && Date.now() / 1000 - root.fetchedAt >= 1800) root.refresh();
    }

    property Process fetchProc: Process {
        command: [root.script]
        onExited: (code) => {
            root.fetching = false;
            if (code === 1) retryTimer.restart();
        }
    }
    property Timer periodic: Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: root.configured
        onTriggered: root.refresh()
    }
    property Timer retryTimer: Timer {
        interval: 5 * 60 * 1000
        onTriggered: root.refresh()
    }

    // Busqueda de ciudad (solo mientras se elige) y ubicacion.
    property var searchResults: []
    property bool searching: false
    property bool searchFailed: false
    function search(query: string): void {
        const q = query.trim();
        if (q.length < 2) {
            root.searchResults = [];
            return;
        }
        searchProc.command = [root.script, "--search", q];
        root.searching = true;
        root.searchFailed = false;
        searchProc.running = true;
    }
    property Process searchProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                root.searching = false;
                try {
                    root.searchResults = JSON.parse(this.text);
                } catch (e) {
                    root.searchResults = [];
                    root.searchFailed = true;
                }
            }
        }
    }
    function setLocation(place: var): void {
        root.fetching = true;
        Quickshell.execDetached([root.script, "--set", String(place.lat), String(place.lon), place.name, place.detail || ""]);
        settleTimer.restart();
    }
    function clearLocation(): void {
        Quickshell.execDetached([root.script, "--clear"]);
    }
    // --set consulta por su cuenta: fetching vuelve a false cuando llega la cache.
    property Timer settleTimer: Timer {
        interval: 15000
        onTriggered: root.fetching = false
    }

    // ---- Archivos -------------------------------------------------------------
    property FileView stateFile: FileView {
        path: root.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(this.text());
                root.location = s && s.lat !== undefined ? s : null;
            } catch (e) {
                root.location = null;
            }
            root.settle();
        }
        onLoadFailed: {
            root.location = null;
            root.settle();
        }
    }
    property FileView cacheFile: FileView {
        path: root.cachePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.cache = JSON.parse(this.text());
            } catch (e) {
                root.cache = null;
            }
            if (root.data) {
                root.fetching = false;
                settleTimer.stop();
            }
            root.settle();
        }
        onLoadFailed: {
            root.cache = null;
            root.settle();
        }
    }
    property int loadedFiles: 0
    // Al arrancar (con los dos archivos leidos): si hace falta, consultar.
    function settle(): void {
        if (root.settled) return;
        root.loadedFiles++;
        if (root.loadedFiles < 2) return;
        root.settled = true;
        root.ensureFresh();
    }

    // ---- Presentacion (espanol) -------------------------------------------------
    // Codigo WMO -> texto e icono (Material Symbols; de noche, luna/nubes de noche).
    function describe(code: int, isDay: bool): var {
        const c = code;
        if (c === 0) return { text: "Despejado", icon: isDay ? "clear_day" : "bedtime" };
        if (c === 1) return { text: "Mayormente despejado", icon: isDay ? "partly_cloudy_day" : "partly_cloudy_night" };
        if (c === 2) return { text: "Parcialmente nublado", icon: isDay ? "partly_cloudy_day" : "partly_cloudy_night" };
        if (c === 3) return { text: "Nublado", icon: "cloud" };
        if (c === 45 || c === 48) return { text: "Niebla", icon: "foggy" };
        if (c >= 51 && c <= 55) return { text: "Llovizna", icon: "rainy_light" };
        if (c === 56 || c === 57) return { text: "Llovizna helada", icon: "rainy_light" };
        if (c === 61) return { text: "Lluvia débil", icon: "rainy_light" };
        if (c === 63) return { text: "Lluvia", icon: "rainy" };
        if (c === 65) return { text: "Lluvia fuerte", icon: "rainy_heavy" };
        if (c === 66 || c === 67) return { text: "Lluvia helada", icon: "rainy" };
        if (c >= 71 && c <= 75) return { text: "Nieve", icon: "weather_snowy" };
        if (c === 77) return { text: "Granizo fino", icon: "weather_snowy" };
        if (c === 80) return { text: "Chubascos", icon: "rainy" };
        if (c === 81 || c === 82) return { text: "Chubascos fuertes", icon: "rainy_heavy" };
        if (c === 85 || c === 86) return { text: "Chubascos de nieve", icon: "weather_snowy" };
        if (c === 95) return { text: "Tormenta", icon: "thunderstorm" };
        if (c === 96 || c === 99) return { text: "Tormenta con granizo", icon: "thunderstorm" };
        return { text: "Sin datos", icon: "cloud" };
    }
    // Temperatura redondeada con el signo menos tipografico (−5°, no -5°).
    function temp(value: real): string {
        if (value === undefined || value === null || isNaN(value)) return "–";
        const t = Math.round(value);
        return (t < 0 ? "−" + Math.abs(t) : String(t === 0 ? 0 : t)) + "°";
    }
    // "hace 12 min", "hace 3 h", "hace 2 días".
    function ago(seconds: real): string {
        const s = Math.max(0, seconds);
        if (s < 90) return "hace un momento";
        const m = Math.round(s / 60);
        if (m < 60) return "hace " + m + " min";
        const h = Math.round(m / 60);
        if (h < 48) return "hace " + h + " h";
        return "hace " + Math.round(h / 24) + " días";
    }
    readonly property var es: Qt.locale("es_ES")
    function cap(s: string): string {
        return s ? s.charAt(0).toUpperCase() + s.slice(1) : s;
    }
    // "2026-09-26" -> "Sáb" (en espanol, sin depender del locale del sistema).
    function dayShort(iso: string, index: int): string {
        if (index === 0) return "Hoy";
        const p = iso.split("-");
        const d = new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]));
        return root.cap(root.es.dayName(d.getDay(), Locale.ShortFormat).replace(".", ""));
    }
}
