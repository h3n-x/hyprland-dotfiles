// Panel del reloj (Fase 4 B6): calendario y clima bajo el reloj de la barra.
// Es la base del dashboard de B7: el mismo DropdownPanel y las mismas
// tarjetas (CalendarCard, WeatherCard); B7 agrega tarjetas a esta fila, no la
// rehace. Abierto/cerrado en DashboardState. Teclas: izquierda/derecha
// cambian de mes, Esc cierra.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, DashboardState.qml

DropdownPanel {
    id: panel
    alignment: "center"
    open: DashboardState.visible && !!panel.panelWindow && !!panel.panelWindow.screen
        && DashboardState.screen === panel.panelWindow.screen.name
    onCloseRequested: DashboardState.close()
    keyHandler: (event) => {
        if (event.key === Qt.Key_Left) { calendar.step(-1); return true; }
        if (event.key === Qt.Key_Right) { calendar.step(1); return true; }
        return false;
    }

    RowLayout {
        spacing: Tokens.space.xl

        CalendarCard {
            id: calendar
            Layout.alignment: Qt.AlignTop
            active: panel.active
        }
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Colors.m3outlineVariant
        }
        WeatherCard {
            Layout.alignment: Qt.AlignTop
            active: panel.active
            onCloseRequested: DashboardState.close()
            onPickingChanged: if (!picking) panel.focusPanel()
        }
    }
}
