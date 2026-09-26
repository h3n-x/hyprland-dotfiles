// Entry point de la barra. Quickshell.screens es reactivo (Variants la crea
// o destruye sola si conectas/desconectas un monitor, ver doc "Reusable
// components"). Gestionado con GNU Stow desde
// /home/h3n/Dotfiles/quickshell -> ~/.config/quickshell. Se lanza con
// `qs -c dotshell` (ver hypr/.config/hypr/modules/autostart.lua).
import QtQuick
import Quickshell
import Quickshell.Io
import "modules"

ShellRoot {
    // Relee la paleta (~/.cache/matugen/quickshell-colors.json) sin recargar
    // la shell. Colors.qml ya la relee sola al cambiar; esto queda para
    // forzarlo a mano o para llamadas viejas (Fase 3 B1, KI-L8).
    IpcHandler {
        target: "colors"
        function reload(): void {
            Colors.reload();
        }
    }

    // SUPER+SHIFT+B (ver binds.lua) -- reemplaza a "killall -SIGUSR1 waybar".
    IpcHandler {
        target: "bar"
        function toggle(): void {
            BarVisibility.hidden = !BarVisibility.hidden;
        }
    }

    // SUPER+SHIFT+CTRL+B -- reemplaza a "killall -SIGUSR2 waybar". Reload
    // "duro" (recrea ventanas, a diferencia del soft reload de "colors").
    IpcHandler {
        target: "shell"
        function reload(): void {
            Quickshell.reload(true);
        }
    }

    // SUPER+N / SUPER+SHIFT+N (ver binds.lua) -- reemplazan a
    // "swaync-client -t -sw" / "-C".
    IpcHandler {
        target: "controlcenter"
        function toggle(): void {
            ControlCenterState.visible = !ControlCenterState.visible;
        }
        function clearAll(): void {
            NotificationState.clearAll();
        }
    }

    // Reducir movimiento (D9, M4): `qs -c dotshell ipc call motion reduce`
    // pone Tokens.motion.scale en 0 (todas las duraciones en 0 y los springs
    // desactivados); `restore` lo vuelve a 1. PersistentProperties sobrevive
    // a los reloads (el de "colors" corre en cada cambio de wallpaper), no a
    // reiniciar el proceso.
    PersistentProperties {
        id: motionPrefs
        reloadableId: "motionPrefs"
        property bool reduced: false
    }
    Binding {
        target: Tokens.motion
        property: "scale"
        value: motionPrefs.reduced ? 0 : 1
    }
    IpcHandler {
        target: "motion"
        function reduce(): void {
            motionPrefs.reduced = true;
        }
        function restore(): void {
            motionPrefs.reduced = false;
        }
        function status(): string {
            return motionPrefs.reduced ? "reduced" : "normal";
        }
    }

    // SUPER+D (ver binds.lua) -- lanzador de aplicaciones.
    IpcHandler {
        target: "launcher"
        // Se abre en el monitor enfocado (Fase 4 B0); open/close para los
        // paneles nuevos, toggle para el bind de siempre.
        function toggle(): void {
            LauncherState.toggle();
        }
        function open(): void {
            LauncherState.open();
        }
        function close(): void {
            LauncherState.close();
        }
    }

    // SUPER+SHIFT+W (ver binds.lua) -- galeria de wallpapers (Fase 3 B3).
    // Menu de energia y sesion (Fase 4 B1): SUPER+M abre, SUPER+SHIFT+M va
    // directo a la confirmacion de cerrar sesion.
    IpcHandler {
        target: "power"
        function open(): void {
            PowerState.open();
        }
        function close(): void {
            PowerState.close();
        }
        function toggle(): void {
            PowerState.toggle();
        }
        function confirm(action: string): void {
            if (["logout", "reboot", "poweroff"].indexOf(action) >= 0)
                PowerState.openConfirm(action);
        }
    }

    // Historial del portapapeles (Fase 4 B2): SUPER+SHIFT+V abre. pause /
    // resume / status: la pausa del historial (tambien Ctrl+P en el panel).
    IpcHandler {
        target: "clipboard"
        function open(): void {
            ClipboardState.open();
        }
        function close(): void {
            ClipboardState.close();
        }
        function toggle(): void {
            ClipboardState.toggle();
        }
        function pause(): void {
            ClipboardState.setPaused(true);
        }
        function resume(): void {
            ClipboardState.setPaused(false);
        }
        function status(): string {
            return ClipboardState.paused ? "paused" : "active";
        }
    }

    // Selector de emoji (Fase 4 B3): SUPER+. abre. clearRecent borra los
    // recientes.
    IpcHandler {
        target: "emoji"
        function open(): void {
            EmojiState.open();
        }
        function close(): void {
            EmojiState.close();
        }
        function toggle(): void {
            EmojiState.toggle();
        }
        function clearRecent(): void {
            EmojiState.clearRecent();
        }
    }

    // Selector de ventanas (Fase 4 B4): SUPER+TAB -> next, SUPER+SHIFT+TAB ->
    // prev (abren con la ventana anterior elegida o mueven la seleccion).
    IpcHandler {
        target: "switcher"
        function next(): void {
            SwitcherState.next();
        }
        function prev(): void {
            SwitcherState.prev();
        }
        function open(): void {
            SwitcherState.open();
        }
        function close(): void {
            SwitcherState.close();
        }
        function toggle(): void {
            SwitcherState.toggle();
        }
    }

    // Media hub (Fase 4 B5): las teclas multimedia (binds.lua) actuan sobre el
    // mismo reproductor que la pill y el hub (MediaState.active).
    IpcHandler {
        target: "media"
        function playPause(): void {
            MediaState.togglePlaying();
        }
        function next(): void {
            MediaState.next();
        }
        function previous(): void {
            MediaState.previous();
        }
        function open(): void {
            MediaState.openHub("");
        }
        function close(): void {
            MediaState.closeHub();
        }
        function toggle(): void {
            MediaState.toggleHub("");
        }
    }

    // Panel del reloj (Fase 4 B6: calendario + clima; dashboard en B7). Sin
    // atajo propio por ahora (B6-i); el clic en el reloj lo abre.
    IpcHandler {
        target: "dashboard"
        function open(): void {
            DashboardState.open("");
        }
        function close(): void {
            DashboardState.close();
        }
        function toggle(): void {
            DashboardState.toggle("");
        }
    }

    IpcHandler {
        target: "gallery"
        function toggle(): void {
            GalleryState.toggle();
        }
    }

    // Tema (Fase 3 B5): volver al tema anterior del historial. Tambien en
    // SUPER+SHIFT+Z (binds.lua, llama al script directo).
    IpcHandler {
        target: "theme"
        function undo(): void {
            Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/theme-apply.sh", "--undo"]);
        }
    }

    // Wallpaper (Fase 3 B6): capa de fondo con fundido; se oculta si el
    // backend elegido es hyprpaper (theme-apply.sh --backend).
    Variants {
        model: Quickshell.screens

        Wallpaper {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Osd {
            required property var modelData
            screen: modelData
        }
    }

    // Sin icono propio en la barra (a pedido del usuario, ya esta el OSD)
    // pero tienen que seguir instanciados en algun lado para que su logica
    // (Pipewire/FileView + OsdState.show()) siga corriendo. Al no ser
    // PanelWindow (son Item comunes) no necesitan pantalla ni se dibujan
    // en ningun lado por si solos.
    Volume {}
    Backlight {}

    Variants {
        model: Quickshell.screens

        ControlCenter {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        NotificationToast {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Launcher {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        PowerMenu {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Clipboard {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Emoji {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Switcher {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        WallpaperGallery {
            required property var modelData
            screen: modelData
        }
    }

    // Barra de la vista previa del tema (Fase 3 B7).
    Variants {
        model: Quickshell.screens

        PreviewBar {
            required property var modelData
            screen: modelData
        }
    }
}
