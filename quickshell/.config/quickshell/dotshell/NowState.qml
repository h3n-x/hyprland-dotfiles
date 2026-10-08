// La zona "Ahora" de Inicio (Fase 11 B5b, P11.6): lo mas relevante del
// momento, de datos que ya estan en memoria (sin fuentes nuevas, sin
// consultas). En orden de prioridad, lo primero que aplique de
// dashboard.now.kinds:
//   timer   un temporizador en marcha (TimerState)
//   rain    lluvia probable (>= 50 %) en las proximas 3 horas (WeatherState)
//   todo    tareas pendientes (TodoState; solo si Tareas no esta en Inicio)
//   heat    calor (>= 35 grados) o helada (<= 0) ahora
//   sunset  el sol se pone dentro de la proxima hora
// Sin nada que mostrar, `item` es null y la zona no ocupa lugar. El clima
// cuenta solo con datos de menos de 3 h. La hora avanza con la Demand
// `clock` (HomeZones: la zona puesta y el dashboard a la vista), una vez por
// minuto; tambien pide las tareas (TodoState) si hacen falta.
pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property var kinds: SettingsState.value("dashboard.now.kinds") || []
    // Tareas ya esta a la vista en Inicio: no se repite.
    readonly property bool todoPlaced: (SettingsState.value("dashboard.home.zones") || []).some(z => z.id === "todo")

    property real now: Date.now()
    property Demand clock: Demand {
        name: "now.clock"
        onActiveChanged: root.now = Date.now()
    }
    property Timer minute: Timer {
        interval: 60000
        repeat: true
        running: root.clock.active
        onTriggered: root.now = Date.now()
    }

    readonly property var weather: WeatherState.data && (root.now / 1000 - WeatherState.fetchedAt) < 3 * 3600 ? WeatherState.data : null

    function pick(kind: string): var {
        if (kind === "timer") {
            const a = TimerState.active;
            if (!a) return null;
            return { kind: kind, icon: "timer", view: "",
                     text: a.label + (a.left !== undefined ? " · quedan " + TimerState.short(a.left) : " · " + TimerState.short(a.elapsed)),
                     detail: a.mode === "pomodoro" ? "Pomodoro" : "" };
        }
        if (kind === "rain") {
            const h = root.weather ? root.weather.hourly : null;
            if (!h || !h.precipitation_probability) return null;
            // La primera hora es la actual; las tres siguientes.
            for (let i = 1; i <= 3 && i < h.time.length; i++) {
                const p = h.precipitation_probability[i];
                if (p >= 50)
                    return { kind: kind, icon: "rainy", view: "today", text: "Lluvia hacia las " + h.time[i].slice(11, 13) + " h",
                             detail: p + " % de probabilidad" };
            }
            return null;
        }
        if (kind === "todo") {
            if (root.todoPlaced || !TodoState.loaded) return null;
            const n = TodoState.open.length;
            if (!n) return null;
            return { kind: kind, icon: "checklist", view: "", text: n + (n === 1 ? " tarea pendiente" : " tareas pendientes"),
                     detail: TodoState.open[0].text };
        }
        if (kind === "heat") {
            const c = root.weather ? root.weather.current : null;
            if (!c) return null;
            const t = c.temperature_2m;
            if (t >= 35) return { kind: kind, icon: "thermostat", view: "today", text: "Calor fuerte: " + WeatherState.temp(t),
                                  detail: "Sensación " + WeatherState.temp(c.apparent_temperature) };
            if (t <= 0) return { kind: kind, icon: "ac_unit", view: "today", text: "Helada: " + WeatherState.temp(t),
                                 detail: "Sensación " + WeatherState.temp(c.apparent_temperature) };
            return null;
        }
        if (kind === "sunset") {
            const d = root.weather ? root.weather.daily : null;
            if (!d || !d.sunset || !d.sunset[0]) return null;
            // Hora local del lugar ("2026-10-08T19:42"), como la de este equipo.
            const at = new Date(d.sunset[0]).getTime();
            const left = at - root.now;
            if (left <= 0 || left > 3600000) return null;
            return { kind: kind, icon: "wb_twilight", view: "today", text: "El sol se pone a las " + d.sunset[0].slice(11, 16),
                     detail: "en " + Math.max(1, Math.round(left / 60000)) + " min" };
        }
        return null;
    }
    readonly property var order: ["timer", "rain", "todo", "heat", "sunset"]
    readonly property var item: {
        void root.now;
        for (const k of root.order) {
            if (root.kinds.indexOf(k) < 0) continue;
            const it = root.pick(k);
            if (it) return it;
        }
        return null;
    }
}
