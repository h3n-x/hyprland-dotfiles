// Vista Sistema del dashboard (Fase 4 B7): la referencia del estado del
// equipo, orientada a "como esta" antes que a los numeros. Arriba, el estado
// general y una frase que lo explica; despues, cuatro instrumentos con UN
// valor grande y una palabra (procesador, memoria, almacenamiento, energia);
// abajo, las aplicaciones que mas usan (agrupadas por aplicacion, no por
// proceso), la red y las graficas.
//
// Sin graficos en movimiento: los numeros cambian en su lugar, las barras
// solo se deslizan ante cambios de verdad (LevelBar) y la lista de
// aplicaciones reordena sus filas con un deslizamiento cuando cambia el
// ranking. Datos: SystemState (se leen solo mientras esta vista se ve).
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, SystemState.qml, NetworkState.qml, PowerProfileState.qml, MaintenanceState.qml, DashboardState.qml

ColumnLayout {
    id: view
    // La vista se ve (el dashboard la liga a su estado).
    property bool active: false
    property bool narrow: false
    spacing: Tokens.space.md

    onActiveChanged: {
        SystemState.wantDetail(view.active);
        if (view.active) PowerProfileState.refresh();
    }
    Component.onDestruction: if (view.active) SystemState.wantDetail(false)

    readonly property var disk: SystemState.storage.length ? SystemState.storage[0] : null
    readonly property real diskFrac: view.disk && view.disk.size > 0 ? view.disk.used / view.disk.size : 0

    // Frase que explica el estado, en palabras.
    readonly property string summary: {
        const parts = [];
        parts.push("Carga " + SystemState.cpuWord(SystemState.cpu).toLowerCase());
        parts.push("memoria " + SystemState.memWord(SystemState.memFrac).toLowerCase());
        if (!isNaN(SystemState.temp)) parts.push("temperatura " + SystemState.tempWord(SystemState.temp));
        let s = parts.join(", ") + ".";
        if (SystemState.uptime > 0) s += " Encendido hace " + SystemState.duration(SystemState.uptime) + ".";
        return s;
    }

    // ---- Instrumento: una cifra grande, una palabra, una barra -------------------------
    component Instrument: DashZone {
        id: ins
        property string icon
        property string label
        property string value
        property string unit: ""
        property string word: ""
        property int level: 0
        property real fraction: 0
        property string note: ""
        implicitHeight: insCol.implicitHeight + 2 * ins.padding

        ColumnLayout {
            id: insCol
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Tokens.space.xs
            RowLayout {
                spacing: Tokens.space.sm
                Icon { name: ins.icon; size: Tokens.icon.sm; color: Colors.textMuted }
                Text {
                    Layout.fillWidth: true
                    text: ins.label
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                    font.weight: Tokens.weight.semibold
                    elide: Text.ElideRight
                }
            }
            RowLayout {
                Layout.topMargin: Tokens.space.xs
                spacing: Tokens.space.xs
                Text {
                    text: ins.value
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.display
                    font.weight: Tokens.weight.semibold
                    font.features: Tokens.tabularNumbers
                }
                Text {
                    Layout.alignment: Qt.AlignBaseline
                    Layout.fillWidth: true
                    text: ins.unit
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                    elide: Text.ElideRight
                }
            }
            Text {
                text: ins.word
                color: ins.level >= 2 ? Colors.danger : ins.level === 1 ? Colors.warning : Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
                font.weight: Tokens.weight.medium
                Behavior on color { ColorAnimation { duration: Tokens.motion.medium } }
            }
            LevelBar {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.space.xs
                fraction: ins.fraction
                level: ins.level
            }
            Text {
                Layout.fillWidth: true
                text: ins.note
                color: Colors.border
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
                elide: Text.ElideRight
            }
        }
    }

    // ===== Estado general (sin superficie propia) =====
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.space.md
        Layout.rightMargin: Tokens.space.md
        Layout.topMargin: Tokens.space.xs
        spacing: Tokens.space.xs
        StatusLine {
            Layout.fillWidth: true
            textSize: Tokens.type.display
        }
        Text {
            Layout.fillWidth: true
            text: view.summary
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.body
            elide: Text.ElideRight
        }
    }

    // ===== Cuatro instrumentos =====
    GridLayout {
        Layout.fillWidth: true
        columns: view.narrow ? 2 : 4
        columnSpacing: Tokens.space.md
        rowSpacing: Tokens.space.md
        uniformCellWidths: true

        Instrument {
            Layout.fillWidth: true
            icon: "memory"
            label: "Procesador"
            value: Math.round(SystemState.cpu * 100) + " %"
            word: SystemState.cpuWord(SystemState.cpu)
            level: SystemState.cpuHighCount >= 3 ? 1 : 0
            fraction: SystemState.cpu
            note: (isNaN(SystemState.temp) ? "" : Math.round(SystemState.temp) + "° · ") + SystemState.cpuModel
        }
        Instrument {
            Layout.fillWidth: true
            icon: "memory_alt"
            label: "Memoria"
            value: SystemState.bytes(SystemState.memUsed)
            unit: "de " + SystemState.bytes(SystemState.memTotal)
            word: SystemState.memWord(SystemState.memFrac)
            level: SystemState.memFrac >= 0.92 ? 1 : 0
            fraction: SystemState.memFrac
            note: SystemState.swapUsed > 64 * 1048576 ? "Swap en uso: " + SystemState.bytes(SystemState.swapUsed) : "Sin swap en uso"
        }
        Instrument {
            Layout.fillWidth: true
            icon: "hard_drive"
            label: "Almacenamiento"
            value: view.disk ? SystemState.bytes(view.disk.avail) : "–"
            unit: "libres"
            word: view.disk ? SystemState.diskWord(view.diskFrac) : ""
            level: view.diskFrac >= 0.92 ? 1 : 0
            fraction: view.diskFrac
            note: (view.disk ? "de " + SystemState.bytes(view.disk.size) + " en " + view.disk.mount : "")
                + (isNaN(SystemState.nvmeTemp) ? "" : " · disco a " + Math.round(SystemState.nvmeTemp) + "°")
        }
        Instrument {
            Layout.fillWidth: true
            icon: SystemState.charging ? "battery_charging_full" : PowerProfileState.info.icon
            label: SystemState.hasBattery ? "Energía" : "Energía · corriente"
            value: SystemState.hasBattery ? Math.round(SystemState.batteryPct * 100) + " %" : PowerProfileState.info.label
            unit: !SystemState.hasBattery ? ""
                : SystemState.batteryTime > 0 ? (SystemState.charging ? "llena en " : "quedan ") + SystemState.duration(SystemState.batteryTime)
                : SystemState.charging ? "cargando" : SystemState.onAc ? (SystemState.batteryPct >= 0.995 ? "cargada" : "conectada") : ""
            word: "Perfil " + PowerProfileState.info.label.toLowerCase()
            level: SystemState.batteryCritical ? 2 : SystemState.batteryWarning ? 1 : 0
            fraction: SystemState.hasBattery ? SystemState.batteryPct : 0
            note: SystemState.batteryRate > 0.1 ? (SystemState.charging ? "Entran " : "Consume ") + SystemState.batteryRate.toFixed(1).replace(".", ",") + " W" : ""
        }
    }

    // ===== Aplicaciones · red y graficas =====
    GridLayout {
        Layout.fillWidth: true
        columns: view.narrow ? 1 : 2
        columnSpacing: Tokens.space.md
        rowSpacing: Tokens.space.md

        // Aplicaciones que mas usan (5).
        DashZone {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: appsCol.implicitHeight + 2 * padding
            ColumnLayout {
                id: appsCol
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Tokens.space.sm
                RowLayout {
                    Layout.fillWidth: true
                    ZoneTitle { Layout.fillWidth: true; text: "Aplicaciones"; detail: "· lo que más usa ahora" }
                    Text { text: "CPU"; color: Colors.border; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
                    Text { text: "Memoria"; color: Colors.border; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight }
                }
                ListView {
                    id: appList
                    Layout.fillWidth: true
                    implicitHeight: 5 * 32
                    interactive: false
                    model: ListModel { id: appModel }
                    // Cambia el ranking: las filas se deslizan a su lugar.
                    move: Transition { NumberAnimation { properties: "y"; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
                    displaced: Transition { NumberAnimation { properties: "y"; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
                    add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Tokens.motion.short } }
                    delegate: RowLayout {
                        required property string name
                        required property string icon
                        required property real cpu
                        required property real mem
                        required property real rel
                        width: appList.width
                        height: 32
                        spacing: Tokens.space.sm
                        Image {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            sourceSize: Qt.size(40, 40)
                            source: parent.icon
                            asynchronous: true
                        }
                        Text {
                            Layout.preferredWidth: 150
                            text: parent.name
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            elide: Text.ElideRight
                        }
                        LevelBar {
                            Layout.fillWidth: true
                            implicitHeight: 3
                            fraction: parent.rel
                            tint: Colors.accentContainer
                        }
                        Text {
                            Layout.preferredWidth: 44
                            horizontalAlignment: Text.AlignRight
                            text: parent.cpu < 0.01 ? (parent.cpu > 0 ? "< 1 %" : "0 %") : (parent.cpu * 100).toFixed(parent.cpu < 0.1 ? 1 : 0).replace(".", ",") + " %"
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            font.features: Tokens.tabularNumbers
                        }
                        Text {
                            Layout.preferredWidth: 64
                            horizontalAlignment: Text.AlignRight
                            text: SystemState.bytes(parent.mem)
                            color: Colors.textMuted
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            font.features: Tokens.tabularNumbers
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: view.narrow ? -1 : 300
            Layout.fillWidth: view.narrow
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            spacing: Tokens.space.md

            // Red: la conexion y su trafico ahora.
            DashZone {
                Layout.fillWidth: true
                implicitHeight: netCol.implicitHeight + 2 * padding
                ColumnLayout {
                    id: netCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Tokens.space.xs
                    ZoneTitle { Layout.fillWidth: true; text: "Red"; detail: "· " + NetworkState.label }
                    RowLayout {
                        Layout.topMargin: Tokens.space.xs
                        spacing: Tokens.space.lg
                        visible: NetworkState.connected
                        Repeater {
                            model: [{ icon: "arrow_downward", v: SystemState.rxRate, c: Colors.decor }, { icon: "arrow_upward", v: SystemState.txRate, c: Colors.accentAlt }]
                            Row {
                                required property var modelData
                                spacing: Tokens.space.xs
                                Icon { anchors.verticalCenter: parent.verticalCenter; name: parent.modelData.icon; size: Tokens.icon.sm; color: parent.modelData.c }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: SystemState.rate(parent.modelData.v)
                                    color: Colors.text
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.title
                                    font.weight: Tokens.weight.semibold
                                    font.features: Tokens.tabularNumbers
                                }
                            }
                        }
                    }
                }
            }

            // Graficas: integrada (uso y temperatura) y dedicada (estado, sin despertarla).
            DashZone {
                id: gpuZone
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: gpuCol.implicitHeight + 2 * padding
                readonly property bool dgpuActive: !!SystemState.nvidia && !!SystemState.nvidia.active
                ColumnLayout {
                    id: gpuCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Tokens.space.sm
                    ZoneTitle { Layout.fillWidth: true; text: "Gráficas" }
                    RowLayout {
                        visible: !!SystemState.igpuName
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: SystemState.igpuName
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            elide: Text.ElideRight
                        }
                        Text {
                            text: [isNaN(SystemState.gpuBusy) ? "" : Math.round(SystemState.gpuBusy * 100) + " %",
                                   isNaN(SystemState.gpuTemp) ? "" : Math.round(SystemState.gpuTemp) + "°"].filter(x => x).join(" · ")
                            color: Colors.textMuted
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            font.features: Tokens.tabularNumbers
                        }
                    }
                    RowLayout {
                        visible: !!SystemState.dgpuName
                        Layout.fillWidth: true
                        Text {
                            text: SystemState.dgpuName
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                        }
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            readonly property var n: SystemState.nvidia
                            text: !n ? "…" : !n.active ? "En reposo"
                                : n.processes && n.processes.length ? "Activa · " + n.processes.map(p => AppInfo.name(p.name)).join(", ") : "Activa"
                            color: gpuZone.dgpuActive ? Colors.decor : Colors.textMuted
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // ---- Mantenimiento (B9): una fila que lleva a su vista --------------------------------
    DashZone {
        Layout.fillWidth: true
        clickable: true
        padding: Tokens.space.md
        implicitHeight: maintRow.implicitHeight + 2 * Tokens.space.md
        onActivated: DashboardState.showView("maintenance")
        RowLayout {
            id: maintRow
            width: parent.width
            spacing: Tokens.space.sm
            Icon { name: "build"; size: Tokens.icon.md; color: Colors.textMuted }
            Text {
                Layout.fillWidth: true
                text: "Mantenimiento · " + MaintenanceState.shortStatus
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
                elide: Text.ElideRight
            }
            Icon { name: "chevron_right"; size: Tokens.icon.md; color: Colors.textMuted }
        }
    }

    // ---- Lista de aplicaciones: sincronizada por clave (para que las filas se muevan) ----
    Connections {
        target: SystemState
        function onAppsChanged(): void { view.syncApps(); }
    }
    function syncApps(): void {
        const list = SystemState.apps;
        // Escala absoluta con un minimo (una cuarta parte del equipo): en reposo
        // las barras quedan casi vacias en vez de "llenas" por comparacion.
        const top = list.reduce((m, a) => Math.max(m, a.cpu), 0.25);
        for (let i = 0; i < list.length; i++) {
            const a = list[i];
            const row = { key: a.key, name: a.name, icon: a.icon, cpu: a.cpu, mem: a.mem, rel: a.cpu / top };
            let j = -1;
            for (let k = i; k < appModel.count; k++) if (appModel.get(k).key === a.key) { j = k; break; }
            if (j < 0) appModel.insert(i, row);
            else {
                if (j !== i) appModel.move(j, i, 1);
                appModel.set(i, row);
            }
        }
        while (appModel.count > list.length) appModel.remove(appModel.count - 1);
    }
}
