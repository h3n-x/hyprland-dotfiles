// Opciones de color de TODOS los wallpapers (Fase 3 B8b): esquema
// predeterminado y contraste (decisiones B8b y B8d: 0 / 0.33 / 0.66 / 1).
// Contenido del panel "Tema global" de la galeria. Elegir guarda la
// preferencia al instante; se usa en el proximo cambio de tema (no se
// reaplica nada, B8b-5).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml

ColumnLayout {
    id: root

    property string scheme: "scheme-content"
    property real contrast: 0

    signal schemeChosen(string scheme)
    signal contrastChosen(real contrast)

    // Opciones y etiquetas del esquema del almacen (las mismas que muestra el
    // centro de configuracion): esquemas en el orden del esquema, niveles de
    // contraste de "presets".
    readonly property var schemes: {
        const m = SettingsState.meta("appearance.scheme");
        return m ? Object.keys(m.values).map(k => [k, m.values[k]]) : [];
    }
    readonly property var levels: (SettingsState.meta("appearance.contrast") || {}).presets || []

    spacing: Tokens.space.sm

    Text {
        text: "TODOS LOS WALLPAPERS"
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.caption
        font.weight: Tokens.weight.semibold
        font.letterSpacing: 0.6
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Esquema predeterminado"
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.label
        }
        Item { Layout.fillWidth: true }
        Select {
            id: schemePick
            options: root.schemes
            current: root.scheme
        }
    }

    // Lista de esquemas (se despliega en el panel; Select/SelectList compartidos).
    SelectList {
        visible: schemePick.open
        Layout.fillWidth: true
        options: root.schemes
        current: root.scheme
        onChosen: value => root.schemeChosen(value)
        onClosed: schemePick.open = false
    }

    Text {
        text: "Contraste"
        color: Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.label
    }
    // Control segmentado compartido (modules/Segmented.qml).
    Segmented {
        Layout.fillWidth: true
        options: root.levels
        current: root.contrast
        onChosen: value => root.contrastChosen(value)
    }

    Text {
        Layout.fillWidth: true
        text: "Se usan en el próximo cambio de tema."
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.caption
        wrapMode: Text.WordWrap
    }
}
