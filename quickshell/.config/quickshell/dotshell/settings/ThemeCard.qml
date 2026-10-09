// Tema actual, arriba de "Color" en Apariencia (Fase 10 B2): el wallpaper
// aplicado y con que esquema y contraste se aplico. Esquema y contraste se
// usan la proxima vez que se aplique un tema; si difieren de los del tema
// actual, "Aplicar al tema actual" lo reaplica con ellos (theme-apply.sh, el
// camino de siempre; nunca solo). Si el wallpaper tiene su propio esquema
// (excepcion de la galeria), el global no lo cambia y se dice.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".." // Colors.qml, Tokens.qml, SettingsState.qml, ThemeState.qml
import "../modules"

Item {
    id: card

    required property SettingsModel model

    readonly property var current: ThemeState.current || null
    readonly property string wallpaper: card.current && card.current.wallpaper ? card.current.wallpaper : ""
    readonly property var override: (ThemeState.overrides || {})[card.wallpaper] || ({})
    readonly property string wantScheme: card.override.scheme || SettingsState.value("appearance.scheme") || ""
    readonly property real wantContrast: Number(SettingsState.value("appearance.contrast") || 0)
    readonly property bool differs: !!card.current && !!card.current.scheme
        && (card.wantScheme !== card.current.scheme || Math.abs(card.wantContrast - Number(card.current.contrast || 0)) > 0.001)
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    // Aplicando: hasta que el estado cambie (o 15 s si algo falla).
    property bool applying: false
    onCurrentChanged: card.applying = false
    Timer { id: giveUp; interval: 15000; onTriggered: card.applying = false }
    function applyNow(): void {
        card.applying = true;
        giveUp.restart();
        Quickshell.execDetached([card.scriptsDir + "/theme-apply.sh", card.wallpaper, "--source", "settings"]);
    }

    implicitHeight: row.implicitHeight + 2 * Tokens.space.lg

    RowLayout {
        id: row
        x: Tokens.space.lg
        y: Tokens.space.lg
        width: parent.width - 2 * Tokens.space.lg
        spacing: Tokens.space.lg

        ClippingRectangle {
            implicitWidth: Tokens.px(176)
            implicitHeight: Tokens.px(99)
            radius: Tokens.radius.md
            color: Colors.surfaceHigh
            Image {
                anchors.fill: parent
                source: card.wallpaper ? "file://" + card.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: Tokens.px(352)
                asynchronous: true
                cache: false
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.space.xs
            Text {
                text: "Tema actual"
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
            Text {
                Layout.fillWidth: true
                text: card.wallpaper.split("/").pop() || "Ningún tema aplicado todavía"
                elide: Text.ElideMiddle
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.title
                font.weight: Tokens.weight.semibold
            }
            Text {
                visible: !!card.current && !!card.current.scheme
                Layout.fillWidth: true
                text: card.current ? "Aplicado con esquema " + card.model.format("appearance.scheme", card.current.scheme).toLowerCase()
                    + " y contraste " + card.model.format("appearance.contrast", Number(card.current.contrast || 0)).toLowerCase() : ""
                wrapMode: Text.WordWrap
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
            Text {
                visible: !!card.override.scheme
                Layout.fillWidth: true
                text: "Este fondo tiene su propio esquema (" + card.model.format("appearance.scheme", card.override.scheme || "").toLowerCase()
                    + ", elegido en la galería): el de todos los fondos no lo cambia."
                wrapMode: Text.WordWrap
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
            RowLayout {
                Layout.topMargin: Tokens.space.xs
                spacing: Tokens.space.sm
                Button {
                    visible: card.differs
                    activeFocusOnTab: visible
                    main: true
                    icon: card.applying ? "hourglass_top" : "check"
                    label: card.applying ? "Aplicando…" : "Aplicar al tema actual"
                    onClicked: if (!card.applying) card.applyNow()
                }
                Text {
                    visible: !card.differs && !!card.current && !!card.current.scheme
                    text: "El tema actual ya usa estas opciones."
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
                Button {
                    activeFocusOnTab: true
                    icon: "wallpaper"
                    label: "Cambiar fondo"
                    onClicked: Quickshell.execDetached(["qs", "-c", "dotshell", "ipc", "call", "gallery", "open"])
                }
            }
        }
    }
}
