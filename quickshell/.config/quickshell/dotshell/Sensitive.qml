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
        "privkey": "una clave privada",
        "github": "un token de GitHub",
        "apikey-ai": "una clave de API",
        "apikey-cloud": "una clave de API",
        "jwt": "un token de sesión",
        "env-secret": "una contraseña o secreto",
        "password-like": "una contraseña"
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
        return labels[category] || "contenido sensible";
    }
}
