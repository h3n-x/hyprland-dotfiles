// Menu de la bateria (Fase 14 B1): lo abre el clic en la pill de bateria de la
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
    readonly property string stateText: BatteryState.full ? "Cargada"
        : BatteryState.charging ? "Cargando"
        : BatteryState.onAc ? "Enchufada" : "Con batería"
    readonly property string timeText: BatteryState.secondsLeft <= 0 ? ""
        : SystemState.duration(BatteryState.secondsLeft) + (BatteryState.charging ? " para llenarse" : " restantes")
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
                text: Math.round(BatteryState.pct * 100) + " %"
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
                text: BatteryState.charging ? "Carga" : "Consumo"
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
            Text {
                visible: BatteryState.watts > 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: BatteryState.watts.toFixed(1) + " W"
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.features: Tokens.tabularNumbers
            }
            Text {
                visible: BatteryState.health >= 0
                text: "Salud"
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
            }
            Text {
                visible: BatteryState.health >= 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: Math.round(BatteryState.health * 100) + " % de la capacidad original"
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
                text: "Perfil de energía"
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
            label: "Configuración de energía"
            onClicked: {
                popup.close();
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/settings-ui", "open", "system.battery.warnPct"]);
            }
        }
    }
}
