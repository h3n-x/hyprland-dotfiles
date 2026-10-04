// Texto e icono del clima a partir del codigo WMO de Open-Meteo, en espanol
// sea cual sea el locale (Fase 9 B2: sacado de WeatherState). Pasivo: sin
// timers ni procesos, asi lo usan la shell (barra, dashboard) y el bloqueo de
// pantalla, que es otro proceso y nunca consulta la red.
pragma Singleton
import QtQuick

QtObject {
    // Temperatura (de Open-Meteo, siempre en °C) como se muestra: redondeada,
    // con signo menos tipografico y en las unidades elegidas ("c" o "f",
    // dashboard.weather.units, Fase 10 B4). Una sola implementacion para la
    // barra, el dashboard y el bloqueo.
    function temp(value: real, units: string): string {
        if (value === undefined || value === null || isNaN(value)) return "–";
        const t = Math.round(units === "f" ? value * 9 / 5 + 32 : value);
        return (t < 0 ? "−" + Math.abs(t) : String(t === 0 ? 0 : t)) + "°";
    }
    // De noche, luna/nubes de noche (Material Symbols).
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
}
