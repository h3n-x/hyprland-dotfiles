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

    // SUPER+D (ver binds.lua) -- reemplaza a "rofi -show drun".
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            LauncherState.visible = !LauncherState.visible;
        }
    }

    // SUPER+SHIFT+W (ver binds.lua) -- galeria de wallpapers (Fase 3 B3);
    // el selector de rofi queda en SUPER+ALT+W mientras la galeria madura.
    IpcHandler {
        target: "gallery"
        function toggle(): void {
            GalleryState.visible = !GalleryState.visible;
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

        WallpaperGallery {
            required property var modelData
            screen: modelData
        }
    }
}
