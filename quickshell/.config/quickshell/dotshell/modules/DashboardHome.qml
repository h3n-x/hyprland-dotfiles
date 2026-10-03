// Inicio del dashboard (Fase 4 B7): la vista principal. Tres niveles:
//   contexto      hora, fecha, avisos (solo si hay) y clima; sin superficie
//   protagonista  el reproductor, solo mientras hay uno (MediaHero)
//   instrumentos  estado general del equipo y escritorios
//
// Con musica el reloj se reduce a la linea de contexto y el titulo de la
// cancion es el texto mas grande; sin musica el reloj crece al tamano del de
// la pantalla de bloqueo (80 px) y el panel queda mas bajo, sin huecos. El
// paso entre los dos es un solo movimiento: hora y fecha se mueven y cambian
// de tamano como el mismo elemento mientras el reproductor se abre o cierra.
//
// Teclado (Dashboard.qml le pasa las teclas): Tab / Mayus+Tab mueven el
// anillo de foco entre zonas; con el foco en el reproductor, sus teclas
// (MediaHero); en escritorios, izquierda/derecha + Enter (sin elegir uno:
// la vista Escritorios); en la linea de contexto y en sistema, Enter abre su
// vista (Hoy, Sistema); 1-9 van a ese workspace desde cualquier lugar. Un
// clic en la fecha o el clima abre Hoy; en el estado del equipo, Sistema.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import ".." // Colors.qml, Tokens.qml, MediaState.qml, WeatherState.qml, MaintenanceState.qml, NotificationState.qml, ControlCenterState.qml, DashboardState.qml

Item {
    id: home
    // El panel se ve de verdad (Presence): liga relojes y animaciones.
    property bool active: false
    property string screenName: ""
    // Dashboard angosto: una sola regla de reacomodo (sistema arriba,
    // escritorios debajo).
    property bool narrow: false
    // Zona con el anillo de foco ("" = ninguna).
    property string focusKey: ""
    // Abrir una vista de detalle desde su zona (Dashboard.qml la muestra).
    signal openView(string view)
    // Rectangulo de una zona en las coordenadas de "target" (de donde sale la
    // transicion de contenedor).
    function zoneRect(key: string, target: Item): rect {
        const z = key === "system" ? systemZone : key === "workspaces" ? workspacesZone : key === "today" || key === "maintenance" ? context : null;
        if (!z) return Qt.rect(0, 0, target.width, 0);
        const p = z.mapToItem(target, 0, 0);
        return Qt.rect(p.x, p.y, z.width, z.height);
    }

    implicitHeight: col.implicitHeight

    readonly property bool hasMedia: !!MediaState.active

    // ---- Con musica / sin musica: un solo valor que mueve todo ----------------
    // 1 = con reproductor. Se anima solo con el panel visible; al abrir va
    // directo al estado actual.
    property real mediaP: home.hasMedia ? 1 : 0
    NumberAnimation {
        id: mediaAnim
        target: home
        property: "mediaP"
        duration: Tokens.motion.medium
        // Cambio de tamano grande: la curva estandar (una de entrada hace el
        // 90 % en el primer tercio y el reloj "salta").
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.motion.easeStandard
    }
    onHasMediaChanged: {
        const to = home.hasMedia ? 1 : 0;
        if (!home.hasMedia && home.focusKey === "media") home.focusKey = "";
        if (home.active && Tokens.motion.scale > 0) {
            mediaAnim.to = to;
            mediaAnim.restart();
        } else {
            mediaAnim.stop();
            home.mediaP = to;
        }
    }
    function lerp(a: real, b: real, t: real): real {
        return a + (b - a) * t;
    }
    function mix(a: color, b: color, t: real): color {
        return Qt.rgba(home.lerp(a.r, b.r, t), home.lerp(a.g, b.g, t), home.lerp(a.b, b.b, t), home.lerp(a.a, b.a, t));
    }

    // ---- Apertura -------------------------------------------------------------------
    // Con algo sonando, el foco empieza en el reproductor. Las tres franjas
    // entran escalonadas 0/40/80 ms (como los textos del reproductor en B5).
    function prepare(): void {
        mediaAnim.stop();
        home.mediaP = home.hasMedia ? 1 : 0;
        strip.reset();
        const playing = !!MediaState.active && MediaState.active.isPlaying;
        home.focusKey = playing ? "media" : "";
        for (const band of [context, heroBox, instruments]) {
            band.opacity = Tokens.motion.scale > 0 ? 0 : 1;
            band.lift = Tokens.motion.scale > 0 ? Tokens.space.xs : 0;
        }
        if (Tokens.motion.scale > 0) enter.restart();
    }
    ParallelAnimation {
        id: enter
        component Band: SequentialAnimation {
            id: band
            property Item target
            property int delay
            PauseAnimation { duration: Math.round(band.delay * Tokens.motion.scale) }
            ParallelAnimation {
                NumberAnimation { target: band.target; property: "opacity"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
                NumberAnimation { target: band.target; property: "lift"; to: 0; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
            }
        }
        Band { target: context; delay: 0 }
        Band { target: heroBox; delay: 40 }
        Band { target: instruments; delay: 80 }
    }

    // ---- Teclado --------------------------------------------------------------------
    readonly property var zones: ["today"].concat(home.hasMedia ? ["media"] : [], ["system", "workspaces"])
    function handleKey(event: var): bool {
        const plain = !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier));
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            const z = home.zones;
            const i = z.indexOf(home.focusKey);
            const back = event.key === Qt.Key_Backtab;
            home.focusKey = i < 0 ? (back ? z[z.length - 1] : z[0]) : z[(i + (back ? -1 : 1) + z.length) % z.length];
            if (home.focusKey !== "workspaces") strip.selected = -1;
            return true;
        }
        if (plain && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            strip.pick(event.key - Qt.Key_0);
            return true;
        }
        const enter = event.key === Qt.Key_Return || event.key === Qt.Key_Enter;
        if (enter && (home.focusKey === "system" || home.focusKey === "today")) {
            home.openView(home.focusKey);
            return true;
        }
        if (home.focusKey === "media") return hero.handleKey(event);
        if (home.focusKey === "workspaces") {
            if (strip.handleKey(event)) return true;
            // Enter sin un escritorio elegido: la vista Escritorios.
            if (enter) {
                home.openView("workspaces");
                return true;
            }
        }
        return false;
    }

    // ---- Avisos (solo los que existen) ----------------------------------------------
    readonly property int notificationCount: NotificationState.server.trackedNotifications.values.length
    readonly property var notices: {
        const list = [];
        // Actualizaciones y mantenimiento abren la vista Mantenimiento (B9-b).
        const updates = MaintenanceState.updateCount;
        if (updates > 0)
            list.push({ key: "updates", icon: "download", filled: true, n: updates,
                        full: updates + (updates === 1 ? " actualización" : " actualizaciones") });
        const warn = MaintenanceState.attention.length;
        if (warn > 0)
            list.push({ key: "maintenance", icon: "build", filled: false, n: warn,
                        full: "Mantenimiento · " + warn + (warn === 1 ? " aviso" : " avisos") });
        if (home.notificationCount > 0)
            list.push({ key: "notifications", icon: "notifications", filled: false, n: home.notificationCount,
                        full: home.notificationCount + (home.notificationCount === 1 ? " aviso" : " avisos") });
        if (NotificationState.doNotDisturb)
            list.push({ key: "dnd", icon: "do_not_disturb_on", filled: false, n: 0, full: "No molestar" });
        return list;
    }
    function actOn(key: string): void {
        if (key === "updates" || key === "maintenance") {
            DashboardState.showView("maintenance");
            return;
        }
        DashboardState.close();
        ControlCenterState.visible = true;
    }

    // Un bloque escalado que ocupa su tamano escalado en el layout.
    component Scaled: Item {
        id: sc
        property real k: 1
        default property Item child
        implicitWidth: sc.child ? sc.child.implicitWidth * sc.k : 0
        implicitHeight: sc.child ? sc.child.implicitHeight * sc.k : 0
        onChildChanged: if (sc.child) {
            sc.child.parent = sc;
            sc.child.transformOrigin = Item.TopLeft;
        }
        Binding { target: sc.child; property: "scale"; value: sc.k; when: !!sc.child }
    }

    SystemClock {
        id: clock
        enabled: home.active
        precision: SystemClock.Minutes
    }
    readonly property var es: Qt.locale("es_ES")

    Column {
        id: col
        width: home.width
        spacing: Tokens.space.md

        // ===== Contexto =====
        Item {
            id: context
            property real lift: 0
            transform: Translate { y: context.lift }
            width: parent.width
            height: home.lerp(132, 48, home.mediaP)

            // Fecha y clima llevan a Hoy (los avisos tienen su propio clic).
            Rectangle {
                anchors.fill: parent
                radius: Tokens.radius.md
                color: "transparent"
                StateLayer { hovered: contextMouse.containsMouse; pressed: contextMouse.pressed }
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 2
                    border.color: Colors.accent
                    opacity: home.focusKey === "today" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Tokens.motion.fast } }
                }
                MouseArea {
                    id: contextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: home.openView("today")
                }
            }

            Scaled {
                id: timeBlock
                x: Tokens.space.md
                anchors.verticalCenter: parent.verticalCenter
                k: home.lerp(1, Tokens.type.display / Tokens.type.hero, home.mediaP)
                Text {
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.hero
                    font.weight: Tokens.weight.semibold
                    font.letterSpacing: home.lerp(-2, 0, home.mediaP)
                    font.features: Tokens.tabularNumbers
                }
            }
            Scaled {
                anchors.left: timeBlock.right
                anchors.leftMargin: home.lerp(Tokens.space.xl, Tokens.space.md, home.mediaP)
                anchors.verticalCenter: parent.verticalCenter
                k: home.lerp(1, Tokens.type.body / Tokens.type.headline, home.mediaP)
                Text {
                    text: WeatherState.cap(home.es.standaloneDayName(clock.date.getDay(), Locale.LongFormat)) + ", "
                        + clock.date.getDate() + " de " + home.es.standaloneMonthName(clock.date.getMonth(), Locale.LongFormat)
                    color: home.mix(Colors.text, Colors.textMuted, home.mediaP)
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.headline
                    font.weight: Tokens.weight.medium
                }
            }

            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: Tokens.space.md
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.space.lg

                // Avisos: con musica, solo el numero.
                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Tokens.space.xs
                    Repeater {
                        model: home.notices
                        Rectangle {
                            id: chip
                            required property var modelData
                            readonly property string label: home.mediaP > 0.5 && chip.modelData.n > 0 ? String(chip.modelData.n) : chip.modelData.full
                            implicitHeight: 26
                            implicitWidth: chipRow.implicitWidth + Tokens.space.md * 2
                            radius: 13
                            color: chip.modelData.filled ? Colors.accentAltContainer : "transparent"
                            border.width: chip.modelData.filled ? 0 : 1
                            border.color: Colors.divider
                            Behavior on implicitWidth { enabled: home.active; NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
                            clip: true
                            // Un aviso nuevo con el panel abierto entra creciendo.
                            Component.onCompleted: if (home.active && Tokens.motion.scale > 0) chipIn.start()
                            ParallelAnimation {
                                id: chipIn
                                NumberAnimation { target: chip; property: "scale"; from: 0.8; to: 1; duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
                                NumberAnimation { target: chip; property: "opacity"; from: 0; to: 1; duration: Tokens.motion.short }
                            }
                            StateLayer { hovered: chipMouse.containsMouse; pressed: chipMouse.pressed }
                            Row {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 5
                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: chip.modelData.icon
                                    filled: chip.modelData.filled
                                    size: Tokens.icon.sm
                                    color: chip.modelData.filled ? Colors.textOnAccentAltContainer : Colors.textMuted
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: chip.label
                                    color: chip.modelData.filled ? Colors.textOnAccentAltContainer : Colors.textMuted
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.caption
                                    font.weight: Tokens.weight.medium
                                    font.features: Tokens.tabularNumbers
                                }
                            }
                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: home.actOn(chip.modelData.key)
                            }
                        }
                    }
                }

                // Clima: liviano; nunca compite con el reproductor ni los escritorios.
                RowLayout {
                    id: wx
                    visible: WeatherState.configured && !!WeatherState.current
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Tokens.space.sm
                    opacity: WeatherState.isDim(clock.date.getTime() / 1000) ? 0.55 : 1
                    readonly property var cur: WeatherState.current
                    readonly property var desc: cur ? WeatherText.describe(cur.weather_code, cur.is_day === 1) : null
                    readonly property var today: WeatherState.data && WeatherState.data.daily ? WeatherState.data.daily : null
                    Scaled {
                        Layout.alignment: Qt.AlignVCenter
                        k: home.lerp(1, 0.55, home.mediaP)
                        Icon {
                            name: wx.desc ? wx.desc.icon : ""
                            size: 40
                            color: Colors.decor
                        }
                    }
                    Column {
                        Layout.alignment: Qt.AlignVCenter
                        Scaled {
                            k: home.lerp(1, Tokens.type.title / Tokens.type.display, home.mediaP)
                            Text {
                                text: wx.cur ? WeatherState.temp(wx.cur.temperature_2m) : ""
                                color: Colors.text
                                font.family: Tokens.font.ui
                                font.pixelSize: Tokens.type.display
                                font.weight: Tokens.weight.semibold
                                font.features: Tokens.tabularNumbers
                            }
                        }
                        Text {
                            visible: !home.narrow || home.mediaP < 0.5
                            text: wx.desc ? wx.desc.text : ""
                            color: Colors.textMuted
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.label
                        }
                        // Maxima, minima y lugar: solo sin musica.
                        Text {
                            height: implicitHeight * (1 - home.mediaP)
                            opacity: 1 - home.mediaP
                            clip: true
                            text: {
                                const d = wx.today;
                                const loc = WeatherState.location ? " · " + WeatherState.location.name : "";
                                return d ? "↑ " + WeatherState.temp(d.temperature_2m_max[0]) + "  ↓ " + WeatherState.temp(d.temperature_2m_min[0]) + loc : loc;
                            }
                            color: Colors.border
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.caption
                        }
                    }
                }
            }
        }

        // ===== Reproductor =====
        Item {
            id: heroBox
            property real lift: 0
            transform: Translate { y: heroBox.lift }
            width: parent.width
            height: Math.round(hero.implicitHeight * home.mediaP)
            visible: home.mediaP > 0
            clip: true
            DashZone {
                width: parent.width
                height: hero.implicitHeight
                tinted: false
                padding: 0
                focused: home.focusKey === "media"
                opacity: home.mediaP
                MediaHero {
                    id: hero
                    anchors.fill: parent
                    active: home.active && home.hasMedia
                }
            }
        }

        // ===== Estado general + escritorios =====
        GridLayout {
            id: instruments
            property real lift: 0
            transform: Translate { y: instruments.lift }
            width: parent.width
            columns: home.narrow ? 1 : 2
            columnSpacing: Tokens.space.md
            rowSpacing: Tokens.space.md

            DashZone {
                id: systemZone
                Layout.preferredWidth: home.narrow ? instruments.width : 272
                Layout.preferredHeight: home.narrow ? 112 : 148
                focused: home.focusKey === "system"
                clickable: true
                onActivated: home.openView("system")
                SystemGlance {
                    anchors.fill: parent
                    wide: home.narrow
                }
            }
            DashZone {
                id: workspacesZone
                Layout.fillWidth: true
                Layout.preferredHeight: home.narrow ? implicitHeight : 148
                // Fuera de las miniaturas (que van a su escritorio): la vista Escritorios.
                clickable: true
                onActivated: home.openView("workspaces")
                implicitHeight: strip.implicitHeight + 2 * padding
                focused: home.focusKey === "workspaces"
                WorkspaceStrip {
                    id: strip
                    anchors.fill: parent
                    screenName: home.screenName
                    live: home.active
                }
            }
        }
    }
}
