// Ajustes rapidos (Fase 11 B6, P11.7): el unico dueno de cada accion rapida.
// Un modelo por ajuste: nombre, icono, estado, si esta
// disponible en este equipo y toggle(). Los usan el centro de control
// (controlCenter.tiles), los interruptores de arriba de los desplegables de
// Wi-Fi y Bluetooth y los modulos de la barra (mantener despierto,
// microfono): nadie escribe la accion de nuevo.
//
// Costo: todo llega por eventos (Networking, Bluetooth, PipeWire, el
// almacen, KeyboardState). Lo que hay que preguntar al sistema (modo juego,
// si existen hyprpicker y powerprofilesctl) se pregunta al abrir el centro
// de control (refresh), nunca con un temporizador.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts"
    // Que existe (se pregunta una vez, al primer refresh).
    property bool hasPicker: false
    property bool hasProfiles: true
    property bool checked: false
    property Process probe: Process {
        command: ["sh", "-c", "command -v hyprpicker >/dev/null && echo picker; command -v powerprofilesctl >/dev/null && echo profiles"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hasPicker = this.text.indexOf("picker") >= 0;
                root.hasProfiles = this.text.indexOf("profiles") >= 0;
                root.checked = true;
            }
        }
    }
    // Al abrir el centro de control.
    function refresh(): void {
        if (!root.checked && !root.probe.running) root.probe.running = true;
        if (!gameProbe.running) gameProbe.running = true;
        PowerProfileState.refresh();
    }
    function run(cmd: var): void {
        Quickshell.execDetached(cmd);
    }
    // Lo que abre algo en pantalla cierra antes el centro de control.
    function closeAnd(cmd: var): void {
        ControlCenterState.visible = false;
        Quickshell.execDetached(cmd);
    }
    function get(id: string): var {
        return root.tiles[id] || null;
    }

    // ---- Modo juego (game-mode.sh status: 0 = activo) ------------------------------
    property bool gameModeActive: false
    property Process gameProbe: Process {
        command: [root.scripts + "/game-mode.sh", "status"]
        onExited: (code) => root.gameModeActive = (code === 0)
    }
    property Timer gameRecheck: Timer {
        interval: 350
        onTriggered: gameProbe.running = true
    }

    // ---- Microfono -------------------------------------------------------------------
    property PwObjectTracker micTracker: PwObjectTracker { objects: [Pipewire.defaultAudioSource] }
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool micMuted: !!(root.source && root.source.audio && root.source.audio.muted)
    function toggleMic(): void {
        if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted;
    }

    // ---- Wi-Fi y Bluetooth (tambien los desplegables de la barra) ---------------------
    function toggleWifi(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothOn: !!(root.adapter && root.adapter.enabled)
    function toggleBluetooth(): void {
        if (root.adapter) root.adapter.enabled = !root.adapter.enabled;
    }

    // ---- Los ajustes (id -> modelo) ------------------------------------------------------
    // active: encendido; status: la linea del tamano ancho; available: si en
    // este equipo se puede (si no, no se muestra ni se ofrece en "Agregar").
    readonly property var tiles: ({
        wifi: root.wifi, bluetooth: root.bluetooth, nightLight: root.nightLight, gameMode: root.gameMode, lock: root.lock,
        profile: root.profile, dnd: root.dnd, idle: root.idle, mic: root.mic, capture: root.capture, record: root.record,
        keyboard: root.keyboard, picker: root.picker, settings: root.settings
    })
    property QtObject wifi: QtObject {
        readonly property bool available: true
        readonly property bool active: Networking.wifiEnabled
        readonly property string icon: Networking.wifiEnabled ? "wifi" : "wifi_off"
        readonly property string status: !Networking.wifiEnabled ? "Apagado" : NetworkState.connected ? NetworkState.label : "Sin conexión"
        function toggle(): void { root.toggleWifi(); }
    }
    property QtObject bluetooth: QtObject {
        readonly property bool available: !!root.adapter
        readonly property bool active: root.bluetoothOn
        readonly property string icon: root.bluetoothOn ? "bluetooth" : "bluetooth_disabled"
        readonly property var connected: root.adapter ? root.adapter.devices.values.filter(d => d.connected) : []
        readonly property string status: !root.bluetoothOn ? "Apagado" : connected.length ? connected.map(d => d.name).join(", ") : "Sin dispositivos"
        function toggle(): void { root.toggleBluetooth(); }
    }
    property QtObject nightLight: QtObject {
        readonly property bool available: true
        readonly property bool active: SettingsState.value("display.nightLight.enabled") === true
        readonly property string icon: "nightlight"
        readonly property string status: active ? "Encendida" : "Apagada"
        function toggle(): void { SettingsState.set("display.nightLight.enabled", !active); }
    }
    property QtObject gameMode: QtObject {
        readonly property bool available: true
        readonly property bool active: root.gameModeActive
        readonly property string icon: "sports_esports"
        readonly property string status: active ? "Activo" : "Apagado"
        function toggle(): void {
            root.run([root.scripts + "/game-mode.sh", "toggle"]);
            root.gameRecheck.restart();
        }
    }
    property QtObject lock: QtObject {
        readonly property bool available: true
        readonly property bool active: false
        readonly property string icon: "lock"
        readonly property string status: "Bloquear la pantalla"
        function toggle(): void { root.closeAnd([root.scripts + "/lock", "--user"]); }
    }
    property QtObject profile: QtObject {
        readonly property bool available: root.hasProfiles
        // Fuera de "equilibrado" se marca como encendido (un perfil elegido a proposito).
        readonly property bool active: PowerProfileState.current !== "balanced"
        readonly property string icon: PowerProfileState.info.icon
        readonly property string status: PowerProfileState.info.label
        function toggle(): void { PowerProfileState.cycle(); }
    }
    property QtObject dnd: QtObject {
        readonly property bool available: true
        readonly property bool active: NotificationState.doNotDisturb
        readonly property string icon: active ? "do_not_disturb_on" : "do_not_disturb_off"
        readonly property string status: active ? "Encendido" : "Apagado"
        function toggle(): void { NotificationState.doNotDisturb = !NotificationState.doNotDisturb; }
    }
    property QtObject idle: QtObject {
        readonly property bool available: true
        readonly property bool active: IdleState.active
        readonly property string icon: active ? "visibility" : "visibility_off"
        readonly property string status: active ? "La pantalla no se apaga" : "Apagado"
        function toggle(): void { IdleState.toggle(); }
    }
    property QtObject mic: QtObject {
        readonly property bool available: !!root.source
        readonly property bool active: !!root.source && !root.micMuted
        readonly property string icon: root.micMuted ? "mic_off" : "mic"
        readonly property string status: root.micMuted ? "Silenciado" : "Activo"
        function toggle(): void { root.toggleMic(); }
    }
    property QtObject capture: QtObject {
        readonly property bool available: true
        readonly property bool active: false
        readonly property string icon: "screenshot_region"
        readonly property string status: "Una región"
        function toggle(): void { root.closeAnd([root.scripts + "/screenshot", "region"]); }
    }
    property QtObject record: QtObject {
        readonly property bool available: true
        readonly property bool active: CaptureState.isRecording
        readonly property string icon: active ? "stop_circle" : "radio_button_checked"
        readonly property string status: active ? "Grabando · detener" : "Una zona"
        function toggle(): void {
            if (active) CaptureState.stopRecording();
            else root.closeAnd([root.scripts + "/record", "toggle", "region"]);
        }
    }
    property QtObject keyboard: QtObject {
        readonly property bool available: KeyboardState.layouts.length > 1
        readonly property bool active: false
        readonly property string icon: "keyboard"
        readonly property string status: KeyboardState.code
        function toggle(): void { KeyboardState.next(); }
    }
    property QtObject picker: QtObject {
        readonly property bool available: root.hasPicker
        readonly property bool active: false
        readonly property string icon: "colorize"
        readonly property string status: "Copiar un color"
        // El color queda en el portapapeles y se avisa cual (nunca en silencio).
        function toggle(): void {
            root.closeAnd(["sh", "-c", "c=$(hyprpicker -a -n) && [ -n \"$c\" ] && notify-send -a Color \"Color copiado\" \"$c\""]);
        }
    }
    property QtObject settings: QtObject {
        readonly property bool available: true
        readonly property bool active: false
        readonly property string icon: "settings"
        readonly property string status: "Abrir"
        function toggle(): void { root.closeAnd([root.scripts + "/settings-ui"]); }
    }
}
