// Zona Ahora de Inicio (Fase 11 B5b, P11.6): una linea con lo mas relevante
// del momento (NowState: temporizador, lluvia cerca, tareas, calor o helada,
// la puesta de sol). Clic: la vista de lo que muestra (Hoy para el clima).
// Sin nada que mostrar, HomeZones no le da lugar (needs "now").
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, NowState.qml, TimerState.qml, DashboardState.qml

Item {
    id: root
    property bool active: false
    property bool wide: false
    readonly property var item: NowState.item
    readonly property real ideal: row.implicitHeight

    // Los minutos de un temporizador avanzan solo con la zona a la vista (la
    // hora de NowState la pide HomeZones: tambien cuando la zona esta oculta).
    // (Depende de "algo corre", no de lo que Ahora muestra: eso cambia con cada minuto.)
    Subscription { demand: TimerState.minutes; active: root.active && TimerState.anyRunning && NowState.kinds.indexOf("timer") >= 0 }

    function focusField(): void {
        if (root.item && root.item.view) DashboardState.showTab(root.item.view, "zone");
    }

    MouseArea {
        anchors.fill: parent
        enabled: !!root.item && !!root.item.view
        cursorShape: Qt.PointingHandCursor
        onClicked: root.focusField()
    }
    RowLayout {
        id: row
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.space.md
        Rectangle {
            implicitWidth: Tokens.px(44)
            implicitHeight: Tokens.px(44)
            radius: Tokens.radius.md
            color: Colors.accentAltContainer
            Icon {
                anchors.centerIn: parent
                name: root.item ? root.item.icon : "bolt"
                size: Tokens.icon.lg
                color: Colors.textOnAccentAltContainer
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.item ? root.item.text : "Nada por ahora"
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.title
                font.weight: Tokens.weight.semibold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.item ? root.item.detail : "Aparece cuando hay algo"
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                elide: Text.ElideRight
            }
        }
        Icon {
            visible: !!root.item && !!root.item.view
            name: "chevron_right"
            size: Tokens.icon.sm
            color: Colors.textMuted
        }
    }
}
