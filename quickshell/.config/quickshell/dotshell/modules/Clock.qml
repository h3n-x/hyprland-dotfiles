// Reloj de la barra (Fase 4 B6): icono de reloj (identidad del modulo, como
// el icono de estado de la pill multimedia; fijo: el dia/noche ya lo dice el
// icono del clima), la hora (24 h) y, con una ubicacion
// configurada, el clima compacto (icono + temperatura, atenuado si los datos
// son viejos o no se pudo actualizar). Clic: abre el panel del reloj
// (calendario + clima; dashboard en B7). La fecha ya no se alterna aca: esta
// en el panel, siempre en espanol. SystemClock evita un proceso "date".
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, WeatherState.qml, DashboardState.qml

Item {
    id: root
    // Barra que contiene el reloj (para anclar el panel).
    property var panelWindow: null

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property var cur: WeatherState.data ? WeatherState.data.current : null
    readonly property bool showWeather: WeatherState.configured && !!root.cur
    // Datos viejos (> 60 min) o ultimo intento fallido: atenuado, no oculto.
    readonly property bool weatherDim: root.showWeather
        && (!!WeatherState.lastError || clock.date.getTime() / 1000 - WeatherState.fetchedAt > 3600)

    RowLayout {
        id: row
        spacing: Tokens.space.sm

        Icon {
            Layout.alignment: Qt.AlignVCenter
            name: "schedule"
            size: Tokens.icon.sm
            color: Colors.m3onSurfaceVariant
        }
        Text {
            Layout.alignment: Qt.AlignVCenter
            color: Colors.m3onSurface
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
                name: root.cur ? WeatherState.describe(root.cur.weather_code, root.cur.is_day === 1).icon : ""
                size: Tokens.icon.sm
                color: Colors.m3onSurfaceVariant
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.cur ? WeatherState.temp(root.cur.temperature_2m) : ""
                color: Colors.m3onSurfaceVariant
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
                font.features: Tokens.tabularNumbers
            }
        }
    }

    // Accion unica: la Pill que lo contiene se ilumina entera (Bar.qml, Q2 = A).
    readonly property bool hovered: hoverArea.containsMouse
    readonly property bool pressed: hoverArea.pressed

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.panelWindow && root.panelWindow.screen) DashboardState.toggle(root.panelWindow.screen.name)
    }

    ClockPanel {
        anchorItem: root.parent ? root.parent : root
        panelWindow: root.panelWindow
    }
}
