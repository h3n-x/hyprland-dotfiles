// Lo que se ve en cada pantalla bloqueada (Fase 9 B1): el wallpaper difuminado
// (nunca una copia del escritorio), el reloj del design system
// (Tokens.type.hero, el mismo estilo que el reloj del dashboard), la fecha, el
// avatar y el campo de contrasena. El campo esta en TODAS las pantallas y
// todas muestran el mismo buffer (D8): Hyprland puede darle el teclado a
// cualquier superficie (al conectar un monitor mueve el foco), y lo que se
// escribe se ve igual.
//
// Sin imports de Quickshell.Wayland: la misma vista se prueba en una ventana
// comun fuera de pantalla (sondas).
import QtQuick
import QtQuick.Effects
import Quickshell
import ".." // Colors.qml, Tokens.qml
import "../modules" // Surface, Icon

Item {
    id: view

    required property var auth
    // false = salida en curso (animacion de desbloqueo).
    property bool shown: true
    signal leaveFinished()

    readonly property var es: Qt.locale("es_ES")
    function cap(s: string): string {
        return s ? s.charAt(0).toUpperCase() + s.slice(1) : s;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---- Fondo -----------------------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: Colors.background
    }
    Image {
        id: wallpaper
        anchors.fill: parent
        source: Colors.image ? "file://" + Colors.image : ""
        fillMode: Image.PreserveAspectCrop
        // Sincronica: el primer cuadro del bloqueo ya trae el fondo (sin el
        // salto de color liso a wallpaper, V0-7c). Cuesta ≈ 50 ms antes de ese
        // primer cuadro (PNG 2560x1440); el bloqueo completo aparece cuando antes.
        asynchronous: false
        // El mismo tamano en todas las pantallas: una sola decodificacion
        // compartida (cache), no una por pantalla (≈ −6.6 MB por pantalla extra).
        sourceSize.width: 1920
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        brightness: -0.12
    }
    Rectangle {
        anchors.fill: parent
        color: Colors.tint(Colors.scrim, Tokens.opacity.scrim)
    }

    // ---- Contenido ---------------------------------------------------------------------------
    Item {
        id: content
        anchors.fill: parent
        opacity: view.shown ? 1 : 0
        scale: view.shown ? 1 : 0.96
        Behavior on opacity {
            NumberAnimation { duration: Tokens.motion.long; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
        }
        Behavior on scale {
            NumberAnimation { duration: Tokens.motion.long; easing.type: Easing.BezierSpline; easing.bezierCurve: Tokens.motion.easeStandard }
        }
        onOpacityChanged: if (!view.shown && content.opacity === 0) view.leaveFinished()

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.18)
            spacing: Tokens.space.sm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.hero
                font.weight: Tokens.weight.semibold
                font.letterSpacing: -2
                font.features: Tokens.tabularNumbers
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: view.cap(view.es.standaloneDayName(clock.date.getDay(), Locale.LongFormat)) + ", "
                    + clock.date.getDate() + " de " + view.es.standaloneMonthName(clock.date.getMonth(), Locale.LongFormat)
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.headline
                font.weight: Tokens.weight.medium
            }
        }

        Column {
            id: login
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(parent.height * 0.16)
            spacing: Tokens.space.md

            // Avatar: ~/.face (lo escribe theme-apply.sh).
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 72
                height: 72
                Image {
                    id: face
                    anchors.fill: parent
                    source: "file://" + Quickshell.env("HOME") + "/.face"
                    sourceSize.width: 144
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    visible: false
                }
                Rectangle {
                    id: faceMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {
                    anchors.fill: parent
                    source: face
                    maskEnabled: true
                    maskSource: faceMask
                    visible: face.status === Image.Ready
                }
                Icon {
                    anchors.centerIn: parent
                    visible: face.status !== Image.Ready
                    name: "account_circle"
                    size: 72
                    color: Colors.textMuted
                }
            }

            // Campo de contrasena: puntos, sin texto real.
            Surface {
                id: field
                anchors.horizontalCenter: parent.horizontalCenter
                width: 320
                height: 48
                level: 3
                translucent: true
                radius: Tokens.radius.pill(height)
                border.color: view.auth.state === "wrong" || view.auth.state === "error" || view.auth.lockedOut ? Colors.danger : Colors.divider
                transform: Translate { id: shake; x: 0 }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.space.lg
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.space.sm
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: view.auth.busy ? "progress_activity" : "lock"
                        filled: true
                        color: Colors.textMuted
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: view.auth.buffer.length === 0
                        text: view.auth.busy ? "Verificando…" : view.auth.lockedOut ? "Bloqueado temporalmente" : "Contraseña"
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: view.auth.buffer.length > 0
                        text: "•".repeat(Math.min(view.auth.buffer.length, 24))
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.headline
                        font.letterSpacing: 2
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                height: Tokens.type.body * 1.5
                text: view.auth.message
                color: Colors.danger
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
                font.weight: Tokens.weight.medium
            }
        }
    }

    // Sacudida corta al fallar (sin movimiento con "reducir movimiento").
    SequentialAnimation {
        id: shakeAnim
        loops: 1
        NumberAnimation { target: shake; property: "x"; to: -10; duration: Tokens.motion.fast / 2 }
        NumberAnimation { target: shake; property: "x"; to: 10; duration: Tokens.motion.fast / 2 }
        NumberAnimation { target: shake; property: "x"; to: -6; duration: Tokens.motion.fast / 2 }
        NumberAnimation { target: shake; property: "x"; to: 0; duration: Tokens.motion.fast / 2 }
    }
    Connections {
        target: view.auth
        function onFailed() { if (Tokens.motion.scale > 0) shakeAnim.restart(); }
    }

    // ---- Cursor ----------------------------------------------------------------------------
    // Oculto sobre el bloqueo (como hide_cursor de hyprlock, D11): no hay nada
    // que tocar con el raton. No acepta clics ni cambia el foco del teclado.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.BlankCursor
    }

    // ---- Teclado ---------------------------------------------------------------------------
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) view.auth.submit();
            else if (event.key === Qt.Key_Backspace) {
                if (event.modifiers & Qt.ControlModifier) view.auth.clear();
                else view.auth.erase();
            } else if (event.key === Qt.Key_Escape) view.auth.clear();
            else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) view.auth.type(event.text);
            event.accepted = true;
        }
    }
    function focusField(): void {
        keys.forceActiveFocus();
    }
    Component.onCompleted: keys.forceActiveFocus()
}
