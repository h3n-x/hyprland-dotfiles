// Busqueda difusa compartida (Fase 4 B0): la del launcher, sacada tal cual
// para que la usen los demas selectores (portapapeles, emoji...).
//
// Coincidencia "subsecuencia": los caracteres de la busqueda aparecen en
// orden en el texto, no necesariamente juntos ("vsc" -> "Visual Studio
// Code"). Mas puntaje para coincidencias seguidas y al comienzo de una
// palabra. match() devuelve null si no coincide, o un objeto con score y
// positions. (Sin llaves en este encabezado: Quickshell deja de buscar
// "pragma Singleton" en la primera, aunque este en un comentario.)
pragma Singleton
import QtQuick
import Quickshell

Item {
    function match(text: string, query: string): var {
        if (!query) return { score: 0, positions: [] };
        if (!text) return null;
        const t = text.toLowerCase();
        const q = query.toLowerCase();
        let ti = 0, qi = 0, consecutive = 0, score = 0;
        const positions = [];
        while (ti < t.length && qi < q.length) {
            if (t[ti] === q[qi]) {
                positions.push(ti);
                score += 10 + consecutive * 5;
                if (ti === 0 || t[ti - 1] === " " || t[ti - 1] === "-") score += 15;
                consecutive++;
                qi++;
            } else {
                consecutive = 0;
            }
            ti++;
        }
        if (qi < q.length) return null;
        score -= (t.length - q.length) * 0.1;
        return { score, positions };
    }

    function escapeHtml(s: string): string {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // Marca en primary los caracteres que coincidieron (sin busqueda o sin
    // posiciones, el texto tal cual).
    function highlight(text: string, positions: var): string {
        if (!positions || positions.length === 0) return escapeHtml(text);
        const posSet = new Set(positions);
        let result = "";
        for (let i = 0; i < text.length; i++) {
            const ch = escapeHtml(text[i]);
            result += posSet.has(i) ? ("<b style=\"color:" + Colors.accent + "\">" + ch + "</b>") : ch;
        }
        return result;
    }
}
