// Recursos en la barra (Fase 11 B2b; no esta en la barra de fabrica): CPU,
// memoria y temperatura (las que elijas: bar.resources.cpu/mem/temp) de SystemState.
// Solo pide muestras mientras esta en la barra (Subscription a la demanda
// "basic"; el intervalo es system.sampleSeconds). Por encima del umbral, el
// valor va en el color fijo de advertencia (un estado, principio 23).
import QtQuick
import ".." // Colors.qml, Tokens.qml, SystemState.qml, Subscription.qml

Item {
    id: root
    readonly property var show: ["cpu", "mem", "temp"].filter(k => SettingsState.value("bar.resources." + k) === true)
    readonly property int warnPct: SettingsState.value("bar.resources.warnPct") || 90
    readonly property bool shown: root.show.length > 0
    visible: shown
    // Texto para la informacion al pasar el raton (Fase 11 B2b).
    readonly property string tooltip: I18n.tr("CPU %1 % · memory %2 of %3", Math.round(SystemState.cpu * 100), I18n.bytes(SystemState.memUsed), I18n.bytes(SystemState.memTotal))
        + (isNaN(SystemState.temp) ? "" : " · " + I18n.tr("%1 °C", Math.round(SystemState.temp)))

    Subscription { demand: SystemState.basic; active: true }
    TextMetrics { id: wide; text: "100%"; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.features: { "tnum": 1 } }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    BarFlow {
        id: row
        spacing: Tokens.space.md
        Repeater {
            model: root.show
            BarFlow {
                id: cell
                required property string modelData
                readonly property real pct: cell.modelData === "cpu" ? SystemState.cpu * 100
                    : cell.modelData === "mem" ? SystemState.memFrac * 100 : SystemState.temp
                readonly property bool hot: cell.modelData === "temp" ? cell.pct >= 85 : cell.pct >= root.warnPct
                spacing: Tokens.space.xs
                visible: !(cell.modelData === "temp" && isNaN(SystemState.temp))
                Icon {
                    name: ({ "cpu": "memory", "mem": "memory_alt", "temp": "device_thermostat" })[cell.modelData] || "help"
                    size: Tokens.icon.sm
                    color: cell.hot ? Colors.warning : Colors.textMuted
                }
                Text {
                    // Ancho fijo ("100%"): el numero cambia sin mover lo de al lado.
                    width: Tokens.bar.vertical ? implicitWidth : Math.max(implicitWidth, wide.width)
                    horizontalAlignment: Text.AlignRight
                    text: isNaN(cell.pct) ? "–" : Math.round(cell.pct) + (cell.modelData === "temp" ? "°" : "%")
                    color: cell.hot ? Colors.warning : Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.bar.vertical ? Tokens.type.caption : Tokens.type.label
                    font.features: { "tnum": 1 }
                }
            }
        }
    }
}
