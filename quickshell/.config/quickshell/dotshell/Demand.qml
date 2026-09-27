// Demanda de un servicio (Fase 8 B3, P8.2): la unica forma de que un servicio
// compartido trabaje solo mientras alguien lo mira. El servicio la declara y
// reacciona a active; las vistas la piden con una Subscription.
//
//   property Demand detail: Demand { name: "system.detail"; onActiveChanged: ... }
//   Subscription { demand: SystemState.detail; active: view.visible }
//
// active = hay al menos un suscriptor. idleRelease (ms): cuanto esperar despues
// del ultimo suscriptor antes de soltar los datos pesados (released); 0 = al
// instante. Un nuevo suscriptor dentro de ese plazo lo cancela (reabrir rapido
// no recarga nada). Toda demanda se anota en Services (services.status()).
import QtQuick

QtObject {
    id: root

    property string name: ""
    property int idleRelease: 0
    readonly property int count: root._count
    readonly property bool active: root._count > 0
    // Hay datos cargados que todavia no se soltaron.
    property bool holding: false
    property real since: 0

    // Soltar los datos pesados (listas, muestras): lo emite despues de idleRelease.
    signal released()

    property int _count: 0
    function acquire(): void {
        root._count += 1;
        if (root._count === 1) {
            root.since = Date.now();
            root.holding = true;
            releaseTimer.stop();
        }
    }
    function release(): void {
        if (root._count <= 0) {
            console.warn("Demand " + root.name + ": release sin acquire");
            return;
        }
        root._count -= 1;
        if (root._count === 0) {
            root.since = Date.now();
            if (root.idleRelease > 0) releaseTimer.restart();
            else root.drop();
        }
    }
    function drop(): void {
        if (!root.holding || root._count > 0) return;
        root.holding = false;
        root.released();
    }
    property Timer releaseTimer: Timer {
        interval: Math.max(1, root.idleRelease)
        onTriggered: root.drop()
    }

    Component.onCompleted: Services.register(root)
}
