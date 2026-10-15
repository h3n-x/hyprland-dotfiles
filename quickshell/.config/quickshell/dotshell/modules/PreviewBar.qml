// Barra de la vista previa del tema (Fase 3 B7): abajo al centro mientras
// ThemePreview.active. Dice que se esta viendo y da los controles:
// <- / -> recorren la lista de la galeria (decision B7d), Enter aplica,
// Esc cancela y vuelve a la galeria (B7b). Un clic afuera o perder el foco
// cancela y cierra (B7e): nunca queda una vista previa olvidada.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".." // Colors.qml, Tokens.qml, ThemePreview.qml, GalleryState.qml

PanelWindow {
    id: win

    anchors {
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.namespace: "quickshell-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitHeight: box.implicitHeight + box.shadowMargin * 2
    margins {
        bottom: Tokens.space.xl - box.shadowMargin
    }
    // Solo la tarjeta recibe clics; el resto de la franja cuenta como "afuera".
    mask: Region { item: box }

    // En el mismo monitor que la galeria desde la que se abrio (Fase 4 B0).
    readonly property bool onThisScreen: GalleryState.screen === "" || (!!win.screen && win.screen.name === GalleryState.screen)
    Presence { id: presence; open: ThemePreview.active && win.onThisScreen; enterDuration: Tokens.motion.medium }
    visible: presence.shown

    // Teclado recien cuando la galeria termino de irse (ver GalleryState) y
    // 100 ms despues: si se toma en el mismo momento en que la galeria suelta
    // el suyo, Hyprland le devuelve el teclado a la ventana anterior.
    readonly property bool wantGrab: ThemePreview.active && win.visible && !GalleryState.windowShown
    property bool grabReady: false
    onWantGrabChanged: {
        grabDelay.stop();
        win.grabReady = false;
        if (win.wantGrab)
            grabDelay.restart();
    }
    Timer {
        id: grabDelay
        interval: 100
        onTriggered: win.grabReady = true
    }
    HyprlandFocusGrab {
        windows: [win]
        active: win.grabReady
        onActiveChanged: if (active) box.forceActiveFocus()
        onCleared: ThemePreview.cancel(false)
    }

    readonly property bool canPrev: ThemePreview.index > 0
    readonly property bool canNext: ThemePreview.index < ThemePreview.names.length - 1

    component IconButton: Rectangle {
        id: btn
        property string icon
        signal clicked()
        implicitWidth: Tokens.row.height
        implicitHeight: Tokens.row.height
        radius: Tokens.radius.pill(height)
        color: "transparent"
        border.color: Colors.divider
        opacity: btn.enabled ? 1 : Tokens.opacity.disabled
        StateLayer { visible: btn.enabled; hovered: btnMouse.containsMouse; pressed: btnMouse.pressed }
        Icon { anchors.centerIn: parent; name: btn.icon; color: Colors.textMuted }
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
    // Tecla del atajo dentro de un boton.
    component KeyHint: Rectangle {
        id: hint
        property string text
        property color fg
        implicitWidth: hintText.implicitWidth + Tokens.space.sm * 2
        implicitHeight: hintText.implicitHeight + Tokens.space.hair * 2
        radius: Tokens.radius.sm
        color: "transparent"
        border.color: Colors.tint(hint.fg, Tokens.tint.hairline)
        Text {
            id: hintText
            anchors.centerIn: parent
            text: hint.text
            color: hint.fg
            font.family: Tokens.font.ui
            font.pixelSize: Tokens.type.caption
        }
    }

    Surface {
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        y: box.shadowMargin
        level: 3
        translucent: true
        radius: Tokens.radius.pill(height)
        implicitWidth: row.implicitWidth + Tokens.space.lg * 2
        implicitHeight: row.implicitHeight + Tokens.space.sm * 2
        opacity: presence.progress
        scale: presence.contentScale
        transformOrigin: Item.Bottom
        transform: Translate { y: presence.offsetY }

        focus: true
        Keys.onLeftPressed: ThemePreview.step(-1)
        Keys.onRightPressed: ThemePreview.step(1)
        Keys.onReturnPressed: ThemePreview.apply()
        Keys.onEnterPressed: ThemePreview.apply()
        Keys.onEscapePressed: ThemePreview.cancel(true)

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Tokens.space.md

            Rectangle {
                implicitWidth: Tokens.row.height
                implicitHeight: Tokens.row.height
                radius: width / 2
                color: Colors.accentContainer
                Icon { anchors.centerIn: parent; name: "visibility"; filled: true; color: Colors.textOnAccentContainer }
            }
            Column {
                Layout.preferredWidth: Math.max(implicitWidth, Tokens.panel.widthSm * 0.5)
                Text {
                    text: I18n.tr("Preview · %1 of %2", ThemePreview.index + 1, ThemePreview.names.length)
                    color: Colors.textMuted
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.caption
                }
                Text {
                    text: ThemePreview.name.replace(/\.[^.]+$/, "")
                    color: Colors.text
                    font.family: Tokens.font.ui
                    font.pixelSize: Tokens.type.body
                    font.weight: Tokens.weight.semibold
                }
            }
            IconButton {
                Layout.leftMargin: Tokens.space.sm
                icon: "chevron_left"
                enabled: win.canPrev
                onClicked: ThemePreview.step(-1)
            }
            IconButton {
                icon: "chevron_right"
                enabled: win.canNext
                onClicked: ThemePreview.step(1)
            }
            // Cancelar: vuelve a la galeria.
            Rectangle {
                Layout.leftMargin: Tokens.space.xs
                implicitWidth: cancelRow.implicitWidth + Tokens.space.lg * 2
                implicitHeight: Tokens.row.height
                radius: Tokens.radius.pill(height)
                color: "transparent"
                border.color: Colors.divider
                StateLayer { hovered: cancelMouse.containsMouse; pressed: cancelMouse.pressed }
                Row {
                    id: cancelRow
                    anchors.centerIn: parent
                    spacing: Tokens.space.sm
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr("Cancel")
                        color: Colors.text
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                    }
                    KeyHint { anchors.verticalCenter: parent.verticalCenter; text: "Esc"; fg: Colors.textMuted }
                }
                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ThemePreview.cancel(true)
                }
            }
            // Aplicar (boton lleno primary, como en la galeria).
            Rectangle {
                implicitWidth: applyRow.implicitWidth + Tokens.space.lg * 2
                implicitHeight: Tokens.row.height
                radius: Tokens.radius.pill(height)
                color: Colors.accent
                StateLayer { hovered: applyMouse.containsMouse; pressed: applyMouse.pressed; contentColor: Colors.textOnAccent }
                Row {
                    id: applyRow
                    anchors.centerIn: parent
                    spacing: Tokens.space.sm
                    Icon { name: "wallpaper"; filled: true; color: Colors.textOnAccent }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr("Apply")
                        color: Colors.textOnAccent
                        font.family: Tokens.font.ui
                        font.pixelSize: Tokens.type.body
                        font.weight: Tokens.weight.semibold
                    }
                    KeyHint { anchors.verticalCenter: parent.verticalCenter; text: "Enter"; fg: Colors.textOnAccent }
                }
                MouseArea {
                    id: applyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ThemePreview.apply()
                }
            }
        }
    }

    onVisibleChanged: if (visible) box.forceActiveFocus()
}
