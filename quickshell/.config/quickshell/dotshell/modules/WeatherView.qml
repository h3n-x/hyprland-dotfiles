// Clima de la vista Hoy del dashboard (Fase 4 B7; logica de B6, P4.7). Lee
// WeatherState; nunca toca la red (lo hace scripts/weather-fetch).
//
// Sin ruido: el tiempo de ahora en grande con UNA frase que lo explica
// ("Sensacion 17°. Hoy entre 14° y 24°, sin lluvia a la vista. Anochece a las
// 20:05."), las proximas horas cada 2 h y los proximos 5 dias. La ubicacion
// es un chip (clic o C: cambiarla). Los estados de B6 siguen todos: sin datos
// (consultando, sin conexion, error de consulta) como un bloque propio; con
// datos (usando cache, error al actualizar, antiguos) como una sola linea
// discreta con reintentar (R). Primera configuracion y "Cambiar": la vista de
// ubicacion de B6, sin cambios (busqueda, quitar, aviso de privacidad).
//
// "active" (de la vista): solo mientras se ve corre el reloj de "hace X min"
// y se pide una consulta si los datos son viejos.
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, WeatherState.qml

Item {
    id: wv
    property bool active: true
    // Vista de ubicacion (elegir o cambiar ciudad).
    property bool picking: false
    // Esc en la busqueda sin nada que deshacer: volver a Inicio.
    signal backRequested()

    implicitHeight: (wv.picking || !WeatherState.configured) ? picker.implicitHeight : main.implicitHeight

    SystemClock {
        id: clock
        enabled: wv.active
        precision: SystemClock.Minutes
    }
    readonly property real now: clock.date.getTime() / 1000
    readonly property string status: WeatherState.status(wv.now)
    readonly property var d: WeatherState.data
    readonly property var cur: wv.d ? wv.d.current : null
    readonly property var desc: wv.cur ? WeatherText.describe(wv.cur.weather_code, wv.cur.is_day === 1) : null

    onActiveChanged: {
        if (wv.active) {
            WeatherState.ensureFresh();
            // Primera configuracion: el cursor ya en la busqueda.
            if (picker.visible) Qt.callLater(() => field.focusInput());
        } else {
            wv.picking = false;
        }
    }
    // Teclado (con el foco en la vista): C cambiar ubicacion, R reintentar.
    function handleKey(event: var): bool {
        if (event.key === Qt.Key_C) {
            wv.picking = true;
            return true;
        }
        if (event.key === Qt.Key_R && WeatherState.configured) {
            WeatherState.refresh();
            return true;
        }
        return false;
    }

    readonly property var days: {
        if (!wv.d || !wv.d.daily) return [];
        const dl = wv.d.daily;
        const out = [];
        for (let i = 0; i < dl.time.length && i < 5; i++)
            out.push({ label: WeatherState.dayShort(dl.time[i], i), code: dl.weather_code[i], max: dl.temperature_2m_max[i], min: dl.temperature_2m_min[i], rain: dl.precipitation_probability_max[i] });
        return out;
    }
    readonly property real weekMin: wv.days.length ? Math.min.apply(null, wv.days.map(x => x.min)) : 0
    readonly property real weekMax: wv.days.length ? Math.max.apply(null, wv.days.map(x => x.max)) : 1

    // La frase: sensacion, el rango de hoy, la lluvia y la luz que queda.
    readonly property string sentence: {
        if (!wv.cur || !wv.days.length) return "";
        const t = wv.days[0];
        let s = "Sensación " + WeatherState.temp(wv.cur.apparent_temperature) + ". Hoy entre "
            + WeatherState.temp(t.min) + " y " + WeatherState.temp(t.max);
        s += t.rain >= 50 ? ", con lluvia probable (" + t.rain + " %)" : t.rain >= 20 ? ", puede llover (" + t.rain + " %)" : ", sin lluvia a la vista";
        s += ".";
        if (wv.cur.wind_speed_10m >= 30) s += " Viento fuerte (" + Math.round(wv.cur.wind_speed_10m) + " km/h).";
        const dl = wv.d.daily;
        if (dl && dl.sunset && dl.sunrise) s += wv.cur.is_day === 1 ? " Anochece a las " + dl.sunset[0].slice(11, 16) + "." : " Amanece a las " + (dl.sunrise[1] || dl.sunrise[0]).slice(11, 16) + ".";
        return s;
    }

    component TextButton: Rectangle {
        id: tb
        property string label
        property string icon: ""
        property bool danger: false
        signal clicked()
        implicitHeight: Tokens.px(28)
        implicitWidth: tbRow.implicitWidth + Tokens.space.md * 2
        radius: Tokens.radius.sm
        color: "transparent"
        border.width: 1
        border.color: Colors.divider
        StateLayer { hovered: tbMouse.containsMouse; pressed: tbMouse.pressed; contentColor: tb.danger ? Colors.danger : Colors.text }
        Row {
            id: tbRow
            anchors.centerIn: parent
            spacing: Tokens.space.xs
            Icon { visible: !!tb.icon; anchors.verticalCenter: parent.verticalCenter; name: tb.icon; size: Tokens.icon.sm; color: tb.danger ? Colors.danger : Colors.textMuted }
            Text { anchors.verticalCenter: parent.verticalCenter; text: tb.label; color: tb.danger ? Colors.danger : Colors.textMuted; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.weight: Tokens.weight.medium }
        }
        MouseArea {
            id: tbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tb.clicked()
        }
    }


    // ---- Vista principal --------------------------------------------------------
    ColumnLayout {
        id: main
        visible: !wv.picking && WeatherState.configured
        width: wv.width
        spacing: Tokens.space.md

        // Ahora (sin superficie): lo que importa, en grande.
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.space.xs
            spacing: Tokens.space.lg
            Icon {
                visible: !!wv.desc
                Layout.alignment: Qt.AlignTop
                name: wv.desc ? wv.desc.icon : ""
                size: Tokens.px(48)
                filled: true
                color: wv.cur && wv.cur.is_day === 1 ? Colors.accent : Colors.decor
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.space.xs
                RowLayout {
                    visible: !!wv.cur
                    spacing: Tokens.space.md
                    Text {
                        text: wv.cur ? WeatherState.temp(wv.cur.temperature_2m) : ""
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.displayLarge
                        font.weight: Tokens.weight.semibold
                        font.features: Tokens.tabularNumbers
                    }
                    Text {
                        Layout.alignment: Qt.AlignBaseline
                        text: wv.desc ? wv.desc.text : ""
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.title
                        font.weight: Tokens.weight.medium
                    }
                }
                Text {
                    visible: !!wv.sentence
                    Layout.fillWidth: true
                    text: wv.sentence
                    wrapMode: Text.WordWrap
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                }
                // Estado con datos: una sola linea discreta.
                RowLayout {
                    visible: !!wv.d && ["cached", "error", "stale"].indexOf(wv.status) >= 0
                    spacing: Tokens.space.xs
                    readonly property color tint: wv.status === "error" ? Colors.danger : wv.status === "cached" ? Colors.textMuted : Colors.border
                    Icon { name: wv.status === "cached" ? "cloud_off" : wv.status === "error" ? "warning" : "history"; size: Tokens.icon.sm; color: parent.tint }
                    Text {
                        text: wv.status === "cached" ? "Sin conexión · datos guardados " + WeatherState.ago(wv.now - WeatherState.fetchedAt)
                            : wv.status === "error" ? "No se pudo actualizar" + (WeatherState.lastError ? " (" + WeatherState.lastError.detail + ")" : "") + " · datos " + WeatherState.ago(wv.now - WeatherState.fetchedAt)
                            : "Datos " + WeatherState.ago(wv.now - WeatherState.fetchedAt) + (WeatherState.fetching ? " · actualizando…" : "")
                        color: parent.tint
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.caption
                        font.weight: Tokens.weight.medium
                    }
                    TextButton { visible: !WeatherState.fetching; label: "Reintentar"; icon: "refresh"; onClicked: WeatherState.refresh() }
                }
            }
            // La ubicacion: un chip; cambiarla abre la vista de ubicacion.
            TextButton {
                Layout.alignment: Qt.AlignTop
                label: WeatherState.location ? WeatherState.location.name : ""
                icon: "location_on"
                onClicked: wv.picking = true
            }
        }

        // Sin datos: un bloque centrado propio.
        ColumnLayout {
            visible: !wv.d
            Layout.fillWidth: true
            Layout.topMargin: Tokens.space.lg
            Layout.bottomMargin: Tokens.space.lg
            spacing: Tokens.space.sm
            Icon {
                Layout.alignment: Qt.AlignHCenter
                name: wv.status === "offline" ? "cloud_off" : wv.status === "failed" ? "warning" : "sync"
                size: Tokens.icon.xl
                color: wv.status === "failed" ? Colors.danger : Colors.textMuted
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: wv.status === "offline" ? "Sin conexión" : wv.status === "failed" ? "No se pudo consultar el clima" : "Consultando el clima…"
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.title
                font.weight: Tokens.weight.semibold
            }
            Text {
                visible: wv.status === "offline" || wv.status === "failed"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: wv.status === "offline" ? "No hay red o Open-Meteo no responde. Se reintenta en unos minutos."
                    : "Open-Meteo respondió con un error" + (WeatherState.lastError ? " (" + WeatherState.lastError.detail + ")" : "") + "."
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
            }
            TextButton {
                visible: wv.status === "offline" || wv.status === "failed"
                Layout.alignment: Qt.AlignHCenter
                label: WeatherState.fetching ? "Reintentando…" : "Reintentar"
                icon: "refresh"
                onClicked: WeatherState.refresh()
            }
        }

        // Proximas horas.
        DashZone {
            visible: WeatherState.hours.length > 0
            Layout.fillWidth: true
            implicitHeight: hoursCol.implicitHeight + 2 * padding
            ColumnLayout {
                id: hoursCol
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Tokens.space.sm
                ZoneTitle { Layout.fillWidth: true; text: "Próximas horas" }
                WeatherHours { Layout.fillWidth: true }
            }
        }

        // Proximos dias con barra minima-maxima (escala de la semana).
        DashZone {
            visible: wv.days.length > 0
            Layout.fillWidth: true
            implicitHeight: daysCol.implicitHeight + 2 * padding
            ColumnLayout {
                id: daysCol
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Tokens.space.xs
                ZoneTitle { Layout.fillWidth: true; text: "Próximos días" }
                Repeater {
                    model: wv.days
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: Tokens.px(28)
                        spacing: Tokens.space.md
                        Text { Layout.preferredWidth: Tokens.px(44); text: modelData.label; color: Colors.text; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.weight: Tokens.weight.medium }
                        Icon { name: WeatherText.describe(modelData.code, true).icon; size: Tokens.icon.md; color: Colors.textMuted }
                        Text { Layout.preferredWidth: Tokens.px(40); text: modelData.rain >= 30 ? modelData.rain + " %" : ""; color: Colors.decor; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; font.features: Tokens.tabularNumbers }
                        Text { Layout.preferredWidth: Tokens.px(36); horizontalAlignment: Text.AlignRight; text: WeatherState.temp(modelData.min); color: Colors.border; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.features: Tokens.tabularNumbers }
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 4
                            readonly property real span: Math.max(1, wv.weekMax - wv.weekMin)
                            Rectangle { anchors.fill: parent; radius: 2; color: Colors.tint(Colors.textMuted, Tokens.tint.track) }
                            Rectangle {
                                x: (modelData.min - wv.weekMin) / parent.span * parent.width
                                width: Math.max(4, (modelData.max - modelData.min) / parent.span * parent.width)
                                height: 4
                                radius: 2
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: Colors.accentAlt }
                                    GradientStop { position: 1; color: Colors.accent }
                                }
                            }
                        }
                        Text { Layout.preferredWidth: Tokens.px(36); text: WeatherState.temp(modelData.max); color: Colors.text; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.weight: Tokens.weight.medium; font.features: Tokens.tabularNumbers }
                    }
                }
            }
        }
    }

    // ---- Vista de ubicacion (primera configuracion o "Cambiar") -----------------
    ColumnLayout {
        id: picker
        visible: wv.picking || !WeatherState.configured
        width: wv.width
        spacing: Tokens.space.sm

        onVisibleChanged: if (picker.visible) {
            field.reset();
            if (wv.active) field.focusInput();
        }

        RowLayout {
            visible: WeatherState.configured
            Layout.fillWidth: true
            TextButton { label: "Volver"; icon: "arrow_back"; onClicked: wv.picking = false }
            Item { Layout.fillWidth: true }
        }
        Icon {
            visible: !WeatherState.configured
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.space.sm
            name: "partly_cloudy_day"
            size: Tokens.px(48)
            color: Colors.textMuted
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: WeatherState.configured ? Text.AlignLeft : Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: WeatherState.configured ? "Cambiar la ubicación" : "Elige tu ciudad para ver el clima"
            color: Colors.text
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.title
            font.weight: Tokens.weight.semibold
        }
        // La ubicacion actual, con la opcion de quitarla (deja de consultar).
        Rectangle {
            visible: WeatherState.configured
            Layout.fillWidth: true
            implicitHeight: curRow.implicitHeight + Tokens.space.sm * 2
            radius: Tokens.radius.md
            color: Colors.surfaceHighest
            RowLayout {
                id: curRow
                anchors.fill: parent
                anchors.margins: Tokens.space.sm
                spacing: Tokens.space.sm
                Icon { name: "place"; size: Tokens.icon.sm; color: Colors.accent }
                Column {
                    Layout.fillWidth: true
                    Text { text: "Ubicación actual"; color: Colors.border; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption }
                    Text { width: parent.width; text: WeatherState.location ? WeatherState.location.name + (WeatherState.location.detail ? " · " + WeatherState.location.detail : "") : ""; color: Colors.text; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.weight: Tokens.weight.medium; elide: Text.ElideRight }
                }
                TextButton { label: "Quitar"; icon: "delete"; danger: true; onClicked: { WeatherState.clearLocation(); wv.picking = false; } }
            }
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: WeatherState.configured ? Text.AlignLeft : Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "Se guarda solo en este equipo. Se consulta Open-Meteo con coordenadas aproximadas (≈ 10 km) cada 30 minutos; sin ubicación no se consulta nada."
            color: Colors.textMuted
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
        }
        // Busqueda de ciudad (CitySearch, compartida con el centro de
        // configuracion, Fase 10 B4).
        CitySearch {
            id: field
            Layout.fillWidth: true
            onChosen: (place) => {
                WeatherState.setLocation(place);
                wv.picking = false;
            }
            onEscaped: {
                if (wv.picking && WeatherState.configured) wv.picking = false;
                else wv.backRequested();
            }
        }
    }
}
