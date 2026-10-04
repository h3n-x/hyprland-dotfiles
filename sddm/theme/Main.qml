// Greeter de SDDM (Fase 9 B3, P9.4-P9.5): la misma pantalla de entrada que el
// bloqueo (login/LoginStage.qml, composicion "Material You"), con las
// tarjetas como acciones: apagar, reiniciar, suspender (si se puede) y la
// sesion (un clic pasa a la siguiente). Antes de iniciar sesion no hay datos
// del usuario que mostrar: no hay tarjetas de estado.
//
// Secuencia: entra sobre el fondo ya difuminado (el mismo que deja Plymouth);
// al aceptar la contrasena el candado se abre (M6) y sale todo hasta el
// wallpaper nitido, el mismo que muestra la sesion al arrancar (M2).
//
// Este archivo y SddmAuth.qml son la fuente del repo (sddm/theme/); login/,
// Tokens.qml, SemanticPalette.qml y modules/Icon.qml se copian de dotshell, y
// Colors.qml lo genera matugen (sddm-theme-stage arma el tema completo).
// API de SDDM: sddm, userModel, sessionModel, keyboard (propiedades de contexto).
import QtQuick
import "login"

Item {
    id: root
    width: 1920
    height: 1080

    // ---- Usuario y sesion ------------------------------------------------------------------
    property var userNames: []
    property var sessionNames: []
    Instantiator {
        model: userModel
        delegate: QtObject {
            required property int index
            required property string name
            Component.onCompleted: {
                const a = root.userNames.slice();
                a[index] = name;
                root.userNames = a;
            }
        }
    }
    Instantiator {
        model: sessionModel
        delegate: QtObject {
            required property int index
            required property string name
            Component.onCompleted: {
                const a = root.sessionNames.slice();
                a[index] = name;
                root.sessionNames = a;
            }
        }
    }
    readonly property string user: userModel.lastUser || root.userNames[0] || ""
    property int session: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    SddmAuth {
        id: sddmAuth
        user: root.user
        session: root.session
        onSucceeded: {
            stage.success = true;
            beat.restart();
        }
    }
    // M6: un instante con el candado abierto, despues la salida (M2).
    Timer {
        id: beat
        interval: Tokens.motion.short
        onTriggered: stage.exit()
    }

    // ---- Reloj: un tic al cambiar el minuto (sin consultas cada segundo) ------------------
    property date now: new Date()
    Timer {
        id: minute
        running: true
        interval: 60000 - (Date.now() % 60000) + 50
        onTriggered: {
            root.now = new Date();
            minute.interval = 60000 - (Date.now() % 60000) + 50;
            minute.restart();
        }
    }

    // ---- Acciones ------------------------------------------------------------------------------
    readonly property var actions: {
        const r = [];
        if (sddm.canPowerOff) r.push({ key: "poweroff", icon: "power_settings_new", title: "Apagar", sub: "Apagar el equipo" });
        if (sddm.canReboot) r.push({ key: "reboot", icon: "restart_alt", title: "Reiniciar", sub: "Volver a arrancar" });
        if (sddm.canSuspend) r.push({ key: "suspend", icon: "bedtime", title: "Suspender", sub: "Dormir el equipo" });
        if (root.sessionNames.length > 0)
            r.push({ key: "session", icon: "desktop_windows", title: "Sesión", sub: root.sessionNames[root.session] || "" });
        return r;
    }
    function act(key: string): void {
        if (key === "poweroff") sddm.powerOff();
        else if (key === "reboot") sddm.reboot();
        else if (key === "suspend") sddm.suspend();
        else if (key === "session" && root.sessionNames.length > 0) root.session = (root.session + 1) % root.sessionNames.length;
        stage.focusField();
    }

    LoginStage {
        id: stage
        objectName: "stage"
        anchors.fill: parent
        auth: sddmAuth
        avatar: Qt.resolvedUrl("face.png")
        user: root.user
        subtitle: "iniciar sesión"
        successText: "Iniciando sesión…"
        capsLock: keyboard.capsLock
        date: root.now
        tiles: root.actions
        tilesTitle: "INICIO"
        tilesActionable: true
        blurFrom: 1
        onTileActivated: key => root.act(key)
    }
}
