// Singleton central de notificaciones -- reemplaza a swaync del todo (ver
// Fase C del plan). NotificationServer NO es singleton (es un servicio
// DBus real, org.freedesktop.Notifications -- solo un proceso puede ser
// el dueno a la vez), asi que se envuelve aca adentro para que
// ControlCenter.qml (historial) y NotificationToast.qml (popups
// temporales) puedan compartir la misma instancia sin duplicar el
// servidor.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

QtObject {
    id: root

    property bool doNotDisturb: false
    // Cuantos hay en el historial (la campana de la barra, Fase 11 B2).
    readonly property int count: root.server.trackedNotifications.values.length

    // Para el bloqueo de pantalla (Fase 9 B2; otro proceso): cuantos avisos
    // llegaron desde que arranco la shell y si No molestar esta activo. Solo el
    // numero, nunca el contenido. Se escribe al llegar un aviso o cambiar No
    // molestar (nada periodico); el bloqueo lo vigila y resta el valor que vio
    // al bloquear.
    property int received: 0
    function publish(): void {
        root.lockFile.setText(JSON.stringify({ received: root.received, dnd: root.doNotDisturb }) + "\n");
    }
    onDoNotDisturbChanged: root.publish()
    Component.onCompleted: root.publish()
    property FileView lockFile: FileView {
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/dotfiles-notifications.json"
        printErrors: false
    }
    property var activeToasts: []

    // Pantallas donde se ve cada aviso, decididas al llegar (Fase 8 B6):
    // una pantalla completa o una captura que empieza despues no lo saca de
    // golpe. Clave: el aviso; valor: [nombres de pantalla].
    property var placement: new Map()

    function showToast(n) {
        const on = Quickshell.screens.map(s => s.name).filter(name => FullscreenState.allowsToast(n, name));
        root.placement.set(n, on);
        root.activeToasts = [...root.activeToasts, n];
    }
    function shownOn(n, screen) {
        const on = root.placement.get(n);
        return !on || on.indexOf(screen) >= 0;
    }

    function dismissToast(n) {
        root.placement.delete(n);
        root.activeToasts = root.activeToasts.filter(x => x !== n);
    }

    // Aviso nuevo (ya en el historial): toast o retenido.
    function present(n) {
        // Con DND activo, la notificacion igual queda en el historial
        // (tracked=true) pero no aparece como toast temporal.
        if (root.doNotDisturb) return;
        // Con el centro abierto (Fase 14 B1) entra directo a su lista, donde se
        // ve: un toast en la misma esquina lo taparia. Suena igual.
        if (ControlCenterState.visible) {
            root.chime();
            return;
        }
        // Pantalla completa o captura en todas las pantallas: queda en el
        // historial y cuenta para el resumen (FullscreenState).
        if (Quickshell.screens.some(s => FullscreenState.allowsToast(n, s.name))) {
            root.showToast(n);
            root.chime();
        } else FullscreenState.hold(n);
    }
    // Sonido al llegar (notifications.sound, Fase 10 B4): solo si se ve.
    function chime(): void {
        if (SettingsState.value("notifications.sound") === true)
            Quickshell.execDetached(["paplay", "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"]);
    }
    // Al abrir el centro, los toasts en pantalla se van (ya estan en su lista).
    property Connections centerOpen: Connections {
        target: ControlCenterState
        function onVisibleChanged(): void {
            if (ControlCenterState.visible) {
                root.placement.clear();
                root.activeToasts = [];
            }
        }
    }

    // Resumen al salir de pantalla completa o de una captura (FullscreenState):
    // no es una notificacion (no va al historial); "Ver" abre el centro de
    // control, donde quedaron las retenidas.
    function showSummary(text) {
        const s = {
            id: -1, urgency: NotificationUrgency.Normal, expireTimeout: 0, appIcon: "", appName: "", hints: ({}),
            summary: text, body: "",
            actions: [{ text: "Ver", invoke: () => { ControlCenterState.visible = true; root.dismissToast(s); } }],
            expire: () => root.dismissToast(s),
            dismiss: () => root.dismissToast(s)
        };
        root.showToast(s);
    }

    function clearAll() {
        for (const n of root.server.trackedNotifications.values) {
            n.dismiss();
        }
    }

    property NotificationServer server: NotificationServer {
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: (notification) => {
            notification.tracked = true;
            root.received++;
            root.publish();
            notification.closed.connect(() => root.dismissToast(notification));
            root.present(notification);
        }
    }
}
