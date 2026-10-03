// Reloj de la barra (Fase 4 B6): icono de reloj (identidad del modulo, como
// el icono de estado de la pill multimedia; fijo: el dia/noche ya lo dice el
// icono del clima), la hora (24 h) y, con una ubicacion
// configurada, el clima compacto (icono + temperatura, atenuado si los datos
// son viejos o no se pudo actualizar). Solo informa: sin accion al clic (el
// dashboard se abre unicamente con SUPER+A, Fase 4 B7). SystemClock evita un
// proceso "date".
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, WeatherState.qml

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property var cur: WeatherState.current
    readonly property bool showWeather: WeatherState.configured && !!root.cur
    readonly property bool weatherDim: root.showWeather && WeatherState.isDim(clock.date.getTime() / 1000)

    RowLayout {
        id: row
        spacing: Tokens.space.sm

        Icon {
            Layout.alignment: Qt.AlignVCenter
            name: "schedule"
            size: Tokens.icon.sm
            color: Colors.textMuted
        }
        Text {
            Layout.alignment: Qt.AlignVCenter
            color: Colors.text
            font.family: Tokens.font.ui
            // type.title (D2): el reloj recupera el enfasis con tamano, no con un Bold.
            font.pixelSize: Tokens.type.title
            font.weight: Tokens.weight.semibold
            font.features: Tokens.tabularNumbers
            text: Qt.formatTime(clock.date, "HH:mm")
        }
        Row {
            visible: root.showWeather
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.space.xs
            opacity: root.weatherDim ? 0.55 : 1
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.cur ? WeatherText.describe(root.cur.weather_code, root.cur.is_day === 1).icon : ""
                size: Tokens.icon.sm
                color: Colors.textMuted
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.cur ? WeatherState.temp(root.cur.temperature_2m) : ""
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
                font.features: Tokens.tabularNumbers
            }
        }
    }
}
