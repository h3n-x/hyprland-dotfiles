// Singleton central de notificaciones -- reemplaza a swaync del todo (ver
// Fase C del plan). NotificationServer NO es singleton (es un servicio
// DBus real, org.freedesktop.Notifications -- solo un proceso puede ser
// el dueno a la vez), asi que se envuelve aca adentro para que
// ControlCenter.qml (historial) y NotificationToast.qml (popups
// temporales) puedan compartir la misma instancia sin duplicar el
// servidor.
pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: root

    property bool doNotDisturb: false
    property var activeToasts: []

    function showToast(n) {
        root.activeToasts = [...root.activeToasts, n];
    }

    function dismissToast(n) {
        root.activeToasts = root.activeToasts.filter(x => x !== n);
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
            notification.closed.connect(() => root.dismissToast(notification));
            // Con DND activo, la notificacion igual queda en el historial
            // (tracked=true arriba) pero no aparece como toast temporal.
            if (!root.doNotDisturb) root.showToast(notification);
        }
    }
}
