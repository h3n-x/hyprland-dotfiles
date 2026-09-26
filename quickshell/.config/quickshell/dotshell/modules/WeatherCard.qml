// Clima (Fase 4 B6, P4.7): tarjeta autonoma (panel del reloj; dashboard en
// B7). Lee WeatherState; nunca toca la red (lo hace scripts/weather-fetch).
//
// Cabecera: la ubicacion configurada, siempre visible, y "Cambiar". Vista de
// ubicacion: la actual (con "Quitar"), busqueda por nombre y resultados.
// Estados con aspecto propio: primera configuracion, consultando, sin
// conexion (sin datos), error de consulta (sin datos), usando cache (sin
// conexion, con datos), error al actualizar (con datos), datos antiguos.
// Todo en espanol. "active" (del panel): solo mientras se ve corre el reloj de
// "hace X min" y se pide una consulta si los datos son viejos.
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, WeatherState.qml

Item {
    id: card
    property bool active: true
    // Vista de ubicacion (elegir o cambiar ciudad).
    property bool picking: false
    readonly property int cardWidth: 316
    // Esc en la busqueda sin nada que deshacer: el panel se cierra.
    signal closeRequested()

    implicitWidth: card.cardWidth
    implicitHeight: (card.picking || !WeatherState.configured) ? picker.implicitHeight : main.implicitHeight

    SystemClock {
        id: clock
        enabled: card.active
        precision: SystemClock.Minutes
    }
    readonly property real now: clock.date.getTime() / 1000
    readonly property string status: WeatherState.status(card.now)
    readonly property var d: WeatherState.data
    readonly property var cur: card.d ? card.d.current : null

    onActiveChanged: {
        if (card.active) {
            WeatherState.ensureFresh();
            // Primera configuracion: el cursor ya en la busqueda (despues de que
            // el panel tome el foco).
            if (picker.visible) Qt.callLater(() => field.forceActiveFocus());
        } else {
            card.picking = false;
        }
    }

    // Proximas 6 horas (desde la hora actual).
    readonly property var hours: {
        if (!card.d || !card.d.hourly) return [];
        const h = card.d.hourly;
        const out = [];
        for (let i = 0; i < h.time.length && out.length < 6; i++)
            out.push({ label: h.time[i].slice(11, 13) + " h", code: h.weather_code[i], day: h.is_day ? h.is_day[i] === 1 : true, t: h.temperature_2m[i] });
        return out;
    }
    readonly property var days: {
        if (!card.d || !card.d.daily) return [];
        const dl = card.d.daily;
        const out = [];
        for (let i = 0; i < dl.time.length && i < 5; i++)
            out.push({ label: WeatherState.dayShort(dl.time[i], i), code: dl.weather_code[i], max: dl.temperature_2m_max[i], min: dl.temperature_2m_min[i], rain: dl.precipitation_probability_max[i] });
        return out;
    }
    readonly property real weekMin: card.days.length ? Math.min.apply(null, card.days.map(x => x.min)) : 0
    readonly property real weekMax: card.days.length ? Math.max.apply(null, card.days.map(x => x.max)) : 1

    component TextButton: Rectangle {
        id: tb
        property string label
        property string icon: ""
        property bool danger: false
        signal clicked()
        implicitHeight: 28
        implicitWidth: tbRow.implicitWidth + Tokens.space.md * 2
        radius: Tokens.radius.sm
        color: "transparent"
        border.width: 1
        border.color: Colors.m3outlineVariant
        StateLayer { hovered: tbMouse.containsMouse; pressed: tbMouse.pressed; contentColor: tb.danger ? Colors.m3error : Colors.m3onSurface }
        Row {
            id: tbRow
            anchors.centerIn: parent
            spacing: Tokens.space.xs
            Icon { visible: !!tb.icon; anchors.verticalCenter: parent.verticalCenter; name: tb.icon; size: Tokens.icon.sm; color: tb.danger ? Colors.m3error : Colors.m3onSurfaceVariant }
            Text { anchors.verticalCenter: parent.verticalCenter; text: tb.label; color: tb.danger ? Colors.m3error : Colors.m3onSurfaceVariant; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.weight: Tokens.weight.medium }
        }
        MouseArea {
            id: tbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tb.clicked()
        }
    }

    // Aviso de estado (una linea con icono y color propios).
    component Banner: Rectangle {
        id: ban
        property string icon
        property string text
        property color tint: Colors.m3onSurfaceVariant
        property color fill: "transparent"
        property bool retry: false
        Layout.fillWidth: true
        implicitHeight: Math.max(32, banRow.implicitHeight + Tokens.space.sm * 2)
        radius: Tokens.radius.md
        color: ban.fill
        RowLayout {
            id: banRow
            anchors.fill: parent
            anchors.leftMargin: Tokens.space.sm
            anchors.rightMargin: Tokens.space.xs
            spacing: Tokens.space.sm
            Icon { name: ban.icon; size: Tokens.icon.sm; color: ban.tint }
            Text { Layout.fillWidth: true; text: ban.text; color: ban.tint; wrapMode: Text.WordWrap; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; font.weight: Tokens.weight.medium }
            Rectangle {
                visible: ban.retry
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: "transparent"
                StateLayer { hovered: retryMouse.containsMouse; pressed: retryMouse.pressed; contentColor: ban.tint }
                Icon { anchors.centerIn: parent; name: "refresh"; size: Tokens.icon.sm; color: ban.tint; rotation: WeatherState.fetching ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: Tokens.motion.medium } } }
                MouseArea { id: retryMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: WeatherState.refresh() }
            }
        }
    }

    // ---- Vista principal --------------------------------------------------------
    ColumnLayout {
        id: main
        visible: !card.picking && WeatherState.configured
        width: card.cardWidth
        spacing: Tokens.space.md

        // Ubicacion actual, siempre visible, con "Cambiar".
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.space.xs
            Icon { name: "place"; size: Tokens.icon.sm; color: Colors.m3onSurfaceVariant }
            Column {
                Layout.fillWidth: true
                Text { width: parent.width; text: WeatherState.location ? WeatherState.location.name : ""; color: Colors.m3onSurface; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.weight: Tokens.weight.medium; elide: Text.ElideRight }
                Text { visible: !!(WeatherState.location && WeatherState.location.detail); width: parent.width; text: WeatherState.location ? WeatherState.location.detail : ""; color: Colors.m3outline; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; elide: Text.ElideRight }
            }
            TextButton { label: "Cambiar"; icon: "edit_location"; onClicked: card.picking = true }
        }

        // Estados sin datos: un bloque centrado propio.
        ColumnLayout {
            visible: !card.d
            Layout.fillWidth: true
            Layout.topMargin: Tokens.space.lg
            Layout.bottomMargin: Tokens.space.lg
            spacing: Tokens.space.sm
            Icon {
                Layout.alignment: Qt.AlignHCenter
                name: card.status === "offline" ? "cloud_off" : card.status === "failed" ? "warning" : "sync"
                size: Tokens.icon.xl
                color: card.status === "failed" ? Colors.m3error : card.status === "offline" ? Colors.m3tertiary : Colors.m3onSurfaceVariant
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: card.status === "offline" ? "Sin conexión" : card.status === "failed" ? "No se pudo consultar el clima" : "Consultando el clima…"
                color: Colors.m3onSurface
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.title
                font.weight: Tokens.weight.semibold
            }
            Text {
                visible: card.status === "offline" || card.status === "failed"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: card.status === "offline" ? "No hay red o Open-Meteo no responde. Se reintenta en unos minutos."
                    : "Open-Meteo respondió con un error" + (WeatherState.lastError ? " (" + WeatherState.lastError.detail + ")" : "") + "."
                color: Colors.m3onSurfaceVariant
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.caption
            }
            TextButton {
                visible: card.status === "offline" || card.status === "failed"
                Layout.alignment: Qt.AlignHCenter
                label: WeatherState.fetching ? "Reintentando…" : "Reintentar"
                icon: "refresh"
                onClicked: WeatherState.refresh()
            }
        }

        // Estados con datos: aviso arriba de los datos.
        Banner {
            visible: card.status === "cached"
            icon: "cloud_off"
            tint: Colors.m3onTertiaryContainer
            fill: Colors.m3tertiaryContainer
            text: "Sin conexión · usando los datos guardados " + WeatherState.ago(card.now - WeatherState.fetchedAt)
            retry: true
        }
        Banner {
            visible: card.status === "error"
            icon: "warning"
            tint: Colors.m3onErrorContainer
            fill: Colors.m3errorContainer
            text: "No se pudo actualizar" + (WeatherState.lastError ? " (" + WeatherState.lastError.detail + ")" : "") + " · datos " + WeatherState.ago(card.now - WeatherState.fetchedAt)
            retry: true
        }
        Banner {
            visible: card.status === "stale"
            icon: "history"
            tint: Colors.m3onSurfaceVariant
            fill: Colors.m3surfaceContainerHighest
            text: "Datos antiguos (" + WeatherState.ago(card.now - WeatherState.fetchedAt) + ")" + (WeatherState.fetching ? " · actualizando…" : "")
            retry: !WeatherState.fetching
        }

        // Actual.
        RowLayout {
            visible: !!card.cur
            spacing: Tokens.space.md
            readonly property var desc: card.cur ? WeatherState.describe(card.cur.weather_code, card.cur.is_day === 1) : null
            Icon {
                name: parent.desc ? parent.desc.icon : ""
                size: 56
                filled: true
                color: card.cur && card.cur.is_day === 1 ? Colors.m3primary : Colors.m3tertiary
            }
            ColumnLayout {
                spacing: 0
                Text {
                    text: card.cur ? WeatherState.temp(card.cur.temperature_2m) : ""
                    color: Colors.m3onSurface
                    font.family: Tokens.font.ui
                    font.pixelSize: 40
                    font.weight: Tokens.weight.semibold
                    font.features: Tokens.tabularNumbers
                }
                Text {
                    text: parent.parent.desc ? parent.parent.desc.text + " · sensación " + WeatherState.temp(card.cur.apparent_temperature) : ""
                    color: Colors.m3onSurfaceVariant
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.label
                }
            }
        }
        // Detalles.
        Flow {
            visible: !!card.cur
            Layout.fillWidth: true
            spacing: Tokens.space.md
            component Stat: Row {
                property string icon
                property string text
                spacing: Tokens.space.xs
                Icon { anchors.verticalCenter: parent.verticalCenter; name: parent.icon; size: Tokens.icon.sm; color: Colors.m3onSurfaceVariant }
                Text { anchors.verticalCenter: parent.verticalCenter; text: parent.text; color: Colors.m3onSurfaceVariant; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; font.features: Tokens.tabularNumbers }
            }
            Stat { icon: "water_drop"; text: card.cur ? card.cur.relative_humidity_2m + " %" : "" }
            Stat { icon: "air"; text: card.cur ? Math.round(card.cur.wind_speed_10m) + " km/h" : "" }
            Stat { icon: "umbrella"; text: card.days.length ? (card.days[0].rain || 0) + " %" : "" }
            Stat { icon: "wb_twilight"; text: card.d && card.d.daily ? card.d.daily.sunrise[0].slice(11, 16) + " · " + card.d.daily.sunset[0].slice(11, 16) : "" }
        }
        // Proximas horas.
        RowLayout {
            visible: card.hours.length > 0
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: card.hours
                ColumnLayout {
                    required property var modelData
                    Layout.preferredWidth: card.cardWidth / 6
                    spacing: 2
                    Text { Layout.alignment: Qt.AlignHCenter; text: modelData.label; color: Colors.m3outline; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; font.features: Tokens.tabularNumbers }
                    Icon { Layout.alignment: Qt.AlignHCenter; name: WeatherState.describe(modelData.code, modelData.day).icon; size: Tokens.icon.md; color: Colors.m3onSurfaceVariant }
                    Text { Layout.alignment: Qt.AlignHCenter; text: WeatherState.temp(modelData.t); color: Colors.m3onSurface; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.features: Tokens.tabularNumbers }
                }
            }
        }
        Rectangle { visible: card.days.length > 0; Layout.fillWidth: true; implicitHeight: 1; color: Colors.m3outlineVariant }
        // Proximos dias con barra minima-maxima (escala de la semana).
        Repeater {
            model: card.days
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Tokens.space.sm
                Text { Layout.preferredWidth: 40; text: modelData.label; color: Colors.m3onSurface; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.weight: Tokens.weight.medium }
                Icon { name: WeatherState.describe(modelData.code, true).icon; size: Tokens.icon.sm; color: Colors.m3onSurfaceVariant }
                Text { Layout.preferredWidth: 40; text: modelData.rain > 0 ? modelData.rain + " %" : ""; color: Colors.m3tertiary; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; font.features: Tokens.tabularNumbers }
                Item { Layout.fillWidth: true }
                Text { Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight; text: WeatherState.temp(modelData.min); color: Colors.m3outline; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.features: Tokens.tabularNumbers }
                Rectangle {
                    implicitWidth: 64
                    implicitHeight: 4
                    radius: 2
                    color: Colors.m3surfaceContainerHighest
                    readonly property real span: Math.max(1, card.weekMax - card.weekMin)
                    Rectangle {
                        x: (modelData.min - card.weekMin) / parent.span * parent.width
                        width: Math.max(4, (modelData.max - modelData.min) / parent.span * parent.width)
                        height: 4
                        radius: 2
                        color: Colors.m3primary
                    }
                }
                Text { Layout.preferredWidth: 36; text: WeatherState.temp(modelData.max); color: Colors.m3onSurface; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.features: Tokens.tabularNumbers }
            }
        }
        Text {
            visible: !!card.d && card.status === "ok"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: "Actualizado " + WeatherState.ago(card.now - WeatherState.fetchedAt) + " · Open-Meteo"
            color: Colors.m3outline
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
        }
        Text {
            visible: !!card.d && card.status !== "ok"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: "Datos de Open-Meteo"
            color: Colors.m3outline
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
        }
    }

    // ---- Vista de ubicacion (primera configuracion o "Cambiar") -----------------
    ColumnLayout {
        id: picker
        visible: card.picking || !WeatherState.configured
        width: card.cardWidth
        spacing: Tokens.space.sm

        onVisibleChanged: if (picker.visible) {
            field.text = "";
            WeatherState.searchResults = [];
            if (card.active) field.forceActiveFocus();
        }

        RowLayout {
            visible: WeatherState.configured
            Layout.fillWidth: true
            TextButton { label: "Volver"; icon: "arrow_back"; onClicked: card.picking = false }
            Item { Layout.fillWidth: true }
        }
        Icon {
            visible: !WeatherState.configured
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.space.sm
            name: "partly_cloudy_day"
            size: 48
            color: Colors.m3onSurfaceVariant
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: WeatherState.configured ? Text.AlignLeft : Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: WeatherState.configured ? "Cambiar la ubicación" : "Elige tu ciudad para ver el clima"
            color: Colors.m3onSurface
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
            color: Colors.m3surfaceContainerHighest
            RowLayout {
                id: curRow
                anchors.fill: parent
                anchors.margins: Tokens.space.sm
                spacing: Tokens.space.sm
                Icon { name: "place"; size: Tokens.icon.sm; color: Colors.m3primary }
                Column {
                    Layout.fillWidth: true
                    Text { text: "Ubicación actual"; color: Colors.m3outline; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption }
                    Text { width: parent.width; text: WeatherState.location ? WeatherState.location.name + (WeatherState.location.detail ? " · " + WeatherState.location.detail : "") : ""; color: Colors.m3onSurface; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.label; font.weight: Tokens.weight.medium; elide: Text.ElideRight }
                }
                TextButton { label: "Quitar"; icon: "delete"; danger: true; onClicked: { WeatherState.clearLocation(); card.picking = false; } }
            }
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: WeatherState.configured ? Text.AlignLeft : Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "Se guarda solo en este equipo. Se consulta Open-Meteo con coordenadas aproximadas (≈ 10 km) cada 30 minutos; sin ubicación no se consulta nada."
            color: Colors.m3onSurfaceVariant
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
        }
        // Busqueda.
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Tokens.row.heightLarge - 4
            radius: Tokens.radius.md
            color: Colors.m3surfaceContainerHighest
            border.width: 1
            border.color: field.activeFocus ? Colors.m3primary : Colors.m3outlineVariant
            Icon { id: searchIcon; anchors.left: parent.left; anchors.leftMargin: Tokens.space.sm; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: Tokens.icon.sm; color: Colors.m3onSurfaceVariant }
            TextInput {
                id: field
                objectName: "weatherSearch"
                anchors.fill: parent
                anchors.leftMargin: Tokens.space.sm * 2 + searchIcon.width
                anchors.rightMargin: Tokens.space.sm
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.m3onSurface
                selectionColor: Colors.m3primary
                selectedTextColor: Colors.m3onPrimary
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
                clip: true
                onTextChanged: searchDelay.restart()
                Keys.onReturnPressed: {
                    if (!WeatherState.searchResults.length) return;
                    WeatherState.setLocation(WeatherState.searchResults[0]);
                    card.picking = false;
                }
                Keys.onEscapePressed: {
                    if (card.picking && WeatherState.configured) card.picking = false;
                    else card.closeRequested();
                }
            }
            Text {
                visible: field.text.length === 0
                anchors.left: field.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Buscar ciudad…"
                color: Colors.m3onSurfaceVariant
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
            }
            // Una busqueda al dejar de escribir, no una por tecla.
            Timer { id: searchDelay; interval: 400; onTriggered: WeatherState.search(field.text) }
        }
        Text {
            visible: WeatherState.searching || WeatherState.searchFailed || (field.text.trim().length >= 2 && !WeatherState.searching && WeatherState.searchResults.length === 0)
            Layout.fillWidth: true
            text: WeatherState.searching ? "Buscando…" : WeatherState.searchFailed ? "No se pudo buscar (¿sin conexión?)" : "Sin resultados"
            color: Colors.m3onSurfaceVariant
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
        }
        Repeater {
            model: WeatherState.searchResults
            Rectangle {
                id: res
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 44
                radius: Tokens.radius.md
                color: res.index === 0 ? Colors.m3secondaryContainer : "transparent"
                StateLayer { hovered: resMouse.containsMouse; pressed: resMouse.pressed }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Tokens.space.md
                    width: parent.width - Tokens.space.md * 2
                    Text { width: parent.width; text: res.modelData.name; color: res.index === 0 ? Colors.m3onSecondaryContainer : Colors.m3onSurface; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.body; font.weight: Tokens.weight.medium; elide: Text.ElideRight }
                    Text { width: parent.width; text: res.modelData.detail; color: res.index === 0 ? Colors.m3onSecondaryContainer : Colors.m3onSurfaceVariant; font.family: Tokens.font.ui; font.pixelSize: Tokens.type.caption; elide: Text.ElideRight }
                }
                MouseArea {
                    id: resMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        WeatherState.setLocation(res.modelData);
                        card.picking = false;
                    }
                }
            }
        }
    }
}
