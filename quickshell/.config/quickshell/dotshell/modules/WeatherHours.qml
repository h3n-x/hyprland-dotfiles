// Las proximas horas del clima (Fase 4 B7; Fase 11 B4 la comparten la vista Hoy
// y la zona "Proximas horas" de Inicio): hora, icono, temperatura y la lluvia
// solo si es probable. "count" recorta (una zona chica muestra menos horas).
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, WeatherState.qml

RowLayout {
    id: strip
    property int count: 6
    readonly property var hours: WeatherState.hours.slice(0, Math.max(1, strip.count))
    spacing: 0
    Repeater {
        model: strip.hours
        ColumnLayout {
            required property var modelData
            Layout.preferredWidth: strip.width / Math.max(1, strip.hours.length)
            spacing: 3
            Text { Layout.alignment: Qt.AlignHCenter; text: modelData.label; color: Colors.border; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; font.features: Tokens.tabularNumbers }
            Icon { Layout.alignment: Qt.AlignHCenter; name: WeatherText.describe(modelData.code, modelData.day).icon; size: Tokens.icon.lg; color: Colors.textMuted }
            Text { Layout.alignment: Qt.AlignHCenter; text: WeatherState.temp(modelData.t); color: Colors.text; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.body; font.weight: Tokens.weight.medium; font.features: Tokens.tabularNumbers }
            // Lluvia: solo si es probable.
            Text { Layout.alignment: Qt.AlignHCenter; text: modelData.rain >= 30 ? modelData.rain + " %" : " "; color: Colors.decor; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; font.features: Tokens.tabularNumbers }
        }
    }
}
