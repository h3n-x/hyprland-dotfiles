// Deteccion de contenido sensible (Fase 4 B2): los mismos patrones que
// scripts/clipboard-store (cambiar uno = cambiar los dos). El script evita
// que lo sensible se guarde; esto solo oculta en el panel las entradas
// viejas, guardadas antes del filtro, a partir de su vista previa.
//
// check(texto) devuelve la categoria (privkey, github, apikey-ai,
// apikey-cloud, jwt, env-secret, password-like) o "" si no parece sensible.
// label(categoria) da el texto para la fila.
pragma Singleton
import QtQuick

QtObject {
    readonly property var patterns: [
        ["privkey", /-----BEGIN [A-Z ]*PRIVATE KEY-----/],
        ["github", /(gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,})/],
        ["apikey-ai", /(sk-ant-[A-Za-z0-9_-]{20,}|sk-(proj-)?[A-Za-z0-9_-]{32,})/],
        ["apikey-cloud", /(AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[A-Za-z0-9-]{10,})/],
        ["jwt", /eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/],
        ["env-secret", /(^|[^A-Za-z])(PASSWORD|PASSWD|SECRET|TOKEN|API_?KEY)[A-Z_]*\s*=\s*\S{6,}/]
    ]
    readonly property var labels: ({
        "privkey": I18n.tr("a private key"),
        "github": I18n.tr("a GitHub token"),
        "apikey-ai": I18n.tr("an API key"),
        "apikey-cloud": I18n.tr("an API key"),
        "jwt": I18n.tr("a session token"),
        "env-secret": I18n.tr("a password or secret"),
        "password-like": I18n.tr("a password")
    })

    function check(text: string): string {
        if (!text) return "";
        for (const p of patterns)
            if (p[1].test(text)) return p[0];
        // Forma de contrasena: una linea, sin espacios, 12-128 caracteres,
        // mayuscula + minuscula + digito + simbolo, no ruta ni URL.
        const d = text.replace(/[\r\n]+$/, "");
        if (d.length >= 12 && d.length <= 128 && !/[\s\/]/.test(d)
                && /[A-Z]/.test(d) && /[a-z]/.test(d) && /[0-9]/.test(d) && /[^A-Za-z0-9._-]/.test(d))
            return "password-like";
        return "";
    }

    function label(category: string): string {
        return labels[category] || I18n.tr("sensitive content");
    }
}
