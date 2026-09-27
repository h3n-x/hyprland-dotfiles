// Suscripcion a una Demand (Fase 8 B3, P8.2): la pide mientras active es true,
// la suelta al pasar a false y al destruirse (un Loader que se descarga nunca
// deja un servicio andando). Nunca cuenta dos veces.
//
//   Subscription { demand: SystemState.detail; active: view.active }
import QtQuick

QtObject {
    id: root

    property var demand: null
    property bool active: false

    property var _held: null
    function _sync(): void {
        const want = root.active && root.demand ? root.demand : null;
        if (want === root._held) return;
        if (root._held) root._held.release();
        root._held = want;
        if (want) want.acquire();
    }
    onActiveChanged: root._sync()
    onDemandChanged: root._sync()
    Component.onCompleted: root._sync()
    Component.onDestruction: {
        if (root._held) root._held.release();
        root._held = null;
    }
}
