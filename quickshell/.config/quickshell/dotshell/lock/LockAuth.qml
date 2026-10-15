// Autenticacion del bloqueo (Fase 9 B1, P9.2): el unico lugar que toca la
// contrasena. PAM con el archivo lock/pam/dotfiles-lock de la configuracion
// (configDirectory: nada en /etc, sin sudo); su pila repite la parte de
// autenticacion de system-auth, faillock incluido (los include no se
// resuelven fuera de /etc/pam.d con un directorio propio).
//
// La contrasena es un buffer de texto en QML (sin TextInput): se vacia en
// cada salida (correcta, incorrecta, error, abortar) y nunca se escribe en el
// log ni sale por IPC. Todas las pantallas muestran el mismo buffer (D8).
//
// Estados: idle, checking, wrong, lockedOut (faillock: con los minutos que
// faltan), error (PAM no pudo verificar).
import QtQuick
import Quickshell
import Quickshell.Services.Pam

QtObject {
    id: auth

    signal unlocked()
    signal failed()

    property string buffer: ""
    property string state: "idle"
    property string message: ""
    readonly property bool busy: auth.state === "checking"
    readonly property bool lockedOut: auth.state === "lockedOut"

    function type(text: string): void {
        if (auth.busy || auth.lockedOut || !text) return;
        auth.buffer += text;
        if (auth.state === "wrong" || auth.state === "error") {
            auth.state = "idle";
            auth.message = "";
        }
    }
    function erase(): void {
        if (auth.busy || auth.lockedOut) return;
        auth.buffer = auth.buffer.slice(0, -1);
    }
    function clear(): void {
        if (auth.busy) return;
        auth.buffer = "";
    }
    function submit(): void {
        if (auth.busy || auth.lockedOut || auth.buffer === "") return;
        auth.settled = false;
        auth.sawLockout = false;
        auth.message = "";
        auth.state = "checking";
        auth.pam.start();
    }
    function abort(): void {
        auth.settled = true;
        if (auth.pam.active) auth.pam.abort();
        auth.buffer = "";
        if (!auth.lockedOut) auth.state = "idle";
    }

    // faillock avisa en dos mensajes: "The account is locked due to N failed
    // logins." y "(M minutes left to unlock)" (o traducidos). Los minutos
    // salen solo del segundo; mientras tanto la contrasena no se manda.
    function lockout(minutes: int): void {
        auth.message = minutes > 0 ? I18n.tr("Too many failed attempts. Enabled again in %1 min.", I18n.number(minutes))
                                   : I18n.tr("Too many failed attempts.");
        auth.state = "lockedOut";
        auth.lockoutEnd.interval = Math.max(1, minutes) * 60000;
        auth.lockoutEnd.restart();
    }
    property Timer lockoutEnd: Timer {
        onTriggered: {
            auth.message = "";
            auth.state = "idle";
        }
    }

    // Cada intento termina una sola vez: PAM puede avisar error y fin del
    // mismo intento.
    property bool settled: true
    property bool sawLockout: false
    function settle(kind: string): void {
        if (auth.settled) return;
        auth.settled = true;
        auth.buffer = "";
        if (auth.sawLockout) return; // el estado ya es lockedOut
        if (kind === "ok") {
            auth.message = "";
            auth.state = "idle";
            auth.unlocked();
        } else if (kind === "error") {
            auth.message = I18n.tr("Couldn't verify the password");
            auth.state = "error";
        } else {
            auth.message = I18n.tr("Wrong password");
            auth.state = "wrong";
            auth.failed();
        }
    }

    property PamContext pam: PamContext {
        configDirectory: Quickshell.env("LOCK_PAM_DIR") || Quickshell.shellPath("lock/pam")
        config: Quickshell.env("LOCK_PAM_SERVICE") || "dotfiles-lock"
        onPamMessage: {
            const text = this.message;
            const minutes = text.match(/(\d+)\s*(minute|minuto)/i);
            if (minutes) {
                auth.sawLockout = true;
                auth.lockout(parseInt(minutes[1]));
            } else if (/locked|bloquead/i.test(text)) {
                auth.sawLockout = true;
                auth.lockout(0);
            } else if (this.responseRequired) {
                if (auth.sawLockout) {
                    auth.buffer = "";
                    this.abort();
                } else {
                    this.respond(auth.buffer);
                    auth.buffer = "";
                }
            }
        }
        onCompleted: result => auth.settle(result === PamResult.Success ? "ok" : "fail")
        onError: error => auth.settle("error")
    }
}
