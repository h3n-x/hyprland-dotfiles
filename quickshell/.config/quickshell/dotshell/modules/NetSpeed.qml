// Velocidad de la red en la barra (Fase 11 B2b; no esta en la barra de
// fabrica): bajada y subida de /proc/net/dev. Solo pide muestras mientras esta
// en la barra (Subscription a la demanda liviana "net" de SystemState).
import QtQuick
import ".." // Colors.qml, Tokens.qml, SystemState.qml, Subscription.qml

Item {
    id: root
    readonly property bool shown: true
    visible: shown
    readonly property string tooltip: I18n.tr("Down %1 · up %2", SystemState.rate(SystemState.rxRate), SystemState.rate(SystemState.txRate))

    Subscription { demand: SystemState.net; active: true }
    // A un costado (Fase 11 B3) no entra "999 kB/s": "73k", "1,2M".
    function compact(bps: real): string {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1).replace(".", ",") + "M";
        if (bps >= 1024) return Math.round(bps / 1024) + "k";
        return Math.round(bps) + "";
    }
    TextMetrics { id: wide; text: I18n.tr("%1 kB/s", "999"); font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.features: { "tnum": 1 } }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    BarFlow {
        id: row
        spacing: Tokens.space.sm
        Repeater {
            model: [["arrow_downward", SystemState.rxRate], ["arrow_upward", SystemState.txRate]]
            BarFlow {
                required property var modelData
                spacing: Tokens.space.hair
                Icon { name: parent.modelData[0]; size: Tokens.icon.sm; color: Colors.textMuted }
                Text {
                    // Ancho fijo ("999 kB/s"): la cifra cambia sin mover lo de al lado.
                    width: Tokens.bar.vertical ? implicitWidth : Math.max(implicitWidth, wide.width)
                    horizontalAlignment: Text.AlignRight
                    text: Tokens.bar.vertical ? root.compact(parent.modelData[1]) : SystemState.rate(parent.modelData[1])
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.bar.vertical ? Tokens.type.caption : Tokens.type.label
                    font.features: { "tnum": 1 }
                }
            }
        }
    }
}
