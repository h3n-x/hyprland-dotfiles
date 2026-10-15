// Autenticacion del greeter (Fase 9 B3): la misma interfaz que lock/LockAuth.qml
// (buffer, state, message, busy, lockedOut, type, erase, clear, submit,
// failed) sobre la API de SDDM (sddm.login, loginFailed, loginSucceeded), asi
// la tarjeta de la contrasena (login/LoginCard.qml) es la misma en los dos.
// La contrasena solo vive en `buffer`: se vacia al responder SDDM.
import QtQuick

QtObject {
    id: auth

    property string user: ""
    property int session: 0
    signal failed()
    signal succeeded()

    property string buffer: ""
    property string state: "idle"
    property string message: ""
    readonly property bool busy: auth.state === "checking"
    // SDDM no informa el bloqueo de faillock (system-login lo aplica igual).
    readonly property bool lockedOut: false

    function type(text: string): void {
        if (auth.busy || !text) return;
        auth.buffer += text;
        if (auth.state === "wrong") {
            auth.state = "idle";
            auth.message = "";
        }
    }
    function erase(): void {
        if (auth.busy) return;
        auth.buffer = auth.buffer.slice(0, -1);
    }
    function clear(): void {
        if (auth.busy) return;
        auth.buffer = "";
    }
    function submit(): void {
        if (auth.busy || auth.buffer === "" || auth.user === "") return;
        auth.message = "";
        auth.state = "checking";
        sddm.login(auth.user, auth.buffer, auth.session);
    }

    property Connections replies: Connections {
        target: sddm
        function onLoginFailed() {
            auth.buffer = "";
            auth.message = I18n.tr("Wrong password");
            auth.state = "wrong";
            auth.failed();
        }
        function onLoginSucceeded() {
            auth.buffer = "";
            auth.message = "";
            auth.state = "idle";
            auth.succeeded();
        }
    }
}
