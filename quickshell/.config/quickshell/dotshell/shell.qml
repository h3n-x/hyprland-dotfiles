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

    // Reducir movimiento (D9, M4): la opcion accessibility.reduceMotion
    // (settings store, Fase 8 B1: sobrevive a reinicios) pone
    // Tokens.motion.scale en 0 (todas las duraciones en 0 y los springs
    // desactivados). `qs -c dotshell ipc call motion reduce|restore` la cambia
    // por el motor, como cualquier otro escritor.
    Binding {
        target: Tokens.motion
        property: "scale"
        value: SettingsState.value("accessibility.reduceMotion") ? 0 : 1
    }
    IpcHandler {
        target: "motion"
        function reduce(): void {
            SettingsState.set("accessibility.reduceMotion", true);
        }
        function restore(): void {
            SettingsState.set("accessibility.reduceMotion", false);
        }
        function status(): string {
            return SettingsState.value("accessibility.reduceMotion") ? "reduced" : "normal";
        }
    }

    // Servicios bajo demanda (Fase 8 B3): quien esta pidiendo que. Solo lee
    // contadores; lo usan las sondas y el diagnostico del centro de
    // configuracion (P10).
    IpcHandler {
        target: "services"
        function status(): string {
            return JSON.stringify(Services.status());
        }
    }

    // Popups anclados (Fase 8 B5): cual esta abierto y donde; cerrarlos.
    // P8.6 (pantalla completa) usa PopupState.closeAll(pantalla).
    IpcHandler {
        target: "popups"
        function status(): string {
            return JSON.stringify({ id: PopupState.openId, screen: PopupState.openScreen });
        }
        function close(): void {
            PopupState.closeAll("");
        }
    }

    // Pantalla completa y captura (Fase 8 B6): estado por pantalla y avisos
    // retenidos.
    IpcHandler {
        target: "fullscreen"
        function status(): string {
            return JSON.stringify({
                screens: Quickshell.screens.map(s => ({ name: s.name, fullscreen: FullscreenState.isFullscreen(s.name),
                    kind: FullscreenState.kind(s.name), capture: FullscreenState.isCapturing(s.name) })),
                held: FullscreenState.held
            });
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

    // Reproductor (Fase 4 B5): las teclas multimedia (binds.lua) actuan sobre
    // el mismo reproductor que la pill y el dashboard (MediaState.active).
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
    }

    // Dashboard (Fase 4 B7): unica entrada, SUPER+A (binds.lua) -> toggle, en
    // el monitor enfocado y con el foco en el reproductor si algo esta sonando.
    IpcHandler {
        target: "dashboard"
        function open(): void {
            DashboardState.open();
        }
        function close(): void {
            DashboardState.close();
        }
        function toggle(): void {
            DashboardState.toggle();
        }
    }

    // Capturas y grabacion (Fase 4 B8): avisos de los scripts screenshot y
    // record. preview <ruta> <region|window|full|recording> <"x,y wxh">
    // <bytes> <extra: monitor, clase o duracion en ms>; recorded ok|error <ms>
    // al terminar una grabacion; refresh relee su estado. "preview" y no
    // "show": "qs ipc call capture show" choca con el subcomando "qs ipc show".
    IpcHandler {
        target: "capture"
        function preview(path: string, kind: string, region: string, bytes: string, extra: string): void {
            CaptureState.show(path, kind, region, bytes, extra);
        }
        function dismiss(): void {
            CaptureState.dismiss();
        }
        function recorded(result: string, ms: string): void {
            CaptureState.recorded(result, ms);
        }
        function refresh(): void {
            CaptureState.refresh();
        }
    }

    // Guia de atajos (Fase 4 B10): SUPER+/ (binds.lua) -> toggle, en el
    // monitor enfocado.
    IpcHandler {
        target: "keybinds"
        function open(): void {
            KeybindState.open();
        }
        function close(): void {
            KeybindState.close();
        }
        function toggle(): void {
            KeybindState.toggle();
        }
    }

    IpcHandler {
        target: "gallery"
        function toggle(): void {
            GalleryState.toggle();
        }
        // El centro de configuracion (Inicio, "Cambiar fondo"): abre sin cerrar.
        function open(): void {
            GalleryState.open();
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

    Variants {
        model: Quickshell.screens

        Keybinds {
            required property var modelData
            screen: modelData
        }
    }

    // Vista previa de capturas y marcas de grabacion (Fase 4 B8).
    Variants {
        model: Quickshell.screens

        CapturePreview {
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
