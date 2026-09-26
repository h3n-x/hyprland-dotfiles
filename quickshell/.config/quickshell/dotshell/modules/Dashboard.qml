// Dashboard (Fase 4 B7, P4.5): el centro de la shell, un espacio propio: se
// abre solo con SUPER+A (ningun modulo de la barra lo abre), en el monitor
// enfocado. Uno por barra, centrado bajo ella; abierto en una sola pantalla a
// la vez (DashboardState). Una sola
// superficie (DropdownPanel con radio xl y la entrada larga que el spec
// reserva al dashboard) con zonas adentro, no tarjetas.
//
// Vistas: Inicio y, desde sus zonas, las de detalle: Hoy (fecha y clima),
// Sistema y Escritorios. Sin pestanas: se entra abriendo una zona (clic,
// Enter o su letra: H, S, E) y se vuelve con Esc, Retroceso o la flecha. La
// transicion es de contenedor: la zona crece desde su lugar hasta ocupar el
// panel mientras Inicio se retira, y el contenido de la vista aparece encima;
// al volver, al reves. Entre dos vistas (su letra), un fundido cruzado con la
// altura animada. Los puntos de la cabecera solo dicen donde se esta.
//
// Tamano segun SU pantalla: ancho = pantalla - 2 x 12, entre 640 y 960 px
// (bajo 820, una sola regla de reacomodo); alto maximo = pantalla - barra -
// margen, y si el contenido no entra, se desplaza adentro.
//
// Cerrado no corre nada: el muestreo del equipo (SystemState) y el
// seguimiento de ventanas (DesktopState) se piden al mostrarse y se sueltan
// al ocultarse; la vista Sistema pide su detalle solo mientras se ve.
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Colors.qml, Tokens.qml, DashboardState.qml, SystemState.qml, DesktopState.qml, WeatherState.qml

DropdownPanel {
    id: panel
    alignment: "center"
    padding: Tokens.space.md
    cardRadius: Tokens.radius.xl
    enterDuration: Tokens.motion.long
    // Inicio y las vistas animan su propia altura.
    animateHeight: false

    readonly property var scr: panel.panelWindow ? panel.panelWindow.screen : null
    open: DashboardState.visible && !!panel.scr && DashboardState.screen === panel.scr.name
    onCloseRequested: DashboardState.close()
    keyHandler: (event) => panel.handleKey(event)
    escapeHandler: () => panel.back()

    readonly property int contentWidth: panel.scr
        ? Math.max(640, Math.min(960, panel.scr.width - 2 * Tokens.screenEdge)) - 2 * panel.padding : 640
    readonly property int maxContentHeight: panel.scr
        ? panel.scr.height - Tokens.popupTop - Tokens.screenEdge - 2 * panel.padding : 600
    readonly property bool narrow: panel.contentWidth + 2 * panel.padding < 820

    // Pedir datos solo mientras se ve (en pares: mostrar -> soltar).
    property bool holding: false
    onActiveChanged: {
        // Termino de cerrarse: sin vista montada (se sueltan sus datos y capturas).
        if (!panel.active && panel.detail) {
            viewAnim.stop();
            swap.stop();
            panel.detail = "";
            panel.viewP = 0;
        }
        if (panel.active === panel.holding) return;
        panel.holding = panel.active;
        SystemState.want(panel.active);
        DesktopState.watch(panel.active);
    }
    Component.onDestruction: if (panel.holding) {
        SystemState.want(false);
        DesktopState.watch(false);
    }

    // ---- Vistas ---------------------------------------------------------------------
    // detail: la vista de detalle montada (se queda mientras se vuelve a Inicio).
    // viewP: 0 = Inicio, 1 = la vista. origin: la zona de Inicio de donde sale.
    readonly property string view: DashboardState.view
    property string detail: ""
    property real viewP: 0
    property rect origin: Qt.rect(0, 0, 0, 0)
    readonly property var titles: ({
        today: "Hoy",
        system: "Sistema",
        workspaces: "Escritorios"
    })
    readonly property var letters: ({ [Qt.Key_H]: "today", [Qt.Key_S]: "system", [Qt.Key_E]: "workspaces" })

    function back(): bool {
        if (DashboardState.view === "home") return false;
        DashboardState.showView("home");
        return true;
    }
    onViewChanged: {
        const toDetail = panel.view !== "home";
        // De una vista a otra: fundido cruzado.
        if (toDetail && panel.detail && panel.viewP === 1 && panel.detail !== panel.view) {
            if (!panel.active || Tokens.motion.scale === 0) panel.detail = panel.view;
            else swap.restart();
            return;
        }
        if (toDetail) panel.detail = panel.view;
        if (panel.detail) panel.origin = home.zoneRect(panel.detail, stack);
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
    // Fundido entre vistas: sale la actual, cambia (la altura se anima) y entra la otra.
    property real swapFade: 1
    property bool swapping: false
    SequentialAnimation {
        id: swap
        ScriptAction { script: panel.swapping = true }
        NumberAnimation { target: panel; property: "swapFade"; to: 0; duration: Tokens.motion.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeExit }
        ScriptAction { script: panel.detail = panel.view }
        NumberAnimation { target: panel; property: "swapFade"; to: 1; duration: Tokens.motion.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeEnter }
        ScriptAction { script: panel.swapping = false }
    }
    NumberAnimation {
        id: viewAnim
        target: panel
        property: "viewP"
        duration: Tokens.motion.long
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
        panel.detail = panel.view !== "home" ? panel.view : "";
        panel.viewP = panel.detail ? 1 : 0;
    }

    function handleKey(event: var): bool {
        const plain = !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier));
        // H, S, E: esa vista, desde cualquier lugar.
        const byLetter = plain ? panel.letters[event.key] : undefined;
        if (byLetter) {
            DashboardState.showView(byLetter);
            return true;
        }
        if (panel.view === "home") return home.handleKey(event);
        if (event.key === Qt.Key_Backspace) return panel.back();
        if (panel.detail === "today") return todayView.handleKey(event);
        if (panel.detail === "workspaces" && workspacesLoader.item) {
            if (plain && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                workspacesLoader.item.go(event.key - Qt.Key_0, "");
                return true;
            }
            return workspacesLoader.item.handleKey(event);
        }
        return false;
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

    // Cabecera: de que es cada vista (fecha y frescura del clima; ventanas).
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

    Flickable {
        id: scroller
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

            DashboardHome {
                id: home
                width: stack.width
                active: panel.active
                screenName: panel.scr ? panel.scr.name : ""
                narrow: panel.narrow
                onOpenView: (view) => DashboardState.showView(view)
                // Se retira: se apaga y se aleja un poco.
                visible: panel.viewP < 1
                enabled: panel.viewP === 0
                opacity: 1 - Math.min(1, panel.viewP * 2)
                scale: 1 - 0.03 * panel.viewP
                transformOrigin: Item.Top
            }

            // La zona que crece (transicion de contenedor).
            Rectangle {
                visible: !!panel.detail && panel.viewP > 0 && panel.viewP < 1
                x: panel.lerp(panel.origin.x, 0, panel.viewP)
                y: panel.lerp(panel.origin.y, 0, panel.viewP)
                width: panel.lerp(panel.origin.width, stack.width, panel.viewP)
                height: panel.lerp(panel.origin.height, panel.detailHeight, panel.viewP)
                radius: Tokens.radius.md
                color: Qt.alpha(Colors.m3surfaceContainerHighest, 0.55)
                opacity: panel.viewP < 0.7 ? 1 : 1 - (panel.viewP - 0.7) / 0.3
            }

            // La vista: cabecera comun + contenido.
            ColumnLayout {
                id: detailCol
                visible: !!panel.detail
                width: stack.width
                spacing: Tokens.space.md
                opacity: Math.max(0, Math.min(1, (panel.viewP - 0.4) / 0.6)) * panel.swapFade
                transform: Translate { y: (1 - panel.viewP) * Tokens.space.sm }

                // Cabecera: volver, titulo, contexto, puntos de lugar.
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: Tokens.space.sm
                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 18
                        color: Qt.alpha(Colors.m3onSurface, 0.06)
                        StateLayer { hovered: backMouse.containsMouse; pressed: backMouse.pressed }
                        Icon { anchors.centerIn: parent; name: "arrow_back"; size: Tokens.icon.md; color: Colors.m3onSurface }
                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panel.back()
                        }
                    }
                    Text {
                        text: panel.detail ? panel.titles[panel.detail] : ""
                        color: Colors.m3onSurface
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.title
                        font.weight: Tokens.weight.semibold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: panel.subtitle
                        color: Colors.m3outline
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.label
                        elide: Text.ElideRight
                    }
                    Row {
                        Layout.rightMargin: Tokens.space.sm
                        spacing: 6
                        Repeater {
                            model: DashboardState.views
                            Rectangle {
                                required property string modelData
                                readonly property bool here: modelData === panel.detail
                                anchors.verticalCenter: parent.verticalCenter
                                width: here ? 18 : 6
                                height: 6
                                radius: 3
                                color: here ? Colors.m3primary : Colors.m3outlineVariant
                                Behavior on width { NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard } }
                            }
                        }
                    }
                }

                TodayView {
                    id: todayView
                    Layout.fillWidth: true
                    visible: panel.detail === "today"
                    active: panel.active && panel.detail === "today"
                    narrow: panel.narrow
                    onBackRequested: panel.back()
                    onLeftSearch: panel.focusPanel()
                }
                SystemView {
                    Layout.fillWidth: true
                    visible: panel.detail === "system"
                    active: panel.active && panel.detail === "system"
                    narrow: panel.narrow
                }
                // Escritorios: solo mientras es la vista (al salir, o al terminar
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
            }
        }
    }
    // Indicador de desplazamiento (solo si no entra).
    Rectangle {
        visible: scroller.interactive
        x: scroller.width - 3
        y: scroller.visibleArea.yPosition * scroller.height
        width: 3
        height: scroller.visibleArea.heightRatio * scroller.height
        radius: 1.5
        color: Colors.m3outline
    }
}
