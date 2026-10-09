// Dashboard (Fase 4 B7, P4.5): el centro de la shell, un espacio propio: se
// abre solo con SUPER+A (ningun modulo de la barra lo abre), en el monitor
// enfocado. Uno por barra, centrado bajo ella; abierto en una sola pantalla a
// la vez (DashboardState). Una sola
// superficie (AnchoredPanel con radio xl y la entrada larga que el spec
// reserva al dashboard) con zonas adentro, no tarjetas.
//
// Pestanas (Fase 12 B2): Inicio · Musica · Sistema · Escritorios (y Hoy,
// Mantenimiento si se eligen; dashboard.tabs) en una barra arriba (DashTabs).
// Se cambia con clic, Ctrl+Tab / Ctrl+Mayus+Tab, Ctrl+AvPag / Ctrl+RePag,
// Alt+1..6, las letras (H, S, E, M; L = Musica con la letra), la rueda sobre
// la barra o deslizando dos dedos a los lados. Esc o Retroceso vuelven a
// Inicio; en Inicio, Esc cierra.
// Transiciones: desde una zona de Inicio, de contenedor (la zona crece hasta
// ocupar el panel mientras Inicio se retira); por la barra o las teclas, el
// contenido se desliza hacia el lado del cambio. Una sola animacion por cambio.
//
// Las zonas de Inicio son datos (Fase 11 B4, HomeZones): se editan aca mismo
// (lapiz, Ctrl+E o "dashboard edit"); editando, todas las teclas son de la
// edicion y Esc la termina sin cerrar el panel.
//
// Tamano segun SU pantalla: ancho = pantalla - 2 x 12, entre 640 y 960 px
// (bajo 820, una sola regla de reacomodo); alto maximo = pantalla - barra -
// margen, y si el contenido no entra, se desplaza adentro.
//
// Cerrado no corre nada. Inicio vive mientras el panel esta abierto (pausado
// mientras otra pestana lo tapa); otra pestana existe solo mientras se ve (y
// durante su transicion), asi sus datos (SystemState, DesktopState, la
// letra...) se piden y se sueltan con ella.
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, DashboardState.qml, SystemState.qml, DesktopState.qml, WeatherState.qml

AnchoredPanel {
    id: panel
    align: "center"
    // Se desplaza por dentro (sus vistas); el alto lo pone maxBodyHeight.
    scrollable: false
    padding: Tokens.space.md
    cardRadius: Tokens.radius.xl
    enterDuration: Tokens.motion.long
    // Inicio y las vistas animan su propia altura.
    animateHeight: false

    readonly property var scr: panel.panelWindow ? panel.panelWindow.screen : null
    popupId: "dashboard"
    keyHandler: (event) => panel.handleKey(event)
    escapeHandler: () => panel.back()

    readonly property int contentWidth: panel.scr
        ? Math.max(Tokens.px(640), Math.min(Tokens.px(960), panel.scr.width - 2 * Tokens.screenEdge)) - 2 * panel.padding : Tokens.px(640)
    // Lo que deja la pantalla segun el lado del panel (barra arriba o a un costado), sin la barra de pestanas.
    readonly property int maxContentHeight: panel.maxBodyHeight - tabBar.implicitHeight - Tokens.space.md
    readonly property bool narrow: panel.contentWidth + 2 * panel.padding < Tokens.px(820)

    // Datos solo mientras se ve (Fase 8 B3): estado del equipo y escritorios.
    // Solo si su zona se ve en Inicio o se mira su pestana (Fase 11 B4; Fase
    // 12 B3: Inicio tapado por otra pestana no cuenta).
    readonly property bool homeSeen: panel.active && panel.viewP < 1
    property Subscription systemData: Subscription { demand: SystemState.basic; active: panel.active && ((panel.homeSeen && home.placed("system")) || panel.detail === "system") }
    property Subscription desktopData: Subscription { demand: DesktopState.live; active: panel.active && ((panel.homeSeen && home.placed("workspaces")) || panel.detail === "workspaces") }
    onActiveChanged: {
        // Termino de cerrarse: sin vista montada (se sueltan sus datos y capturas).
        if (!panel.active && panel.detail) {
            viewAnim.stop();
            swap.stop();
            panel.detail = "";
            panel.viewP = 0;
        }
    }


    // ---- Pestanas ---------------------------------------------------------------------
    // detail: la pestana montada que no es Inicio (se queda mientras se vuelve).
    // viewP: 0 = Inicio, 1 = la pestana. origin: la zona de Inicio de donde sale.
    // viaZone: se llego desde una zona (transicion de contenedor) o no (desliza).
    readonly property string tab: DashboardState.tab
    property string shown: "home"
    property string detail: ""
    property real viewP: 0
    property rect origin: Qt.rect(0, 0, 0, 0)
    property bool viaZone: false
    // Hacia donde se mueve el contenido entre dos pestanas: 1 = a la derecha.
    property int dir: 1
    readonly property var letters: ({ [Qt.Key_H]: "today", [Qt.Key_S]: "system", [Qt.Key_E]: "workspaces", [Qt.Key_M]: "maintenance" })

    function back(): bool {
        // Editando Inicio: Esc termina la edicion (o deja "Agregar").
        if (DashboardState.editing) {
            home.escapeEdit();
            return true;
        }
        if (DashboardState.tab === "home") return false;
        DashboardState.showTab("home", "back");
        return true;
    }
    onTabChanged: {
        const prev = panel.shown, next = panel.tab, all = DashboardState.all;
        panel.shown = next;
        panel.dir = all.indexOf(next) >= all.indexOf(prev) ? 1 : -1;
        const toDetail = next !== "home";
        // Volver (Esc) deshace como se llego; si no, segun de donde viene.
        if (DashboardState.via !== "back") panel.viaZone = DashboardState.via === "zone";
        // De una pestana a otra: sale una, entra la otra (se desliza). Si Inicio
        // estaba volviendo, no: la nueva sale de ahi (la animacion se invierte).
        if (toDetail && panel.detail && panel.viewP === 1 && !viewAnim.running && panel.detail !== next) {
            if (!panel.active || Tokens.motion.scale === 0) panel.detail = next;
            else swap.restart();
            return;
        }
        if (toDetail) panel.detail = next;
        if (panel.detail && panel.viaZone) panel.origin = home.zoneRect(panel.detail, stack);
        if (!panel.active || Tokens.motion.scale === 0) {
            viewAnim.stop();
            panel.viewP = toDetail ? 1 : 0;
            if (!toDetail) panel.detail = "";
            return;
        }
        viewAnim.to = toDetail ? 1 : 0;
        viewAnim.restart();
        if (!toDetail) panel.focusPanel();
    }
    // Entre dos pestanas: sale la actual hacia un lado, cambia (la altura se
    // anima) y entra la otra desde el otro.
    property real swapFade: 1
    property bool swapping: false
    property bool swapIn: false
    SequentialAnimation {
        id: swap
        ScriptAction { script: { panel.swapping = true; panel.swapIn = false; } }
        NumberAnimation { target: panel; property: "swapFade"; to: 0; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeExit }
        ScriptAction { script: { panel.detail = panel.tab; panel.swapIn = true; } }
        NumberAnimation { target: panel; property: "swapFade"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
        ScriptAction { script: panel.swapping = false }
    }
    NumberAnimation {
        id: viewAnim
        target: panel
        property: "viewP"
        duration: panel.viaZone ? Tokens.motion.long : Tokens.motion.medium
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.motion.easeStandard
        onFinished: if (panel.viewP === 0) panel.detail = ""
    }
    onOpenChanged: {
        if (!panel.open) return;
        home.prepare();
        viewAnim.stop();
        swap.stop();
        panel.swapFade = 1;
        panel.swapping = false;
        panel.shown = panel.tab;
        panel.detail = panel.tab !== "home" ? panel.tab : "";
        panel.viewP = panel.detail ? 1 : 0;
    }

    readonly property Item detailItem: {
        const l = { music: musicLoader, today: todayLoader, system: systemLoader, workspaces: workspacesLoader, maintenance: maintenanceLoader }[panel.detail];
        return l ? l.item : null;
    }

    function handleKey(event: var): bool {
        // Editando Inicio, todas las teclas son de la edicion.
        if (DashboardState.editing) return home.handleKey(event);
        const ctrl = !!(event.modifiers & Qt.ControlModifier), alt = !!(event.modifiers & Qt.AltModifier);
        const plain = !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier));
        // Ctrl+E: editar las zonas de Inicio (Fase 11 B4).
        if (event.key === Qt.Key_E && ctrl) {
            DashboardState.edit();
            return true;
        }
        // Pestanas: Ctrl+Tab / Ctrl+Mayus+Tab (Qt da Backtab), Ctrl+AvPag / Ctrl+RePag, Alt+1..6.
        if (ctrl && (event.key === Qt.Key_Tab || event.key === Qt.Key_PageDown)) {
            DashboardState.step(1);
            return true;
        }
        if (ctrl && (event.key === Qt.Key_Backtab || event.key === Qt.Key_PageUp)) {
            DashboardState.step(-1);
            return true;
        }
        if (alt && event.key >= Qt.Key_1 && event.key <= Qt.Key_6) {
            const t = DashboardState.tabs[event.key - Qt.Key_1];
            if (t) DashboardState.showTab(t, "tab");
            return true;
        }
        // H, S, E, M: esa pestana, desde cualquier lugar (desde Inicio, crece su zona).
        const byLetter = plain ? panel.letters[event.key] : undefined;
        if (byLetter) {
            DashboardState.showTab(byLetter, panel.tab === "home" ? "zone" : "tab");
            return true;
        }
        if (panel.tab === "home") {
            // L: la pestana Musica con la letra.
            if (plain && event.key === Qt.Key_L) {
                LyricsState.viewOpen = true;
                DashboardState.showTab("music", "zone");
                return true;
            }
            return home.handleKey(event);
        }
        if (event.key === Qt.Key_Backspace) return panel.back();
        const it = panel.detailItem;
        if (!it) return false;
        if (panel.detail === "workspaces" && plain && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            it.go(event.key - Qt.Key_0, "");
            return true;
        }
        return it.handleKey ? it.handleKey(event) : false;
    }

    function lerp(a: real, b: real, t: real): real {
        return a + (b - a) * t;
    }
    readonly property real detailHeight: detailCol.implicitHeight
    property real stackHeight: panel.detail ? panel.lerp(home.implicitHeight, panel.detailHeight, panel.viewP) : home.implicitHeight
    Behavior on stackHeight {
        enabled: panel.swapping
        NumberAnimation { duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
    }

    // De que es cada pestana (a la derecha de la barra): fecha y frescura del
    // clima; ventanas; el equipo.
    SystemClock {
        id: clock
        enabled: panel.active
        precision: SystemClock.Minutes
    }
    readonly property var es: Qt.locale("es_ES")
    readonly property string subtitle: {
        if (panel.detail === "system")
            return [SystemState.distro, SystemState.kernel ? "Linux " + SystemState.kernel : "",
                    DesktopState.version ? "Hyprland " + DesktopState.version : ""].filter(x => x).join(" · ");
        if (panel.detail === "today") {
            const d = clock.date;
            let s = WeatherState.cap(panel.es.standaloneDayName(d.getDay(), Locale.LongFormat)) + ", " + d.getDate() + " de "
                + panel.es.standaloneMonthName(d.getMonth(), Locale.LongFormat);
            if (WeatherState.configured && WeatherState.fetchedAt > 0)
                s += " · clima " + WeatherState.ago(d.getTime() / 1000 - WeatherState.fetchedAt) + " · Open-Meteo";
            return s;
        }
        if (panel.detail === "maintenance") {
            if (MaintenanceState.checking) return "Revisando…";
            const at = MaintenanceState.checkedAt;
            return at > 0 ? "Revisado " + WeatherState.ago(clock.date.getTime() / 1000 - at / 1000) : "";
        }
        if (panel.detail === "workspaces") {
            const wins = DesktopState.windows.filter(w => !w.hidden && w.monitor === (panel.scr ? panel.scr.name : ""));
            const spaces = {};
            for (const w of wins) spaces[w.wsId] = true;
            const n = Object.keys(spaces).length;
            return (panel.scr ? panel.scr.name + " · " : "") + wins.length + (wins.length === 1 ? " ventana" : " ventanas")
                + " en " + n + (n === 1 ? " escritorio" : " escritorios");
        }
        return "";
    }

    DashTabs {
        id: tabBar
        width: panel.contentWidth
        tabs: DashboardState.tabs
        current: panel.tab
        compact: panel.narrow
        detail: panel.viewP > 0.5 ? panel.subtitle : ""
        live: panel.active
        onPicked: (id) => DashboardState.showTab(id, "tab")
        onStepped: (delta) => DashboardState.step(delta)
    }

    Flickable {
        id: scroller
        y: tabBar.implicitHeight + Tokens.space.md
        width: panel.contentWidth
        height: Math.min(panel.stackHeight, panel.maxContentHeight)
        contentWidth: width
        contentHeight: panel.stackHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: stack
            width: scroller.width
            height: panel.stackHeight

            // Dos dedos a los lados (touchpad): la pestana de al lado.
            WheelHandler {
                acceptedDevices: PointerDevice.TouchPad
                orientation: Qt.Horizontal
                enabled: !DashboardState.editing
                property real acc: 0
                onWheel: (event) => {
                    acc += event.angleDelta.x;
                    if (Math.abs(acc) >= 240) {
                        DashboardState.step(acc < 0 ? 1 : -1);
                        acc = 0;
                    }
                }
            }

            DashboardHome {
                id: home
                width: stack.width
                // Tapado por otra pestana se pausa (Fase 12 B3): sus zonas sueltan
                // lo que piden y vuelven en cuanto Inicio empieza a volver.
                active: panel.homeSeen
                screenName: panel.scr ? panel.scr.name : ""
                narrow: panel.narrow
                onOpenView: (view) => DashboardState.showTab(view, "zone")
                onFieldDone: panel.focusPanel()
                // Se retira: se apaga y se aleja un poco (hacia la zona que crece,
                // o hacia la izquierda: Inicio es la primera pestana).
                visible: panel.viewP < 1
                enabled: panel.viewP === 0
                opacity: 1 - Math.min(1, panel.viewP * 2)
                scale: panel.viaZone ? 1 - 0.03 * panel.viewP : 1
                transformOrigin: Item.Top
                transform: Translate { x: panel.viaZone ? 0 : -Tokens.space.lg * panel.viewP }
            }

            // La zona que crece (transicion de contenedor).
            Rectangle {
                visible: panel.viaZone && !!panel.detail && panel.viewP > 0 && panel.viewP < 1
                x: panel.lerp(panel.origin.x, 0, panel.viewP)
                y: panel.lerp(panel.origin.y, 0, panel.viewP)
                width: panel.lerp(panel.origin.width, stack.width, panel.viewP)
                height: panel.lerp(panel.origin.height, panel.detailHeight, panel.viewP)
                radius: Tokens.radius.md
                color: Colors.tint(Colors.surfaceHighest, Tokens.tint.well)
                opacity: panel.viewP < 0.7 ? 1 : 1 - (panel.viewP - 0.7) / 0.3
            }

            // La pestana: solo la montada existe.
            ColumnLayout {
                id: detailCol
                visible: !!panel.detail
                width: stack.width
                spacing: 0
                opacity: (panel.viaZone ? Math.max(0, Math.min(1, (panel.viewP - 0.4) / 0.6)) : panel.viewP) * panel.swapFade
                transform: Translate {
                    x: (panel.viaZone ? 0 : Tokens.space.lg * (1 - panel.viewP))
                       + (panel.swapIn ? 1 : -1) * panel.dir * Tokens.space.lg * (1 - panel.swapFade)
                    y: panel.viaZone ? (1 - panel.viewP) * Tokens.space.sm : 0
                }

                Loader {
                    id: musicLoader
                    Layout.fillWidth: true
                    active: panel.detail === "music"
                    visible: active
                    sourceComponent: MusicTab {
                        active: panel.active && panel.detail === "music"
                        narrow: panel.narrow
                    }
                }
                Loader {
                    id: todayLoader
                    Layout.fillWidth: true
                    active: panel.detail === "today"
                    visible: active
                    sourceComponent: TodayView {
                        active: panel.active && panel.detail === "today"
                        narrow: panel.narrow
                        onBackRequested: panel.back()
                        onLeftSearch: panel.focusPanel()
                    }
                }
                Loader {
                    id: systemLoader
                    Layout.fillWidth: true
                    active: panel.detail === "system"
                    visible: active
                    sourceComponent: SystemView {
                        active: panel.active && panel.detail === "system"
                        narrow: panel.narrow
                    }
                }
                // Escritorios: solo mientras es la pestana (al salir, o al terminar
                // de cerrarse el panel, se sueltan las capturas). No ligarlo a
                // "active": cargar la vista cambia el tamano del popup y eso
                // vuelve a tocar su visibilidad (bucle a 100 % de CPU).
                Loader {
                    id: workspacesLoader
                    Layout.fillWidth: true
                    active: panel.detail === "workspaces"
                    visible: active
                    sourceComponent: WorkspacesView {
                        screenName: panel.scr ? panel.scr.name : ""
                        active: panel.active && panel.detail === "workspaces"
                        narrow: panel.narrow
                    }
                }
                Loader {
                    id: maintenanceLoader
                    Layout.fillWidth: true
                    active: panel.detail === "maintenance"
                    visible: active
                    sourceComponent: MaintenanceView {
                        active: panel.active && panel.detail === "maintenance"
                        narrow: panel.narrow
                    }
                }
            }
        }
    }
    // Indicador de desplazamiento (solo si no entra).
    Rectangle {
        visible: scroller.interactive
        x: scroller.width - 3
        y: scroller.y + scroller.visibleArea.yPosition * scroller.height
        width: 3
        height: scroller.visibleArea.heightRatio * scroller.height
        radius: 1.5
        color: Colors.border
    }
}
