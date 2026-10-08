// Las opciones del almacen que cambian el design system en vivo (Fase 10 B2;
// antes, la de movimiento estaba copiada en shell.qml, lock.qml y
// settings.qml): reducir movimiento, fuentes, tamano del texto y foco
// visible. Una instancia en la raiz de cada proceso que dibuja con Tokens
// (shell, bloqueo, centro). Tokens no lee el almacen: lo comparte el greeter
// de SDDM, que recibe lo mismo por su theme.conf (sddm-theme-stage).
//
// Una fuente que ya no esta instalada vuelve a la de fabrica (Acerca de lo
// dice en Diagnostico).
import QtQuick

QtObject {
    id: root

    readonly property var installed: Qt.fontFamilies()
    function family(key: string, fallback: string): string {
        const f = SettingsState.value(key);
        return f && root.installed.indexOf(f) >= 0 ? f : fallback;
    }

    property Binding motion: Binding {
        target: Tokens.motion
        property: "scale"
        value: SettingsState.value("accessibility.reduceMotion") ? 0 : 1
    }
    property Binding uiFont: Binding {
        target: Tokens.font
        property: "ui"
        value: root.family("appearance.font.ui", "Plus Jakarta Sans")
    }
    property Binding monoFont: Binding {
        target: Tokens.font
        property: "mono"
        value: root.family("appearance.font.mono", "Maple Mono NF")
    }
    property Binding textScale: Binding {
        target: Tokens.type
        property: "scale"
        value: SettingsState.value("accessibility.textScale") || 1
    }
    // Donde va la barra y su grosor (Fase 11 B3): los lee todo lo que se ubica
    // respecto de ella (Tokens.bar, inset*). En el bloqueo y el login no hay barra.
    property Binding barEdge: Binding {
        target: Tokens.bar
        property: "edge"
        value: SettingsState.value("bar.edge") || "top"
    }
    property Binding barStyle: Binding {
        target: Tokens.bar
        property: "style"
        value: SettingsState.value("bar.style") || "floating"
    }
    property Binding barSize: Binding {
        target: Tokens.bar
        property: "height"
        value: SettingsState.value("bar.size") || 40
    }
    property Binding focusRing: Binding {
        target: Tokens
        property: "focusRing"
        value: !!SettingsState.value("accessibility.focusRing")
    }
}
