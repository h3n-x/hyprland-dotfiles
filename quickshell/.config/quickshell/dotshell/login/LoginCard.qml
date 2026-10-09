// La tarjeta de la contrasena (Fase 9 B3): avatar, usuario y estado, el campo
// con un punto por caracter (nunca el texto), la linea de mensaje (error >
// Bloq Mayus) y la indicacion de Enter. `auth` es la interfaz de LockAuth
// (buffer, state, message, busy, lockedOut, failed()); el greeter la cumple
// con SddmAuth. Movimiento (sin nada continuo; instantaneo con "reducir
// movimiento"): M4 borde, M5 cada punto aparece con un pequeno rebote y el
// borrado encoge el ultimo, M6 al entrar el candado se abre en verde, y la
// sacudida al fallar (B1). QtQuick puro.
import QtQuick
import QtQuick.Effects
import ".." // Colors.qml, Tokens.qml
import "../modules" // Icon

Rectangle {
    id: card

    required property var auth
    property url avatar
    property string user: ""
    property string subtitle: ""
    property bool capsLock: false
    // Contrasena aceptada: M6 (el candado se abre), antes de la salida.
    property bool success: false
    property string successText: ""

    height: cardColumn.implicitHeight + 2 * Tokens.space.xxl
    radius: Tokens.radius.xl
    color: Colors.tint(Colors.surface, Tokens.opacity.surface)

    readonly property bool failedState: card.auth.state === "wrong" || card.auth.state === "error" || card.auth.lockedOut
    readonly property int dots: Math.min(card.auth.buffer.length, 24)

    Column {
        id: cardColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.space.xxl
        spacing: Tokens.space.lg

        // ---- Avatar, usuario y estado ---------------------------------------------------------
        Row {
            spacing: Tokens.space.md
            Item {
                width: Tokens.px(34)
                height: Tokens.px(34)
                Image {
                    id: face
                    anchors.fill: parent
                    source: card.avatar
                    sourceSize.width: Tokens.px(68)
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
                    size: Tokens.px(34)
                    color: Colors.textMuted
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: card.user
                color: Colors.text
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.title
                font.weight: Tokens.weight.semibold
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "·  " + card.subtitle
                color: Colors.textMuted
                font.family: Tokens.font.ui
                font.pixelSize: Tokens.type.body
            }
        }

        // ---- Campo ----------------------------------------------------------------------------
        Rectangle {
            id: field
            width: parent.width
            height: Tokens.px(64)
            radius: Tokens.radius.pill(height)
            color: Colors.surfaceHighest
            border.width: 2
            // M4 / M6: acento, peligro al fallar, exito al entrar.
            border.color: card.success ? Colors.success : card.failedState ? Colors.danger : Colors.accent
            Behavior on border.color { ColorAnimation { duration: Tokens.motion.short } }
            transform: Translate { id: shake; x: 0 }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Tokens.space.xl
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.space.md

                // M6: el candado se desvanece y aparece abierto, en verde.
                Item {
                    width: lockIcon.width
                    height: lockIcon.height
                    anchors.verticalCenter: parent.verticalCenter
                    Icon {
                        id: lockIcon
                        anchors.centerIn: parent
                        name: card.auth.busy ? "progress_activity" : "lock"
                        filled: true
                        color: Colors.textMuted
                        opacity: card.success ? 0 : 1
                        scale: card.success ? 0.7 : 1
                        Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }
                        Behavior on scale { NumberAnimation { duration: Tokens.motion.short } }
                    }
                    Icon {
                        anchors.centerIn: parent
                        name: "lock_open"
                        filled: true
                        color: Colors.success
                        opacity: card.success ? 1 : 0
                        scale: card.success ? 1 : 0.7
                        Behavior on opacity { NumberAnimation { duration: Tokens.motion.short } }
                        Behavior on scale { NumberAnimation { duration: Tokens.motion.short; easing.type: Easing.OutBack } }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: card.dots === 0
                    text: card.success ? card.successText
                        : card.auth.busy ? "Verificando…" : card.auth.lockedOut ? "Bloqueado temporalmente" : "Contraseña"
                    color: card.success ? Colors.text : Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.title
                }
                // M5: un punto por caracter; el nuevo aparece con rebote, el borrado se encoge.
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: card.dots > 0 || ghost.running
                    spacing: 6
                    Repeater {
                        model: card.dots
                        Rectangle {
                            width: Tokens.px(10)
                            height: Tokens.px(10)
                            radius: 5
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.text
                            scale: 0.6
                            Component.onCompleted: scale = 1
                            Behavior on scale { NumberAnimation { duration: Tokens.motion.fast; easing.type: Easing.OutBack } }
                        }
                    }
                    Rectangle {
                        id: ghostDot
                        width: Tokens.px(10)
                        height: Tokens.px(10)
                        radius: 5
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.text
                        visible: ghost.running
                        scale: 0
                    }
                }
            }
        }

        // ---- Mensaje y Enter --------------------------------------------------------------------
        Item {
            width: parent.width
            height: Tokens.px(48)
            Text {
                anchors.left: parent.left
                anchors.leftMargin: Tokens.space.sm
                anchors.right: enterHint.left
                anchors.rightMargin: Tokens.space.md
                anchors.verticalCenter: parent.verticalCenter
                text: card.auth.message || (card.capsLock ? "Bloq Mayús activado" : "")
                color: card.auth.message ? Colors.danger : Colors.warning
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
                height: Tokens.px(48)
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

    // M5: al borrar un caracter, un punto fantasma se encoge en el lugar del ultimo.
    property int lastDots: 0
    onDotsChanged: {
        if (card.dots === card.lastDots - 1) ghost.restart();
        card.lastDots = card.dots;
    }
    NumberAnimation {
        id: ghost
        target: ghostDot
        property: "scale"
        from: 1
        to: 0
        duration: Tokens.motion.fast
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.motion.easeExit
    }

    // Sacudida corta al fallar (sin movimiento con "reducir movimiento").
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shake; property: "x"; to: -10; duration: Tokens.motion.fast / 2 }
        NumberAnimation { target: shake; property: "x"; to: 10; duration: Tokens.motion.fast / 2 }
        NumberAnimation { target: shake; property: "x"; to: -6; duration: Tokens.motion.fast / 2 }
        NumberAnimation { target: shake; property: "x"; to: 0; duration: Tokens.motion.fast / 2 }
    }
    Connections {
        target: card.auth
        function onFailed() { if (Tokens.motion.scale > 0) shakeAnim.restart(); }
    }
}
