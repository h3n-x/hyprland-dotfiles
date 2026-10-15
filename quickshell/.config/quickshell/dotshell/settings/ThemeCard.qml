// Tema actual, arriba de "Color" en Apariencia (Fase 10 B2): el wallpaper
// aplicado y con que esquema, contraste y modo se aplico (el modo, P5.5, se
// aplica al elegirlo: no espera a "Aplicar al tema actual"). Esquema y contraste se
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
                text: I18n.tr("Current theme")
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
            Text {
                Layout.fillWidth: true
                text: card.wallpaper.split("/").pop() || I18n.tr("No theme applied yet")
                elide: Text.ElideMiddle
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.title
                font.weight: Tokens.weight.semibold
            }
            Text {
                visible: !!card.current && !!card.current.scheme
                Layout.fillWidth: true
                text: card.current ? I18n.tr("Applied with the %1 scheme, %2 contrast and %3 mode", card.model.format("appearance.scheme", card.current.scheme).toLowerCase(),
                    card.model.format("appearance.contrast", Number(card.current.contrast || 0)).toLowerCase(),
                    card.current.mode === "light" ? I18n.trc("mode", "light") : I18n.trc("mode", "dark")) : ""
                wrapMode: Text.WordWrap
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
            Text {
                visible: !!card.override.scheme
                Layout.fillWidth: true
                text: I18n.tr("This wallpaper has its own scheme (%1, chosen in the gallery): the one for every wallpaper doesn't change it.",
                    card.model.format("appearance.scheme", card.override.scheme || "").toLowerCase())
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
                    label: card.applying ? I18n.tr("Applying…") : I18n.tr("Apply to the current theme")
                    onClicked: if (!card.applying) card.applyNow()
                }
                Text {
                    visible: !card.differs && !!card.current && !!card.current.scheme
                    text: I18n.tr("The current theme already uses these options.")
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
                Button {
                    activeFocusOnTab: true
                    icon: "wallpaper"
                    label: I18n.tr("Change wallpaper")
                    onClicked: Quickshell.execDetached(["qs", "-c", "dotshell", "ipc", "call", "gallery", "open"])
                }
            }
        }
    }
}
