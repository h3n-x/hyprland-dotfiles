// Lo que se ve en cada pantalla bloqueada (Fase 9): la pantalla de entrada
// compartida con el greeter (login/LoginStage.qml, composicion "Material
// You") con las tarjetas "de un vistazo" de LockGlance (sin accion) y el
// cursor oculto. La entrada viene del escritorio (fondo nitido -> difuminado,
// M1); al aceptar la contrasena el candado se abre (M6) y despues sale todo
// (M2) hasta el wallpaper nitido; recien entonces lock.qml suelta la sesion.
//
// Sin imports de Quickshell.Wayland: la misma vista se prueba en una ventana
// comun fuera de pantalla (sondas).
import QtQuick
import Quickshell
import ".." // Tokens.qml
import "../login"

Item {
    id: view

    required property var auth
    // LockGlance (una por bloqueo). null = sin tarjetas ni aviso de Bloq Mayus.
    property var glance: null
    // false = la contrasena se acepto: M6 y despues la salida.
    property bool shown: true
    signal leaveFinished()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    LoginStage {
        id: stage
        anchors.fill: parent
        auth: view.auth
        avatar: "file://" + Quickshell.env("HOME") + "/.face"
        user: Quickshell.env("USER")
        subtitle: "sesión bloqueada"
        successText: "Desbloqueado"
        capsLock: view.glance ? view.glance.capsLock : false
        success: !view.shown
        date: clock.date
        tiles: view.glance ? view.glance.tiles : []
        tilesTitle: "DE UN VISTAZO"
        blurFrom: 0
        onKeyPressed: event => { if (view.glance) view.glance.noteKey(event); }
        onExitFinished: view.leaveFinished()
    }
    // M6: un instante con el candado abierto, despues la salida.
    onShownChanged: if (!view.shown) beat.restart()
    Timer {
        id: beat
        interval: Tokens.motion.short
        onTriggered: stage.exit()
    }

    // ---- Cursor ----------------------------------------------------------------------------
    // Oculto sobre el bloqueo (D11): no hay nada que tocar con el raton. No
    // acepta clics ni cambia el foco del teclado.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.BlankCursor
    }

    function focusField(): void {
        stage.focusField();
    }
}
