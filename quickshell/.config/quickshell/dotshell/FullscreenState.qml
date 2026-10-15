// Pantalla completa y captura (Fase 8 B6, P8.6): el unico lugar que sabe si
// un monitor tiene una ventana en pantalla completa o se esta compartiendo,
// y la unica politica de que puede aparecer encima. Ninguna superficie
// decide por su cuenta.
//
// Clases de superficie:
//   invocada  (la pediste ahora: lanzador, energia, guia, galeria, centro de
//              control, dashboard)            -> si, encima (capa Overlay)
//   respuesta (OSD, tarjeta de captura, inicio de grabacion) -> si, encima
//   pasiva    (avisos de notificaciones)      -> segun notifications.fullscreen
//   ambiente  (barra, sus desplegables, fondo) -> no (capa Top, queda tapada)
//
// Pantalla completa de verdad: el escritorio visible del monitor tiene una
// ventana en pantalla completa (no maximizada) y no se esta mostrando el
// escritorio especial encima. Captura: Hyprland avisa "screencast" con cada
// cuadro que copia un cliente (una captura de pantalla dura < 0,5 s; una
// grabacion o una transmision, todo el tiempo): cuenta como captura si dura
// mas de 1 s, y termina 5 s despues del ultimo cuadro. Compartir una sola
// ventana no incluye las capas: no cuenta. Las grabaciones propias
// (CaptureState) cuentan siempre.
//
// Sin temporizadores ni procesos mientras no pasa nada: todo llega por
// eventos de Hyprland y propiedades reactivas.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

QtObject {
    id: root

    // ---- Pantalla completa por monitor ------------------------------------------------------
    // Escritorio especial visible por monitor (evento activespecial).
    property var special: ({})

    // nombre de monitor -> HyprlandToplevel en pantalla completa
    readonly property var fullscreenWindows: {
        const o = {};
        for (const m of Hyprland.monitors.values) {
            const ws = m.activeWorkspace;
            if (!ws || !ws.hasFullscreen || root.special[m.name]) continue;
            // hasFullscreen tambien es true con una ventana maximizada.
            const t = ws.toplevels.values.find(x => x.wayland && x.wayland.fullscreen);
            if (t) o[m.name] = t;
        }
        return o;
    }
    readonly property var fullscreen: {
        const o = {};
        for (const n in root.fullscreenWindows) o[n] = true;
        return o;
    }
    function isFullscreen(screen: string): bool {
        return !!root.fullscreen[screen];
    }
    // "game" | "video" | "other" | "" (protocolo content-type; para P12, sin
    // listas de aplicaciones).
    function kind(screen: string): string {
        if (!root.isFullscreen(screen)) return "";
        const t = root.fullscreenWindows[screen];
        const ct = t && t.lastIpcObject ? t.lastIpcObject.contentType : "";
        return ct === "game" || ct === "video" ? ct : "other";
    }

    // ---- Captura ------------------------------------------------------------------------------
    // nombre de monitor -> true mientras se graba o transmite.
    property var capture: ({})
    readonly property bool recording: CaptureState.isRecording
    function isCapturing(screen: string): bool {
        return root.recording || !!root.capture[screen];
    }
    // Inicio y ultimo cuadro por monitor (variables JS, no propiedades: una
    // grabacion manda ~120 eventos por segundo y nada se recalcula con cada uno).
    property var castStart: ({})
    property var castLast: ({})
    // Hay cuadros recientes en algun monitor (cambia solo al empezar y al
    // terminar una rafaga): mientras tanto se revisa una vez por segundo.
    property bool casting: false
    property Timer castEnd: Timer {
        interval: 1000
        repeat: true
        running: root.casting
        onTriggered: {
            const now = Date.now();
            const cap = Object.assign({}, root.capture);
            let changed = false;
            for (const n in root.castLast) {
                if (now - root.castLast[n] > 5000) {
                    delete root.castLast[n];
                    delete root.castStart[n];
                    if (cap[n]) { delete cap[n]; changed = true; }
                }
            }
            if (changed) root.capture = cap;
            if (Object.keys(root.castLast).length === 0) root.casting = false;
        }
    }
    function castFrame(screen: string): void {
        const now = Date.now();
        if (!root.castLast[screen] || now - root.castLast[screen] > 5000) root.castStart[screen] = now;
        root.castLast[screen] = now;
        if (!root.casting) root.casting = true;
        if (!root.capture[screen] && now - root.castStart[screen] >= 1000) {
            const cap = Object.assign({}, root.capture);
            cap[screen] = true;
            root.capture = cap;
        }
    }

    property Connections events: Connections {
        target: Hyprland
        function onRawEvent(event: var): void {
            if (event.name === "screencastv2") {
                // "estado,dueno,monitor"; dueno window = una ventana sola (sin capas).
                const p = event.data.split(",");
                if (p[1] !== "window" && p[2]) root.castFrame(p[2]);
            } else if (event.name === "activespecial") {
                // "nombre,monitor"; nombre vacio = se oculto.
                const i = event.data.lastIndexOf(",");
                const o = Object.assign({}, root.special);
                o[event.data.slice(i + 1)] = event.data.slice(0, i) !== "";
                root.special = o;
            }
        }
    }

    // ---- Politica -----------------------------------------------------------------------------
    // Un monitor "retiene" lo pasivo si tiene pantalla completa o captura.
    function holds(screen: string): bool {
        return root.isFullscreen(screen) || root.isCapturing(screen);
    }
    // Avisos que nunca se retienen: los de la propia shell marcados como
    // prioritarios (bateria baja y critica).
    function isPriority(n: var): bool {
        return !!n && !!n.hints && !!n.hints["x-dotfiles-priority"];
    }
    function allowsToast(n: var, screen: string): bool {
        if (!root.holds(screen) || root.isPriority(n)) return true;
        const mode = SettingsState.value("notifications.fullscreen");
        if (mode === "show") return true;
        if (mode === "critical") return n.urgency === NotificationUrgency.Critical;
        return false;
    }

    // ---- Retenidos y resumen ------------------------------------------------------------------
    property int held: 0
    property string heldReason: "" // "fullscreen" | "capture"
    function hold(n: var): void {
        root.heldReason = Object.keys(root.capture).length > 0 || root.recording ? "capture" : "fullscreen";
        root.held++;
    }
    // Al volver a haber un monitor que no retiene: un solo aviso con lo que
    // quedo en el historial (nada silencioso).
    function release(): void {
        if (root.held === 0) return;
        if (!Quickshell.screens.some(s => !root.holds(s.name))) return;
        const count = root.held;
        const capture = root.heldReason === "capture";
        root.held = 0;
        NotificationState.showSummary(capture ? I18n.trn("%n notification while you were sharing the screen", "%n notifications while you were sharing the screen", count)
                                             : I18n.trn("%n notification while you were in fullscreen", "%n notifications while you were in fullscreen", count));
    }

    // ---- Transiciones -------------------------------------------------------------------------
    // Entrar o salir de pantalla completa en un monitor cierra los popups
    // anclados de ese monitor (el dashboard cambia de ventana anfitriona,
    // D3-A); entrar cierra ademas el centro de control.
    property var previous: ({})
    onFullscreenChanged: {
        const now = root.fullscreen;
        const names = new Set([...Object.keys(root.previous), ...Object.keys(now)]);
        for (const n of names) {
            if (!!root.previous[n] === !!now[n]) continue;
            PopupState.closeAll(n);
            if (now[n]) {
                ControlCenterState.visible = false;
                Hyprland.refreshToplevels(); // contentType para kind()
            }
        }
        root.previous = now;
        root.release();
    }
    onCaptureChanged: root.release()
    onRecordingChanged: {
        root.release();
        // El indicador rojo de la barra queda tapado: el inicio y el fin de
        // una grabacion se avisan con el OSD si hay una pantalla completa.
        if (Object.keys(root.fullscreen).length > 0)
            OsdState.show(root.recording ? "radio_button_checked" : "stop_circle", -1, root.recording ? I18n.tr("Recording") : I18n.tr("Recording stopped"));
    }
}
