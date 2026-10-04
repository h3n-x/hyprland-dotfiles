// Bloqueo de pantalla (Fase 9 B1, P9.1-P9.2): una instancia de Quickshell
// aparte de la shell (`qs -p ~/.config/quickshell/dotshell/lock.qml`), asi un
// reinicio o una caida de `qs -c dotshell` nunca la toca. Vive en la carpeta
// de dotshell porque Quickshell no importa nada de fuera de la carpeta de la
// configuracion: comparte Tokens/Colors/componentes sin copiarlos. No vigila
// archivos (settings.watchFiles: false): editar la shell nunca recarga un
// bloqueo activo. La lanza scripts/lock al bloquear (unica
// entrada: S+L, menu de energia, centro de control, hypridle) y termina sola
// al desbloquear; si se cae con la sesion bloqueada, scripts/lock la vuelve a
// lanzar (misc:allow_session_lock_restore); si no llega a bloquear o se cae
// tres veces, abre el hyprlock de emergencia. Al reanudar, `scripts/lock
// --resume` lo recrea (Hyprland no le devuelve el teclado a la superficie).
//
// Usa el design system de la shell (Tokens, Colors) solo para leer. De los
// servicios de dotshell solo los pasivos (MediaState, BatteryState,
// WeatherText: clientes de Mpris/UPower o tablas, sin procesos ni red); nunca
// WeatherState, NotificationState ni SystemState (lock/LockGlance.qml).
// Marcas en el log para scripts/lock: "LOCK-SECURE" (el compositor confirmo el
// bloqueo) y "LOCK-UNLOCKED" (desbloqueo correcto). La contrasena nunca va al
// log.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "lock"

ShellRoot {
    id: root
    settings.watchFiles: false

    // Reducir movimiento: la misma opcion que la shell.
    Binding {
        target: Tokens.motion
        property: "scale"
        value: SettingsState.value("accessibility.reduceMotion") ? 0 : 1
    }

    readonly property string sounds: Quickshell.env("HOME") + "/.config/hypr/sounds/"
    function play(name: string): void {
        Quickshell.execDetached(["paplay", root.sounds + name]);
    }

    property bool leaving: false
    LockAuth {
        id: lockAuth
        onUnlocked: root.leaving = true
        onFailed: root.play("wrong.wav")
    }

    // Clima, musica, bateria, avisos y Bloq Mayus (B2): una instancia para
    // todas las pantallas.
    LockGlance {
        id: lockGlance
    }

    WlSessionLock {
        id: lock
        locked: true
        onSecureChanged: {
            if (!lock.secure) return;
            console.log("LOCK-SECURE " + Date.now());
            root.play("lock.wav");
        }

        WlSessionLockSurface {
            id: surface
            color: Colors.background
            LockView {
                anchors.fill: parent
                // id distinto del nombre de la propiedad: "auth: auth" se
                // resolveria a la propiedad de la propia vista (undefined).
                auth: lockAuth
                glance: lockGlance
                shown: !root.leaving
                onLeaveFinished: root.finish()
            }
        }
    }

    // La salida termina antes de soltar el bloqueo: el compositor nunca
    // muestra un salto. Con "reducir movimiento" es inmediata.
    property bool finished: false
    function finish(): void {
        if (root.finished) return;
        root.finished = true;
        lock.locked = false;
        console.log("LOCK-UNLOCKED " + Date.now());
        root.play("unlock.wav");
        Qt.callLater(Qt.quit);
    }
    // Respaldo: si la animacion no avisa (pantalla apagada), se termina igual.
    // Cubre el instante del candado abierto (M6) y la salida (M2, LoginStage).
    Timer {
        running: root.leaving
        interval: Tokens.motion.short + Math.round(Tokens.motion.long / 0.7) + 300
        onTriggered: root.finish()
    }
}
