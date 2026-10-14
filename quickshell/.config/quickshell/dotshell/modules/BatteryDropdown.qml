// Menu de la bateria (Fase 14 B1; textos traducibles, Fase 15 B1): lo abre el clic en la pill de bateria de la
// barra (antes abria el centro de control). Nivel grande, estado y tiempo
// restante, consumo y salud si UPower los informa, el perfil de energia
// (ProfileRow, el mismo del centro de control) y un enlace a la configuracion.
// Todo de BatteryState (UPower, por eventos): abierto no consulta nada.
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, BatteryState.qml, SystemState.qml, QuickTiles.qml

AnchoredPanel {
    id: popup
    popupId: "battery"
    align: "end"
    padding: Tokens.pad.card

    readonly property int contentWidth: Tokens.panel.widthMd - 2 * Tokens.pad.card
    readonly property string stateText: BatteryState.full ? I18n.tr("Charged")
        : BatteryState.charging ? I18n.tr("Charging")
        : BatteryState.onAc ? I18n.tr("Plugged in") : I18n.tr("On battery")
    readonly property string timeText: BatteryState.secondsLeft <= 0 ? ""
        : BatteryState.charging ? I18n.tr("%1 to full", I18n.duration(BatteryState.secondsLeft))
        : I18n.tr("%1 left", I18n.duration(BatteryState.secondsLeft))
    // Gravedad de la barra (LevelBar): critico = danger, aviso = warning (fijos, P8.7).
    readonly property int level: BatteryState.critical ? 2 : BatteryState.warning ? 1 : 0

    onActiveChanged: if (popup.active) QuickTiles.refresh()

    ColumnLayout {
        width: popup.contentWidth
        spacing: Tokens.space.md

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.space.xs
            Layout.rightMargin: Tokens.space.xs
            spacing: Tokens.space.md

            Text {
                text: I18n.tr("%1 %", Math.round(BatteryState.pct * 100))
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.displayLarge
                font.weight: Tokens.weight.semibold
                font.features: Tokens.tabularNumbers
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: popup.stateText
                    color: popup.level === 2 ? Colors.danger : popup.level === 1 ? Colors.warning
                        : BatteryState.charging ? Colors.success : Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.title
                    font.weight: Tokens.weight.semibold
                }
                Text {
                    visible: popup.timeText !== ""
                    Layout.fillWidth: true
                    text: popup.timeText
                    elide: Text.ElideRight
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
            }
        }

        LevelBar {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.space.xs
            Layout.rightMargin: Tokens.space.xs
            fraction: BatteryState.pct
            level: popup.level
        }

        // Datos que UPower puede no informar: solo los que hay.
        GridLayout {
            visible: BatteryState.watts > 0 || BatteryState.health >= 0
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.space.xs
            Layout.rightMargin: Tokens.space.xs
            columns: 2
            columnSpacing: Tokens.space.md
            rowSpacing: Tokens.space.xs

            Text {
                visible: BatteryState.watts > 0
                text: BatteryState.charging ? I18n.tr("Input power") : I18n.tr("Power draw")
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
            Text {
                visible: BatteryState.watts > 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: I18n.tr("%1 W", I18n.number(BatteryState.watts, 1))
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.features: Tokens.tabularNumbers
            }
            Text {
                visible: BatteryState.health >= 0
                text: I18n.tr("Health")
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
            Text {
                visible: BatteryState.health >= 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: I18n.tr("%1 % of the original capacity", Math.round(BatteryState.health * 100))
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
        }

        // Perfil de energia (power-profiles-daemon), si esta instalado.
        ColumnLayout {
            visible: QuickTiles.hasProfiles
            Layout.fillWidth: true
            spacing: Tokens.space.xs
            Text {
                Layout.leftMargin: Tokens.space.xs
                text: I18n.tr("Power profile")
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                font.weight: Tokens.weight.medium
            }
            ProfileRow {
                Layout.fillWidth: true
            }
        }

        Button {
            Layout.alignment: Qt.AlignRight
            icon: "settings"
            label: I18n.tr("Power settings")
            onClicked: {
                popup.close();
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/settings-ui", "open", "system.battery.warnPct"]);
            }
        }
    }
}
