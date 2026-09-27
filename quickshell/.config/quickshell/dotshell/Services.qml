// Registro de demandas (Fase 8 B3, P8.2): cada Demand se anota sola. Lo lee
// el IPC services.status() (sondas, y la pagina de diagnostico del centro de
// configuracion, P10). Leer no cuesta nada: son contadores.
pragma Singleton
import QtQuick

QtObject {
    id: root

    property var demands: []
    function register(d: var): void {
        root.demands = root.demands.concat([d]);
    }
    // [{name, count, active, holding, since}] ordenado por nombre.
    function status(): var {
        return root.demands.map(d => ({ name: d.name, count: d.count, active: d.active, holding: d.holding, since: d.since }))
            .sort((a, b) => a.name.localeCompare(b.name));
    }
}
