// Clima (Fase 4 B6, P4.7): ubicacion y ultima respuesta de Open-Meteo, leidas
// de los archivos que escribe scripts/weather-fetch (unico que toca la red).
// Lo usan el reloj de la barra (clima compacto) y el dashboard (linea de
// contexto de Inicio y la vista Hoy, WeatherView.qml).
//
// Consulta cada 30 min solo si hay ubicacion; al abrir el panel, si los datos
// tienen mas de 30 min (despues de suspender, por ejemplo); tras un fallo,
// reintenta a los 5 min. Sin ubicacion no hay ninguna consulta. Todo el texto
// visible sale en espanol (tabla de codigos WMO en WeatherText.qml), sea cual sea el
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
// WEATHER_CACHE cambia la cache (pruebas); la ciudad vive en el almacen
// (dashboard.weather.location, Fase 10 B4).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/weather-fetch"
    readonly property string cachePath: Quickshell.env("WEATHER_CACHE") || (Quickshell.env("HOME") + "/.cache/dotfiles/weather.json")

    // { name, detail, lat, lon } o null: el almacen de opciones
    // (dashboard.weather.location, Fase 10 B4); lo escribe weather-fetch --set.
    readonly property var location: SettingsState.ready ? SettingsState.value("dashboard.weather.location") : null
    property var cache: null      // { fetched_at, last_attempt, last_error, place, data }
    property bool fetching: false
    property bool settled: false  // el almacen y la cache se leyeron (o no existe)

    readonly property bool configured: !!root.location
    readonly property var data: root.cache && root.cache.data ? root.cache.data : null
    readonly property var current: root.data ? root.data.current : null
    readonly property real fetchedAt: root.cache && root.cache.fetched_at ? root.cache.fetched_at : 0
    // Proximas 12 h, cada 2 h (la API da 12 horas desde la actual): la vista Hoy
    // y la zona "Proximas horas" de Inicio (WeatherHours).
    readonly property var hours: {
        if (!root.data || !root.data.hourly) return [];
        const h = root.data.hourly;
        const out = [];
        for (let i = 0; i < h.time.length && out.length < 6; i += 2)
            out.push({ label: i === 0 ? "Ahora" : h.time[i].slice(11, 13) + " h", code: h.weather_code[i],
                       day: h.is_day ? h.is_day[i] === 1 : true, t: h.temperature_2m[i],
                       rain: h.precipitation_probability ? h.precipitation_probability[i] : 0 });
        return out;
    }
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

    // Clima compacto (barra, Inicio): atenuado, no oculto, si los datos tienen
    // mas de 60 min o el ultimo intento fallo.
    function isDim(now: real): bool {
        return !!root.current && (!!root.lastError || now - root.fetchedAt > 3600);
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
        // dashboard.weatherRefreshMinutes (settings store)
        interval: SettingsState.value("dashboard.weatherRefreshMinutes") * 60 * 1000
        repeat: true
        running: root.configured
        onTriggered: root.refresh()
    }
    property Timer retryTimer: Timer {
        interval: 5 * 60 * 1000
        onTriggered: root.refresh()
    }

    // Ubicacion (la busqueda vive en modules/CitySearch.qml, Fase 10 B4).
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
    // La ciudad la cambia otro escritor (el centro de configuracion,
    // `settings set`): consultar con la nueva. weather-fetch --set ya consulta
    // por su cuenta (fetching), asi que ahi no.
    onLocationChanged: {
        if (!root.settled) return;
        // Otra ciudad: los datos guardados son de la anterior.
        if (root.location && !root.fetching) root.refresh();
    }
    property Connections storeReady: Connections {
        target: SettingsState
        function onReadyChanged() { if (SettingsState.ready) root.settle(); }
    }
    Component.onCompleted: if (SettingsState.ready) root.settle()
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
    // Temperatura redondeada con el signo menos tipografico (−5°, no -5°).
    function temp(value: real): string {
        return WeatherText.temp(value, SettingsState.value("dashboard.weather.units"));
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
