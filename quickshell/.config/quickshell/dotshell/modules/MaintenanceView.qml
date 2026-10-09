// Vista Mantenimiento del dashboard (Fase 4 B9): explica antes de listar.
// Arriba responde "¿esta bien el sistema?", "¿que requiere atencion?" y "¿que
// conviene hacer?"; despues, lo que requiere atencion y lo recomendado (una
// frase por elemento, con su numero adentro); lo que esta bien, en una sola
// linea; lo informativo, en filas discretas. El detalle tecnico (paquetes,
// servicios, volcados y los comandos exactos) solo al desplegar. Las acciones
// abren una terminal visible (MaintenanceState.act).
//
// Datos: MaintenanceState (se revisa al entrar; los tamanos solo si tienen
// mas de 10 min). Quieta mientras no cambia nada.
import QtQuick
import QtQuick.Layouts
import ".." // Colors.qml, Tokens.qml, MaintenanceState.qml, DashboardState.qml

ColumnLayout {
    id: view
    property bool active: false
    property bool narrow: false
    spacing: Tokens.space.md

    onActiveChanged: {
        if (view.active) {
            MaintenanceState.refresh(false);
        } else {
            view.focusIndex = -1;
            view.expanded = "";
        }
    }

    // Filas navegables con el teclado, en el orden en que se ven.
    readonly property var rows: MaintenanceState.attention.concat(MaintenanceState.recommended, MaintenanceState.info)
    property int focusIndex: -1
    property string expanded: ""

    function toggle(id: string): void {
        view.expanded = view.expanded === id ? "" : id;
    }
    function run(item: var): void {
        if (!item || !item.action) return;
        const u = item.units && item.units.length ? item.units[0] : null;
        MaintenanceState.act(item.action, u ? u.name : "", u && u.scope === "user" ? "user" : "");
    }
    function handleKey(event: var): bool {
        const n = view.rows.length;
        if (!n) return false;
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) {
            view.focusIndex = (view.focusIndex + 1) % n;
            return true;
        }
        if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) {
            view.focusIndex = view.focusIndex <= 0 ? n - 1 : view.focusIndex - 1;
            return true;
        }
        const item = view.focusIndex >= 0 ? view.rows[view.focusIndex] : null;
        if (!item) return false;
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Right) {
            view.toggle(item.id);
            return true;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            view.run(item);
            return true;
        }
        return false;
    }

    component T: Text {
        property int size: Tokens.type.body
        property int wt: Tokens.weight.regular
        color: Colors.text
        font.family: Tokens.font.ui
        font.pixelSize: size
        font.weight: wt
        font.features: Tokens.tabularNumbers
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        maximumLineCount: 3
    }
    component SectionTitle: T {
        Layout.topMargin: Tokens.space.xs
        Layout.leftMargin: Tokens.space.xs
        size: Tokens.type.label
        wt: Tokens.weight.semibold
        color: Colors.textMuted
    }

    // Una fila: severidad, frase, por que, accion, desplegar; detalle debajo.
    component Row_: DashZone {
        id: row
        required property var modelData
        readonly property var item: row.modelData
        readonly property bool open_: view.expanded === row.item.id
        readonly property var plan: MaintenanceState.plan[row.item.action] || null
        Layout.fillWidth: true
        padding: Tokens.space.md
        focused: view.focusIndex >= 0 && view.rows[view.focusIndex] && view.rows[view.focusIndex].id === row.item.id
        clickable: true
        onActivated: view.toggle(row.item.id)
        implicitHeight: rowCol.implicitHeight + 2 * Tokens.space.md
        Behavior on implicitHeight {
            enabled: view.active && Tokens.motion.scale > 0
            NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
        }
        clip: true

        ColumnLayout {
            id: rowCol
            width: parent.width
            spacing: Tokens.space.sm
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.space.md
                StatusBadge { level: row.item.sev; Layout.alignment: Qt.AlignTop; Layout.topMargin: 1 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    T { Layout.fillWidth: true; text: row.item.sentence; wt: Tokens.weight.semibold }
                    T { Layout.fillWidth: true; visible: !!row.item.why; text: row.item.why; size: Tokens.type.label; color: Colors.textMuted }
                }
                Button {
                    visible: !!row.item.action && row.item.action !== "unit-log"
                    Layout.alignment: Qt.AlignVCenter
                    label: row.item.actionLabel
                    icon: row.item.action === "reboot" ? "restart_alt" : row.item.action === "captures" ? "folder_open" : "terminal"
                    onClicked: view.run(row.item)
                }
                Icon { Layout.alignment: Qt.AlignVCenter; name: row.open_ ? "expand_less" : "expand_more"; color: Colors.textMuted }
            }

            // ---- Detalle (solo desplegado) ----
            ColumnLayout {
                Layout.fillWidth: true
                visible: row.open_
                spacing: Tokens.space.sm

                // Paquetes (actualizaciones, huerfanos)
                Flow {
                    Layout.fillWidth: true
                    visible: !!row.item.packages
                    spacing: Tokens.space.xs
                    Repeater {
                        model: row.open_ && row.item.packages ? row.item.packages.slice(0, 30) : []
                        Rectangle {
                            id: pkg
                            required property var modelData
                            height: Tokens.px(24)
                            width: pkgText.implicitWidth + Tokens.space.md
                            radius: Tokens.radius.xs
                            color: Colors.tint(Colors.background, Tokens.tint.well)
                            T {
                                id: pkgText
                                anchors.centerIn: parent
                                text: pkg.modelData.to ? pkg.modelData.name + "  " + pkg.modelData.from + " → " + pkg.modelData.to : pkg.modelData.name
                                font.family: Tokens.font.mono
                                size: Tokens.type.caption
                                wrapMode: Text.NoWrap
                            }
                        }
                    }
                    T {
                        visible: !!row.item.packages && row.item.packages.length > 30
                        text: row.item.packages ? "y " + (row.item.packages.length - 30) + " más" : ""
                        size: Tokens.type.caption
                        color: Colors.border
                    }
                }

                // Servicios: su propia descripcion y la ultima linea del registro
                Repeater {
                    model: row.open_ && row.item.units ? row.item.units : []
                    RowLayout {
                        id: unitRow
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Tokens.space.md
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            T { Layout.fillWidth: true; text: unitRow.modelData.name; font.family: Tokens.font.mono; size: Tokens.type.label; wrapMode: Text.NoWrap }
                            T { Layout.fillWidth: true; text: unitRow.modelData.description + (unitRow.modelData.lastLog ? " — " + unitRow.modelData.lastLog : "")
                                size: Tokens.type.caption; color: Colors.border; maximumLineCount: 2 }
                        }
                        Button { label: "Ver registro"; icon: "article"
                            onClicked: MaintenanceState.act("unit-log", unitRow.modelData.name, unitRow.modelData.scope === "user" ? "user" : "") }
                        Button { label: "Ocultar"; icon: "visibility_off"; onClicked: MaintenanceState.ignoreUnit(unitRow.modelData.name) }
                    }
                }

                // Volcados por programa
                Repeater {
                    model: row.open_ && row.item.sources ? row.item.sources.slice(0, 6) : []
                    RowLayout {
                        id: srcRow
                        required property var modelData
                        Layout.fillWidth: true
                        T { Layout.fillWidth: true; text: srcRow.modelData.exe; font.family: Tokens.font.mono; size: Tokens.type.label; wrapMode: Text.NoWrap }
                        T { text: "desde el " + Qt.formatDate(new Date(srcRow.modelData.first * 1000), "dd/MM"); size: Tokens.type.caption; color: Colors.border }
                        T { Layout.preferredWidth: Tokens.px(96); horizontalAlignment: Text.AlignRight; size: Tokens.type.label; wt: Tokens.weight.medium
                            text: MaintenanceState.plural(srcRow.modelData.stored, "volcado", "volcados") }
                    }
                }

                // Archivos .pacnew
                Repeater {
                    model: row.open_ && row.item.files ? row.item.files : []
                    T { required property string modelData; text: modelData; font.family: Tokens.font.mono; size: Tokens.type.label }
                }

                // Lo que se va a ejecutar, antes de abrir la terminal
                Rectangle {
                    Layout.fillWidth: true
                    visible: !!row.plan
                    implicitHeight: planCol.implicitHeight + Tokens.space.md
                    radius: Tokens.radius.sm
                    color: Colors.tint(Colors.background, Tokens.tint.well)
                    Column {
                        id: planCol
                        x: Tokens.space.md
                        y: Tokens.space.sm
                        width: parent.width - 2 * Tokens.space.md
                        spacing: 2
                        T { width: parent.width; text: row.plan ? row.plan.why : ""; size: Tokens.type.label; color: Colors.textMuted }
                        Repeater {
                            model: row.plan ? row.plan.commands : []
                            T { required property string modelData; text: modelData; font.family: Tokens.font.mono; size: Tokens.type.label; wrapMode: Text.NoWrap }
                        }
                    }
                }
                Button {
                    visible: !!row.plan
                    main: true
                    label: "Abrir en la terminal"
                    icon: "terminal"
                    onClicked: view.run(row.item)
                }
            }
        }
    }

    // ---- ¿Esta bien? ¿Que requiere atencion? ¿Que conviene hacer? ----
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.space.xs
        spacing: Tokens.space.md
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.space.xs
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.space.sm
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: Tokens.px(12)
                    height: Tokens.px(12)
                    radius: 6
                    // Veredicto (N7): nada o solo informacion = success; recomendaciones =
                    // neutro; advertencia y accion importante con sus colores fijos.
                    color: MaintenanceState.worst >= 3 ? Colors.danger : MaintenanceState.worst === 2 ? Colors.warning
                        : MaintenanceState.worst === 1 ? Colors.textMuted : Colors.success
                    Behavior on color { ColorAnimation { duration: Tokens.motion.short } }
                }
                T {
                    id: verdict
                    Layout.fillWidth: true
                    text: MaintenanceState.verdict
                    size: Tokens.type.headline
                    wt: Tokens.weight.semibold
                    maximumLineCount: 2
                }
            }
            T {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.px(20)
                visible: !!MaintenanceState.recommendation
                text: MaintenanceState.recommendation
                color: Colors.textMuted
            }
        }
        Button {
            Layout.alignment: Qt.AlignTop
            label: MaintenanceState.checking ? "Revisando…" : "Revisar"
            icon: "refresh"
            onClicked: MaintenanceState.refresh(true)
        }
    }

    SectionTitle { visible: MaintenanceState.attention.length > 0; text: "Requiere atención" }
    Repeater {
        model: MaintenanceState.attention
        Row_ {}
    }
    SectionTitle { visible: MaintenanceState.recommended.length > 0; text: "Recomendado" }
    Repeater {
        model: MaintenanceState.recommended
        Row_ {}
    }

    // Lo que esta bien, en una sola linea
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.space.xs
        Layout.leftMargin: Tokens.space.xs
        visible: !!MaintenanceState.okLine
        spacing: Tokens.space.sm
        Icon { name: "check_circle"; filled: true; size: Tokens.icon.sm; color: Colors.accent }
        T { Layout.fillWidth: true; text: MaintenanceState.okLine; size: Tokens.type.label; color: Colors.textMuted }
    }
    // Informacion: filas discretas, con detalle al desplegar
    Repeater {
        model: MaintenanceState.info
        ColumnLayout {
            id: infoRow
            required property var modelData
            readonly property bool open_: view.expanded === infoRow.modelData.id
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.space.xs
            spacing: Tokens.space.xs
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.space.sm
                Icon { name: "info"; size: Tokens.icon.sm; color: Colors.border }
                T { Layout.fillWidth: true; text: infoRow.modelData.sentence; size: Tokens.type.label; color: Colors.border }
                T {
                    visible: !!infoRow.modelData.units
                    text: infoRow.open_ ? "Menos" : "Ver"
                    size: Tokens.type.label
                    wt: Tokens.weight.semibold
                    color: Colors.accent
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: view.toggle(infoRow.modelData.id) }
                }
            }
            T { visible: infoRow.open_; Layout.leftMargin: Tokens.px(24); Layout.fillWidth: true; text: infoRow.modelData.why; size: Tokens.type.caption; color: Colors.border }
            Repeater {
                model: infoRow.open_ && infoRow.modelData.units ? infoRow.modelData.units : []
                RowLayout {
                    id: infoUnit
                    required property var modelData
                    Layout.leftMargin: Tokens.px(24)
                    Layout.fillWidth: true
                    T { Layout.fillWidth: true; text: infoUnit.modelData.name; font.family: Tokens.font.mono; size: Tokens.type.caption; color: Colors.textMuted; wrapMode: Text.NoWrap }
                    Button { label: "Ver registro"; icon: "article"
                        onClicked: MaintenanceState.act("unit-log", infoUnit.modelData.name, infoUnit.modelData.scope === "user" ? "user" : "") }
                    Button { label: "Ocultar"; icon: "visibility_off"; onClicked: MaintenanceState.ignoreUnit(infoUnit.modelData.name) }
                }
            }
        }
    }
    // Servicios ocultos (reversible)
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.space.xs
        visible: MaintenanceState.ignoredUnits.length > 0
        spacing: Tokens.space.sm
        Icon { name: "visibility_off"; size: Tokens.icon.sm; color: Colors.border }
        T { Layout.fillWidth: true; size: Tokens.type.label; color: Colors.border
            text: "Ocultaste " + MaintenanceState.plural(MaintenanceState.ignoredUnits.length, "servicio", "servicios") + "." }
        T {
            text: "Mostrar"
            size: Tokens.type.label
            wt: Tokens.weight.semibold
            color: Colors.accent
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { for (const n of MaintenanceState.ignoredUnits.slice()) MaintenanceState.restoreUnit(n); } }
        }
    }
}
