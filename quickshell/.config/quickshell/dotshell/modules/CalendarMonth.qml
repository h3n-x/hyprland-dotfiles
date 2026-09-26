// Calendario del mes (Fase 4 B6, P4.6; vista Hoy del dashboard en B7): mes
// con navegacion (flechas, rueda del mouse, izquierda/derecha con el teclado)
// y "Hoy" cuando se mira otro mes. La fecha completa esta en la cabecera de
// la vista. Solo visualizacion (eventos: funcion futura aparte). Siempre en
// espanol, lunes primero, sin depender del locale del sistema.
//
// "active" (de la vista que lo contiene): solo mientras se ve se actualiza la
// fecha (medianoche) -- cerrado no corre nada.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, WeatherState.qml (cap, es)

Item {
    id: card
    property bool active: true
    readonly property var es: Qt.locale("es_ES")
    property int cell: 40

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    SystemClock {
        id: clock
        enabled: card.active
        precision: SystemClock.Hours
    }
    readonly property date today: clock.date
    property int month: card.today.getMonth()
    property int year: card.today.getFullYear()
    // Se mira el mes actual. No llamarla "onToday": junto a "today" QML la
    // toma como manejador de senal (regla del repo: nunca onX al lado de X).
    readonly property bool viewingToday: card.month === card.today.getMonth() && card.year === card.today.getFullYear()

    // Al abrir, volver al mes actual.
    onActiveChanged: if (card.active) card.goToday()
    function goToday(): void {
        card.month = card.today.getMonth();
        card.year = card.today.getFullYear();
    }
    function step(delta: int): void {
        const d = new Date(card.year, card.month + delta, 1);
        card.month = d.getMonth();
        card.year = d.getFullYear();
    }

    component NavButton: Rectangle {
        id: nav
        property string icon
        signal clicked()
        implicitWidth: 32
        implicitHeight: 32
        radius: width / 2
        color: "transparent"
        StateLayer { hovered: navMouse.containsMouse; pressed: navMouse.pressed }
        Icon { anchors.centerIn: parent; name: nav.icon; size: Tokens.icon.md; color: Colors.m3onSurfaceVariant }
        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }

    ColumnLayout {
        id: col
        spacing: Tokens.space.sm

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.space.xs
            Text {
                Layout.fillWidth: true
                text: WeatherState.cap(card.es.standaloneMonthName(card.month, Locale.LongFormat)) + " " + card.year
                color: Colors.m3onSurface
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.title
                font.weight: Tokens.weight.semibold
            }
            // "Hoy": solo si se esta mirando otro mes.
            Rectangle {
                visible: !card.viewingToday
                implicitHeight: 28
                implicitWidth: todayRow.implicitWidth + Tokens.space.md * 2
                radius: Tokens.radius.sm
                color: "transparent"
                border.width: 1
                border.color: Colors.m3outlineVariant
                StateLayer { hovered: todayMouse.containsMouse; pressed: todayMouse.pressed }
                Row {
                    id: todayRow
                    anchors.centerIn: parent
                    spacing: Tokens.space.xs
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "today"; size: Tokens.icon.sm; color: Colors.m3onSurfaceVariant }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Hoy"; color: Colors.m3onSurfaceVariant; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label }
                }
                MouseArea {
                    id: todayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.goToday()
                }
            }
            NavButton { icon: "chevron_left"; onClicked: card.step(-1) }
            NavButton { icon: "chevron_right"; onClicked: card.step(1) }
        }

        DayOfWeekRow {
            locale: card.es
            Layout.preferredWidth: 7 * card.cell
            delegate: Text {
                required property var model
                text: WeatherState.cap(model.shortName.replace(".", "")).slice(0, 2)
                horizontalAlignment: Text.AlignHCenter
                color: Colors.m3outline
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                font.weight: Tokens.weight.medium
            }
        }

        MonthGrid {
            id: grid
            locale: card.es
            month: card.month
            year: card.year
            spacing: 0
            Layout.preferredWidth: 7 * card.cell
            Layout.preferredHeight: 6 * (card.cell - 2)
            delegate: Item {
                id: day
                required property var model
                readonly property bool isToday: day.model.day === card.today.getDate()
                    && day.model.month === card.today.getMonth() && day.model.year === card.today.getFullYear()
                readonly property bool inMonth: day.model.month === card.month
                implicitWidth: card.cell
                implicitHeight: card.cell - 2
                Rectangle {
                    anchors.centerIn: parent
                    width: card.cell - 6
                    height: card.cell - 6
                    radius: width / 2
                    visible: day.isToday
                    color: Colors.m3primary
                }
                Text {
                    anchors.centerIn: parent
                    text: day.model.day
                    color: day.isToday ? Colors.m3onPrimary : (day.inMonth ? Colors.m3onSurface : Colors.m3outline)
                    opacity: day.inMonth || day.isToday ? 1 : 0.6
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                    font.weight: day.isToday ? Tokens.weight.semibold : Tokens.weight.regular
                    font.features: Tokens.tabularNumbers
                }
            }
            // Rueda: mes anterior / siguiente.
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: (event) => card.step(event.angleDelta.y > 0 ? -1 : 1)
            }
        }
    }
}
