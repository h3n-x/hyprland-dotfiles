// Idioma de la shell (Fase 15 B1): appearance.language del almacen ("auto" =
// los idiomas de la sesion: LANGUAGE y luego los de Qt; ingles si ninguno tiene
// catalogo) y el catalogo de data/i18n/<idioma>.json. El nucleo (tr, trc, trn,
// fechas, duraciones, numeros) es I18nCore. Cambiar de idioma es en vivo: se
// relee el catalogo, cambia rev y cada texto se reevalua.
//
// Idiomas disponibles = los valores de appearance.language en el esquema
// (scripts/i18n add <idioma> crea el catalogo y lo agrega ahi).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

I18nCore {
    id: root

    readonly property string setting: SettingsState.value("appearance.language") || "auto"
    readonly property var available: {
        const m = SettingsState.meta("appearance.language");
        return m && m.values ? Object.keys(m.values).filter(k => k !== "auto") : ["en"];
    }
    // I18N_DIR: otros catalogos (pruebas).
    readonly property string dir: Quickshell.env("I18N_DIR") || Quickshell.shellPath("data/i18n")

    function resolve(): string {
        // Un idioma elegido que no tiene catalogo: ingles (igual que scripts/i18n).
        if (root.setting !== "auto") return root.available.indexOf(root.setting) >= 0 ? root.setting : "en";
        const wanted = (Quickshell.env("LANGUAGE") || "").split(":").concat(Qt.locale().uiLanguages || [], [Qt.locale().name]);
        for (const w of wanted) {
            const code = String(w || "").replace("-", "_").split("_")[0].toLowerCase();
            if (code && root.available.indexOf(code) >= 0) return code;
        }
        return "en";
    }
    lang: root.resolve()

    // Sincronico, como el esquema de SettingsState: el primer cuadro ya sale en el
    // idioma elegido. Se lee al cambiar la ruta, el texto (otro catalogo en disco) y
    // al crearse (la primera carga ocurre antes de que onLoaded este conectado).
    function parse(): void {
        try { root.catalog = root.file.path ? JSON.parse(root.file.text()) : null; } catch (e) { root.catalog = null; }
    }
    Component.onCompleted: root.parse()
    property FileView file: FileView {
        path: root.lang === "en" ? "" : root.dir + "/" + root.lang + ".json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: root.parse()
        onPathChanged: root.parse()
        onLoadFailed: root.catalog = null
    }
}
