// Reloj de la barra (Fase 4 B6): icono de reloj (identidad del modulo, como
// el icono de estado de la pill multimedia; fijo: el dia/noche ya lo dice el
// icono del clima), la hora (24 o 12 h, bar.clock.format; la fecha delante con
// bar.clock.date, Fase 10 B4) y, con una ubicacion
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

    // Texto de la informacion al pasar el raton (bar.tooltips, Fase 11 B2b).
    readonly property string tooltip: I18n.date(clock.date, "dddd, MMMM d, yyyy")
        + (root.showWeather ? " · " + WeatherText.describe(root.cur.weather_code, root.cur.is_day === 1).text : "")
    // 12 h: la hora sale del formato con AP (sin AP, Qt da 0-23 aunque se pida "h"; Fase 16 B2).
    readonly property bool h12: SettingsState.value("bar.clock.format") === "12"
    readonly property bool showDate: SettingsState.value("bar.clock.date") === true
    readonly property string ap: root.h12 ? clock.date.toLocaleTimeString(I18n.locale, "AP") : ""
    readonly property var cur: WeatherState.current
    readonly property bool showWeather: WeatherState.configured && !!root.cur
    readonly property bool weatherDim: root.showWeather && WeatherState.isDim(clock.date.getTime() / 1000)

    GridLayout {
        id: row
        // Fila o columna segun la barra (Fase 11 B3).
        flow: Tokens.bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: Tokens.bar.vertical ? -1 : 1
        columns: Tokens.bar.vertical ? 1 : -1
        rowSpacing: Tokens.space.sm
        columnSpacing: Tokens.space.sm

        // A un costado (Fase 11 B3) no hay lugar para el icono; la hora va en dos
        // lineas, con la fecha apilada arriba y la marca de 12 h abajo (Fase 16 B2).
        Icon {
            visible: !Tokens.bar.vertical
            Layout.alignment: Qt.AlignCenter
            name: "schedule"
            size: Tokens.icon.sm
            color: Colors.textMuted
        }
        // A un costado, la fecha va arriba apilada (dia de la semana y numero).
        ColumnLayout {
            visible: root.showDate && Tokens.bar.vertical
            Layout.alignment: Qt.AlignCenter
            spacing: 0
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: I18n.dayName(clock.date.getDay(), true)
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: I18n.number(clock.date.getDate())
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
                font.weight: Tokens.weight.semibold
                font.features: Tokens.tabularNumbers
            }
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            color: Colors.text
            font.family: Tokens.font.ui
            // type.title (D2): el reloj recupera el enfasis con tamano, no con un Bold.
            font.pixelSize: Tokens.type.title
            font.weight: Tokens.weight.semibold
            font.features: Tokens.tabularNumbers
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 0.9
            text: !Tokens.bar.vertical ? clock.date.toLocaleTimeString(I18n.locale, root.h12 ? "h:mm AP" : "HH:mm")
                : (root.h12 ? clock.date.toLocaleTimeString(I18n.locale, "h AP").replace(root.ap, "").trim() : clock.date.toLocaleTimeString(I18n.locale, "HH"))
                  + "\n" + clock.date.toLocaleTimeString(I18n.locale, "mm")
        }
        // A un costado, en 12 h, la marca de la manana o la tarde en su propia linea.
        Text {
            visible: root.h12 && Tokens.bar.vertical
            Layout.alignment: Qt.AlignCenter
            text: root.ap.toLowerCase()
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
        }
        Text {
            visible: root.showDate && !Tokens.bar.vertical
            Layout.alignment: Qt.AlignCenter
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
            text: I18n.trc("weekday and day of the month", "%1 %2", I18n.dayName(clock.date.getDay(), true), clock.date.getDate())
        }
        BarFlow {
            visible: root.showWeather
            Layout.alignment: Qt.AlignCenter
            spacing: Tokens.bar.vertical ? 0 : Tokens.space.xs
            opacity: root.weatherDim ? 0.55 : 1
            Icon {
                name: root.cur ? WeatherText.describe(root.cur.weather_code, root.cur.is_day === 1).icon : ""
                size: Tokens.icon.sm
                color: Colors.textMuted
            }
            Text {
                text: root.cur ? WeatherState.temp(root.cur.temperature_2m) : ""
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
                font.features: Tokens.tabularNumbers
            }
        }
    }
}
