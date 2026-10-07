// Velocidad de la red en la barra (Fase 11 B2b; no esta en la barra de
// fabrica): bajada y subida de /proc/net/dev. Solo pide muestras mientras esta
// en la barra (Subscription a la demanda liviana "net" de SystemState).
import QtQuick
import ".." // Colors.qml, Tokens.qml, SystemState.qml, Subscription.qml

Item {
    id: root
    readonly property bool shown: true
    visible: shown
    readonly property string tooltip: "Bajada " + SystemState.rate(SystemState.rxRate) + " · subida " + SystemState.rate(SystemState.txRate)

    Subscription { demand: SystemState.net; active: true }
    TextMetrics { id: wide; text: "999 kB/s"; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.features: { "tnum": 1 } }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: Tokens.space.sm
        Repeater {
            model: [["arrow_downward", SystemState.rxRate], ["arrow_upward", SystemState.txRate]]
            Row {
                required property var modelData
                spacing: Tokens.space.hair
                Icon { anchors.verticalCenter: parent.verticalCenter; name: parent.modelData[0]; size: Tokens.icon.sm; color: Colors.textMuted }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    // Ancho fijo ("999 kB/s"): la cifra cambia sin mover lo de al lado.
                    width: Math.max(implicitWidth, wide.width)
                    horizontalAlignment: Text.AlignRight
                    text: SystemState.rate(parent.modelData[1])
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                    font.features: { "tnum": 1 }
                }
            }
        }
    }
}
