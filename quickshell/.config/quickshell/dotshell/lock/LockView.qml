// Lo que se ve en cada pantalla bloqueada (Fase 9; composicion "Material You",
// B2): a la izquierda la hora apilada (horas en el acento, minutos en el texto)
// y el chip de la fecha; a la derecha las tarjetas "de un vistazo" (clima,
// musica, bateria, avisos: solo las que tienen algo que decir, ninguna hace
// nada) y la tarjeta de la contrasena. Fondo: el wallpaper difuminado (nunca
// una copia del escritorio).
//
// La tarjeta de la contrasena tiene un lugar fijo: las tarjetas de estado
// crecen hacia arriba, asi que el campo no se mueve si llega un aviso o se
// desenchufa el cargador. El campo esta en TODAS las pantallas y todas
// muestran el mismo buffer (D8): Hyprland puede darle el teclado a cualquier
// superficie. Bloq Mayus y los errores usan la linea bajo el campo (el error
// tiene prioridad).
//
// Sin imports de Quickshell.Wayland: la misma vista se prueba en una ventana
// comun fuera de pantalla (sondas).
import QtQuick
import QtQuick.Effects
import Quickshell
import ".." // Colors.qml, Tokens.qml
import "../modules" // Icon

Item {
    id: view

    required property var auth
    // LockGlance (una por bloqueo). null = sin tarjetas ni aviso de Bloq Mayus.
    property var glance: null
    // false = salida en curso (animacion de desbloqueo).
    property bool shown: true
    signal leaveFinished()

    readonly property var tiles: view.glance ? view.glance.tiles : []
    readonly property bool capsLock: view.glance ? view.glance.capsLock : false
    readonly property var es: Qt.locale("es_ES")

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
        // Sincronica: el primer cuadro del bloqueo ya trae el fondo (V0-7c).
        asynchronous: false
        // El mismo tamano en todas las pantallas: una sola decodificacion compartida.
        sourceSize.width: 1920
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        blurEnabled: true
        blur: 0.45
        blurMax: 64
        brightness: -0.08
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

        readonly property int gap: 120
        readonly property int cardWidth: 530
        readonly property int clockWidth: clockColumn.implicitWidth
        readonly property real left0: Math.round((width - clockWidth - gap - cardWidth) / 2)

        // ---- Izquierda: hora apilada y fecha ---------------------------------------------
        Column {
            id: clockColumn
            x: content.left0
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.space.xl
            Column {
                spacing: -Math.round(Tokens.type.lockClock * 0.21)
                // Va directo sobre el wallpaper: una sombra suave lo mantiene
                // legible con fondos claros (sin ella, 2.98:1 medido).
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Colors.shadow
                    shadowOpacity: Tokens.shadow.lg.opacity
                    shadowBlur: 1.0
                    blurMax: Tokens.shadow.lg.blur
                }
                Text {
                    text: Qt.formatTime(clock.date, "HH")
                    color: Colors.accent
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.lockClock
                    font.weight: Tokens.weight.semibold
                    font.letterSpacing: -6
                    font.features: Tokens.tabularNumbers
                }
                Text {
                    text: Qt.formatTime(clock.date, "mm")
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.lockClock
                    font.weight: Tokens.weight.semibold
                    font.letterSpacing: -6
                    font.features: Tokens.tabularNumbers
                }
            }
            Rectangle {
                width: dateText.implicitWidth + 2 * Tokens.space.xl
                height: 52
                radius: Tokens.radius.pill(height)
                color: Colors.accentContainer
                Text {
                    id: dateText
                    anchors.centerIn: parent
                    text: {
                        const d = view.es.standaloneDayName(clock.date.getDay(), Locale.LongFormat);
                        return d.charAt(0).toUpperCase() + d.slice(1) + ", " + clock.date.getDate() + " de "
                            + view.es.standaloneMonthName(clock.date.getMonth(), Locale.LongFormat);
                    }
                    color: Colors.textOnAccentContainer
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.title
                    font.weight: Tokens.weight.semibold
                }
            }
        }

        // ---- Derecha: tarjetas de estado (crecen hacia arriba) -----------------------------
        Column {
            id: tilesColumn
            x: content.left0 + content.clockWidth + content.gap
            anchors.bottom: card.top
            anchors.bottomMargin: Tokens.space.lg
            spacing: Tokens.space.lg
            visible: view.tiles.length > 0

            Text {
                text: "DE UN VISTAZO"
                // Texto principal, no el atenuado: es chico y va sobre el wallpaper.
                color: Colors.text
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Colors.shadow
                    shadowOpacity: Tokens.shadow.lg.opacity
                    shadowBlur: 1.0
                    blurMax: Tokens.shadow.md.blur
                }
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.label
                font.weight: Tokens.weight.semibold
                font.letterSpacing: 2
                leftPadding: Tokens.space.sm
            }
            Grid {
                columns: 2
                spacing: Tokens.space.md
                Repeater {
                    model: view.tiles
                    Rectangle {
                        required property var modelData
                        readonly property color tone: modelData.tone === "danger" ? Colors.dangerContainer
                            : modelData.tone === "warning" ? Colors.warningContainer : Colors.accentContainer
                        readonly property color onTone: modelData.tone === "danger" ? Colors.textOnDangerContainer
                            : modelData.tone === "warning" ? Colors.textOnWarningContainer : Colors.textOnAccentContainer
                        width: Math.round((content.cardWidth - Tokens.space.md) / 2)
                        height: 96
                        radius: Tokens.radius.pill(height)
                        color: Colors.tint(Colors.surfaceHigh, Tokens.opacity.surface)
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Tokens.space.lg
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Tokens.space.md
                            Rectangle {
                                width: 60; height: 60; radius: 30
                                anchors.verticalCenter: parent.verticalCenter
                                color: parent.parent.tone
                                Icon {
                                    anchors.centerIn: parent
                                    name: modelData.icon
                                    size: 26
                                    filled: true
                                    color: parent.parent.parent.onTone
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    text: modelData.title
                                    color: Colors.text
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.headline
                                    font.weight: Tokens.weight.semibold
                                    font.features: Tokens.tabularNumbers
                                }
                                Text {
                                    text: modelData.sub
                                    width: 150
                                    elide: Text.ElideRight
                                    color: Colors.textMuted
                                    font.family: Tokens.font.ui
                                    font.pixelSize: Tokens.type.label
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- Derecha: tarjeta de la contrasena (lugar fijo) -------------------------------
        Rectangle {
            id: card
            x: content.left0 + content.clockWidth + content.gap
            y: Math.round(content.height / 2) + Tokens.space.sm
            width: content.cardWidth
            height: cardColumn.implicitHeight + 2 * Tokens.space.xxl
            radius: Tokens.radius.xl
            color: Colors.tint(Colors.surface, Tokens.opacity.surface)

            Column {
                id: cardColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.space.xxl
                spacing: Tokens.space.lg

                // Avatar (~/.face, lo escribe theme-apply.sh), usuario y estado.
                Row {
                    spacing: Tokens.space.md
                    Item {
                        width: 34
                        height: 34
                        Image {
                            id: face
                            anchors.fill: parent
                            source: "file://" + Quickshell.env("HOME") + "/.face"
                            sourceSize.width: 68
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
                            size: 34
                            color: Colors.textMuted
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Quickshell.env("USER")
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.title
                        font.weight: Tokens.weight.semibold
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "·  sesión bloqueada"
                        color: Colors.textMuted
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                    }
                }

                // Campo de contrasena: puntos, sin texto real.
                Rectangle {
                    id: field
                    width: parent.width
                    height: 64
                    radius: Tokens.radius.pill(height)
                    color: Colors.surfaceHighest
                    border.width: 2
                    border.color: view.auth.state === "wrong" || view.auth.state === "error" || view.auth.lockedOut ? Colors.danger : Colors.accent
                    transform: Translate { id: shake; x: 0 }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.space.xl
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Tokens.space.md
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
                            font.pixelSize: Tokens.type.title
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: view.auth.buffer.length > 0
                            text: "•".repeat(Math.min(view.auth.buffer.length, 24))
                            color: Colors.text
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.headline
                            font.letterSpacing: 3
                        }
                    }
                }

                // Mensaje (error > Bloq Mayus) y la indicacion de Enter.
                Item {
                    width: parent.width
                    height: 48
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.space.sm
                        anchors.right: enterHint.left
                        anchors.rightMargin: Tokens.space.md
                        anchors.verticalCenter: parent.verticalCenter
                        text: view.auth.message || (view.capsLock ? "Bloq Mayús activado" : "")
                        color: view.auth.message ? Colors.danger : Colors.warning
                        elide: Text.ElideRight
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.weight: Tokens.weight.medium
                    }
                    Rectangle {
                        id: enterHint
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: enterText.implicitWidth + 2 * Tokens.space.xl
                        height: 48
                        radius: Tokens.radius.pill(height)
                        color: Colors.accent
                        Text {
                            id: enterText
                            anchors.centerIn: parent
                            text: "Enter  ↵"
                            color: Colors.textOnAccent
                            font.family: Tokens.font.ui
                            font.pixelSize: Tokens.type.body
                            font.weight: Tokens.weight.semibold
                        }
                    }
                }
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
    // Oculto sobre el bloqueo (D11): no hay nada que tocar con el raton. No
    // acepta clics ni cambia el foco del teclado; "Enter ↵" es solo una indicacion.
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
            if (view.glance) view.glance.noteKey(event);
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
