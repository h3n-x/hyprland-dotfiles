// Estado general del equipo en Inicio (Fase 4 B7): una frase ("Todo en
// orden", "Memoria casi llena"...) con un punto del color de su gravedad y
// cuatro medidores finos. El detalle vive en la vista Sistema; aca solo lo
// necesario para saber si hay que mirar. Datos: SystemState (solo se lee con
// el dashboard abierto).
//
// Movimiento (StatusLine, LevelBar): la frase se funde al cambiar y el punto
// cambia de color; un medidor se desliza solo si su valor cambia de verdad.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, SystemState.qml

ColumnLayout {
    id: glance
    // Medidores en una fila (dashboard angosto) o en dos.
    property bool wide: false
    spacing: Tokens.space.sm

    function levelColor(level: int): color {
        return level >= 2 ? Colors.m3error : level === 1 ? Colors.m3tertiary : Colors.m3primary;
    }

    component Meter: ColumnLayout {
        id: meter
        property string label
        property string value
        property real fraction
        property int level: 0
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: meter.label
                color: Colors.m3onSurfaceVariant
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
            }
            Text {
                text: meter.value
                color: meter.level > 0 ? glance.levelColor(meter.level) : Colors.m3onSurface
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.weight: Tokens.weight.semibold
                font.features: Tokens.tabularNumbers
            }
        }
        LevelBar {
            Layout.fillWidth: true
            fraction: meter.fraction
            level: meter.level
        }
    }

    ZoneTitle {
        Layout.fillWidth: true
        text: "Sistema"
        opens: true
    }
    StatusLine {
        Layout.fillWidth: true
    }

    Item { Layout.fillHeight: true }

    GridLayout {
        Layout.fillWidth: true
        columns: glance.wide ? 4 : 2
        columnSpacing: Tokens.space.lg
        rowSpacing: Tokens.space.sm
        Meter {
            Layout.fillWidth: true
            label: "CPU"
            value: Math.round(SystemState.cpu * 100) + " %"
            fraction: SystemState.cpu
            level: SystemState.cpuHighCount >= 3 ? 1 : 0
        }
        Meter {
            Layout.fillWidth: true
            label: "Memoria"
            value: Math.round(SystemState.memFrac * 100) + " %"
            fraction: SystemState.memFrac
            level: SystemState.memFrac >= 0.92 ? 1 : 0
        }
        Meter {
            Layout.fillWidth: true
            visible: !isNaN(SystemState.temp)
            label: "Temperatura"
            value: Math.round(SystemState.temp) + "°"
            fraction: SystemState.temp / 100
            level: SystemState.temp >= 95 ? 2 : SystemState.temp >= 88 ? 1 : 0
        }
        Meter {
            Layout.fillWidth: true
            visible: SystemState.hasBattery
            label: SystemState.charging ? "Batería · cargando" : "Batería"
            value: Math.round(SystemState.batteryPct * 100) + " %"
            fraction: SystemState.batteryPct
            level: SystemState.batteryCritical ? 2 : SystemState.batteryWarning ? 1 : 0
        }
    }
}
