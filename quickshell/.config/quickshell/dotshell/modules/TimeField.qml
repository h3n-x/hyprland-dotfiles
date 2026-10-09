// Hora del dia HH:MM (Fase 10 B5, luz nocturna): dos Stepper, horas (0-23) y
// minutos de 5 en 5. No guarda estado: el consumidor da `value` y recibe
// edited("HH:MM"). Una hora que no cae en 5 minutos se muestra redondeada.
//
//   TimeField { value: "20:00"; onEdited: v => x = v }
import QtQuick
import ".." // Colors.qml, Tokens.qml

Row {
    id: root

    property string value: "00:00"
    signal edited(string value)

    readonly property int hours: parseInt(root.value.split(":")[0]) || 0
    readonly property int minutes: parseInt(root.value.split(":")[1]) || 0
    function pad(n: int): string {
        return (n < 10 ? "0" : "") + n;
    }
    readonly property var hourLabels: {
        const o = {};
        for (let h = 0; h < 24; h++) o[String(h)] = root.pad(h);
        return o;
    }
    readonly property var minuteLabels: {
        const o = {};
        for (let i = 0; i < 12; i++) o[String(i)] = root.pad(i * 5);
        return o;
    }

    spacing: Tokens.space.xs

    Stepper {
        objectName: "time-hours"
        from: 0
        to: 23
        value: root.hours
        labels: root.hourLabels
        onMoved: (v) => root.edited(root.pad(v) + ":" + root.pad(root.minutes))
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: ":"
        color: Colors.textMuted
        font.family: Tokens.font.ui
        font.pixelSize: Tokens.type.body
    }
    Stepper {
        objectName: "time-minutes"
        from: 0
        to: 11
        value: Math.min(11, Math.round(root.minutes / 5))   // indice del menu, no pixeles (px-ok)
        labels: root.minuteLabels
        onMoved: (v) => root.edited(root.pad(root.hours) + ":" + root.pad(v * 5))
    }
}
