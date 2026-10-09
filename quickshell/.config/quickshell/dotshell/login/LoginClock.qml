// Hora apilada (horas en el acento, minutos en el texto) y chip de la fecha
// (Fase 9 B3). Al cambiar el minuto, los minutos nuevos suben y los viejos se
// van (M7; solo cuando cambia, nada mas se mueve). Sombra suave: va directo
// sobre el wallpaper (legible con fondos claros, B2). QtQuick puro.
import QtQuick
import QtQuick.Effects
import ".." // Colors.qml, Tokens.qml

Column {
    id: clockColumn
    // Cada anfitrion da su reloj: el bloqueo SystemClock, el greeter un Timer.
    property date date: new Date()
    readonly property var es: Qt.locale("es_ES")
    spacing: Tokens.space.xl

    // ---- M7: cambio de minuto ---------------------------------------------------------------
    readonly property string minutes: Qt.formatTime(clockColumn.date, "mm")
    property string shownMinutes: ""
    property string minFrom: ""
    property real minT: 1
    Component.onCompleted: clockColumn.shownMinutes = clockColumn.minutes
    onMinutesChanged: {
        if (clockColumn.shownMinutes === "" || clockColumn.minutes === clockColumn.shownMinutes) {
            clockColumn.shownMinutes = clockColumn.minutes;
            return;
        }
        clockColumn.minFrom = clockColumn.shownMinutes;
        clockColumn.shownMinutes = clockColumn.minutes;
        clockColumn.minT = 0;
        minAnim.restart();
    }
    NumberAnimation {
        id: minAnim
        target: clockColumn
        property: "minT"
        to: 1
        duration: Tokens.motion.medium
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.motion.easeStandard
        onFinished: clockColumn.minFrom = ""
    }

    Column {
        spacing: -Math.round(Tokens.type.lockClock * 0.21)
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Colors.shadow
            shadowOpacity: Tokens.shadow.lg.opacity
            shadowBlur: 1.0
            blurMax: Tokens.shadow.lg.blur
        }
        Text {
            text: Qt.formatTime(clockColumn.date, "HH")
            color: Colors.accent
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.lockClock
            font.weight: Tokens.weight.semibold
            font.letterSpacing: -6
            font.features: Tokens.tabularNumbers
        }
        Item {
            width: minNew.implicitWidth
            height: minNew.implicitHeight
            clip: true
            Text {
                id: minNew
                y: Math.round(height * 0.22 * (1 - clockColumn.minT))
                opacity: clockColumn.minT
                text: clockColumn.shownMinutes
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.lockClock
                font.weight: Tokens.weight.semibold
                font.letterSpacing: -6
                font.features: Tokens.tabularNumbers
            }
            Text {
                visible: clockColumn.minFrom !== ""
                y: -Math.round(height * 0.22 * clockColumn.minT)
                opacity: Math.max(0, 1 - 2 * clockColumn.minT)
                text: clockColumn.minFrom
                color: Colors.text
                font: minNew.font
            }
        }
    }
    Rectangle {
        width: dateText.implicitWidth + 2 * Tokens.space.xl
        height: Tokens.px(52)
        radius: Tokens.radius.pill(height)
        color: Colors.accentContainer
        Text {
            id: dateText
            anchors.centerIn: parent
            text: {
                const d = clockColumn.es.standaloneDayName(clockColumn.date.getDay(), Locale.LongFormat);
                return d.charAt(0).toUpperCase() + d.slice(1) + ", " + clockColumn.date.getDate() + " de "
                    + clockColumn.es.standaloneMonthName(clockColumn.date.getMonth(), Locale.LongFormat);
            }
            color: Colors.textOnAccentContainer
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.title
            font.weight: Tokens.weight.semibold
        }
    }
}
