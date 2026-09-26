// Vista Hoy del dashboard (Fase 4 B7): el calendario del mes y el clima, lado
// a lado (angosto: uno sobre otro). La fecha completa y de cuando son los
// datos estan en la cabecera de la vista; aca, solo lo util.
//
// Teclado (Dashboard.qml le pasa las teclas): izquierda/derecha cambian de
// mes, Inicio vuelve al actual, C cambia la ubicacion, R reintenta.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml

GridLayout {
    id: view
    property bool active: false
    property bool narrow: false
    signal backRequested()
    signal leftSearch()
    columns: view.narrow ? 1 : 2
    columnSpacing: Tokens.space.md
    rowSpacing: Tokens.space.md

    function handleKey(event: var): bool {
        if (event.key === Qt.Key_Left) { calendar.step(-1); return true; }
        if (event.key === Qt.Key_Right) { calendar.step(1); return true; }
        if (event.key === Qt.Key_Home) { calendar.goToday(); return true; }
        return weather.handleKey(event);
    }

    DashZone {
        Layout.alignment: Qt.AlignTop | (view.narrow ? Qt.AlignHCenter : Qt.AlignLeft)
        implicitWidth: calendar.implicitWidth + 2 * padding
        implicitHeight: calendar.implicitHeight + 2 * padding
        CalendarMonth {
            id: calendar
            active: view.active
        }
    }
    WeatherView {
        id: weather
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        active: view.active
        onBackRequested: view.backRequested()
        onPickingChanged: if (!picking) view.leftSearch()
    }
}
