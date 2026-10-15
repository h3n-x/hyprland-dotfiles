// Nucleo de traduccion (Fase 15 B1): el texto fuente es ingles y es la clave;
// cada idioma es un catalogo JSON (data/i18n/<idioma>.json). QtQuick puro: lo
// usa la shell (I18n.qml, que lee el almacen y el archivo) y, en la Fase 15 B3,
// la superficie de login compartida con el greeter de SDDM.
//
// Catalogo:
//   "@meta": { "name": "Español", "plural": "one-other", "locale": "es_ES" }
//   "Notifications": "Notificaciones"
//   "format\u0004ddd d": "ddd d"                 contexto + U+0004 + texto (gettext)
//   "%n notification": { "one": "%n aviso", "other": "%n avisos" }
// Sin la clave (o sin catalogo, ingles) se muestra el texto fuente: nunca vacio.
//
// Argumentos %1..%9; %n es la cantidad de trn, con el formato numerico del
// idioma. rev cambia al cargar otro catalogo: los enlaces que llaman a tr()
// se reevaluan solos porque cada funcion lee rev.
import QtQuick

QtObject {
    id: root

    // Codigo del idioma ("en", "es", "ja"...) y su catalogo (null = ingles).
    property string lang: "en"
    property var catalog: null
    property int rev: 0
    onCatalogChanged: root.rev++

    readonly property var meta: root.catalog && root.catalog["@meta"] ? root.catalog["@meta"] : ({})
    // Familia de plurales (CLDR, solo las que hacen falta): one-other (en, es, de,
    // it, pt...), other (ja, zh, ko...: una sola forma), french (fr: 0 y 1 son
    // "one"), slavic (ru, uk: one, few, many).
    readonly property string plural: root.meta.plural || "one-other"
    readonly property var locale: Qt.locale(root.meta.locale || (root.lang === "en" ? "en_US" : root.lang))

    function lookup(key: string): var {
        void root.rev;
        return root.catalog ? root.catalog[key] : undefined;
    }
    function fill(s: string, args: var): string {
        let out = s;
        for (let i = 0; i < args.length; i++)
            out = out.split("%" + (i + 1)).join(String(args[i]));
        return out;
    }

    // Traducciones.
    // Sin anotaciones de tipo: reciben argumentos variables (%1, %2...).
    function tr(text) {
        const t = root.lookup(text);
        return root.fill(typeof t === "string" && t !== "" ? t : text, Array.prototype.slice.call(arguments, 1));
    }
    function trc(ctx, text) {
        const t = root.lookup(ctx + "\u0004" + text);
        // Vacio solo vale si la fuente es puro espacio (un separador que el idioma no usa).
        const ok = typeof t === "string" && (t !== "" || text.trim() === "");
        return root.fill(ok ? t : text, Array.prototype.slice.call(arguments, 2));
    }
    function category(n: real): string {
        const a = Math.abs(n);
        switch (root.plural) {
        case "other": return "other";
        case "french": return a < 2 ? "one" : "other";
        case "slavic": {
            if (a % 1 !== 0) return "other";
            const m10 = a % 10, m100 = a % 100;
            if (m10 === 1 && m100 !== 11) return "one";
            if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return "few";
            return "many";
        }
        default: return a === 1 ? "one" : "other";
        }
    }
    // Plurales: el catalogo da un objeto por categoria; sin traduccion, la regla del ingles.
    function trn(singular, pluralText, n) {
        const t = root.lookup(singular);
        let s;
        if (t && typeof t === "object") s = t[root.category(n)] || t.other || pluralText;
        else s = Math.abs(n) === 1 ? singular : pluralText;
        return root.fill(s.split("%n").join(root.number(n)), Array.prototype.slice.call(arguments, 3));
    }

    // ---- Formatos (dueno unico del locale: fechas, duraciones, numeros) ----------------
    // Numero con el separador decimal del idioma ("7,9" en espanol, "7.9" en ingles).
    function number(x, decimals) {
        void root.rev;
        const d = decimals === undefined ? (x % 1 === 0 ? 0 : 1) : decimals;
        return Number(x).toLocaleString(root.locale, "f", d);
    }
    // Fecha u hora con un patron de Qt traducible (contexto "format": cada idioma
    // ordena el dia, el mes y las palabras a su manera).
    function date(d: var, pattern: string): string {
        return d.toLocaleString(root.locale, root.trc("format", pattern));
    }
    function dayName(day: int, short: bool): string {
        void root.rev;
        return root.locale.standaloneDayName(day, short ? Locale.ShortFormat : Locale.LongFormat);
    }
    function monthName(month: int, short: bool): string {
        void root.rev;
        return root.locale.standaloneMonthName(month, short ? Locale.ShortFormat : Locale.LongFormat);
    }
    // "45 min", "2 h 5 min", "3 days".
    function duration(seconds: real): string {
        const m = Math.round(seconds / 60);
        if (m < 60) return root.trn("%n min", "%n min", m);
        const h = Math.floor(m / 60);
        if (h >= 48) return root.trn("%n day", "%n days", Math.floor(h / 24));
        return m % 60 ? root.tr("%1 h %2 min", h, m % 60) : root.tr("%1 h", h);
    }
    // Lista con la forma del idioma: "a", "a and b", "a, b and c" (es "a, b y c", ja "a、bとc").
    function join(parts: var): string {
        const p = (parts || []).filter(x => x !== "" && x !== undefined && x !== null);
        if (p.length < 2) return p.length ? String(p[0]) : "";
        const head = p.slice(0, -1).join(root.trc("list", ", "));
        return root.trc("list", "%1 and %2", head, p[p.length - 1]);
    }
    // Dia relativo a partir de un instante (segundos desde 1970): today, yesterday, %n days ago.
    function daysAgo(epochSec: real): string {
        if (!epochSec) return "";
        const days = Math.floor((Date.now() / 1000 - epochSec) / 86400);
        if (days <= 0) return root.trc("relative day", "today");
        if (days === 1) return root.trc("relative day", "yesterday");
        return root.trn("%n day ago", "%n days ago", days);
    }
    // Hace cuanto, a partir de segundos: "a moment ago", "5 min ago", "3 h ago", "2 days ago".
    // precise (graficos de pocos minutos): "now" y segundos.
    function ago(seconds: real, precise: bool): string {
        const s = Math.max(0, seconds);
        if (precise) {
            if (s < 5) return root.trc("relative time", "now");
            if (s < 60) return root.trn("%n s ago", "%n s ago", Math.round(s));
        } else if (s < 90) return root.tr("a moment ago");
        const m = Math.round(s / 60);
        if (m < 60) return root.trn("%n min ago", "%n min ago", m);
        const h = Math.round(m / 60);
        if (h < 48) return root.trn("%n h ago", "%n h ago", h);
        return root.trn("%n day ago", "%n days ago", Math.round(h / 24));
    }
    // "7.9 GB", "420 MB".
    function bytes(b: real): string {
        const gb = b / 1073741824;
        if (gb >= 100) return root.tr("%1 GB", root.number(Math.round(gb), 0));
        if (gb >= 1) return root.tr("%1 GB", root.number(gb, 1));
        return root.tr("%1 MB", root.number(Math.round(b / 1048576), 0));
    }
}
