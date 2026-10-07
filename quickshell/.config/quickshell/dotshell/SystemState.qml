// Estado del equipo (Fase 4 B7): un solo lugar para CPU, memoria,
// temperaturas, almacenamiento, red, graficas, aplicaciones y bateria. Lo
// usan el dashboard (Inicio: estado general; vista Sistema: el detalle) y la
// pill de bateria de la barra (umbrales y avisos).
//
// Todo lo que se lee de /proc y /sys, SOLO mientras alguien lo pide (Demand,
// Fase 8 B3; las vistas se suscriben con Subscription):
//   basic   dashboard visible: CPU, memoria, temperatura (cada 2 s)
//   detail  vista Sistema: ademas red, graficas, tiempo encendido, (al abrirla)
//           almacenamiento y las aplicaciones cada 4 s (D2: a 2 s el orden de
//           la tabla solo cambiaba por ruido y costaba ~6,5 % de un nucleo)
//   Al soltar detail se vacian sus datos (lista de aplicaciones, muestras).
// Cerrado el dashboard no hay temporizador, lecturas ni procesos. La bateria
// esta en BatteryState.qml (UPower, eventos; la comparte el bloqueo). Lo fijo (distro, kernel, modelo de CPU y graficas, rutas de
// sensores) se lee una sola vez, la primera vez que hace falta.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ---- Demanda -----------------------------------------------------------------
    property Demand basic: Demand {
        name: "system.basic"
        onActiveChanged: if (active) root.sample()
    }
    property Demand detail: Demand {
        name: "system.detail"
        onActiveChanged: {
            if (!active) return;
            storageProc.running = true;
            root.dgpuPower = ""; // al entrar se vuelve a preguntar que la usa
            root.appTick = 0;
            root.sample();
        }
        onReleased: {
            root.apps = [];
            root.procPrev = null;
            if (!root.net.active) {
                root.netPrev = null;
                root.rxRate = 0;
                root.txRate = 0;
            }
        }
    }
    // Solo la velocidad de la red (modulo de la barra, Fase 11 B2b): lee
    // /proc/net/dev y nada mas.
    property Demand net: Demand {
        name: "system.net"
        onActiveChanged: if (active) root.sample()
        onReleased: if (!root.detail.active) {
            root.netPrev = null;
            root.rxRate = 0;
            root.txRate = 0;
        }
    }
    readonly property bool sampling: root.basic.active || root.detail.active || root.net.active
    property Timer ticker: Timer {
        // Cada cuanto (system.sampleSeconds, 2-10 s; Fase 11 B2b): el dashboard y la barra.
        interval: Math.max(2, SettingsState.value("system.sampleSeconds") || 2) * 1000
        repeat: true
        running: root.sampling
        onTriggered: root.sample()
    }
    // Aplicaciones: una muestra de cada dos (cada 4 s, D2).
    property int appTick: 0
    function sample(): void {
        if (!root.infoLoaded) {
            if (!infoProc.running) infoProc.running = true;
            return; // la primera muestra sale al terminar (rutas de sensores)
        }
        if (root.basic.active || root.detail.active) {
            statFile.reload();
            memFile.reload();
            if (root.paths.cpuTemp) tempFile.reload();
        }
        if (root.detail.active || root.net.active) netFile.reload();
        if (root.detail.active) {
            uptimeFile.reload();
            if (root.appTick === 0 && !procsProc.running) procsProc.running = true;
            root.appTick = (root.appTick + 1) % 2;
            if (root.paths.gpuBusy) gpuBusyFile.reload();
            if (root.paths.gpuTemp) gpuTempFile.reload();
            if (root.paths.nvmeTemp) nvmeTempFile.reload();
            if (root.paths.dgpuPower) dgpuPowerFile.reload();
        }
    }

    // ---- Datos fijos (una vez) -----------------------------------------------------
    property bool infoLoaded: false
    property string distro: ""
    property string kernel: ""
    property string cpuModel: ""
    property int cpuThreads: 1
    property int clockTicks: 100
    property int pageSize: 4096
    property string igpuName: ""
    property string dgpuName: ""
    property var paths: ({ cpuTemp: "", gpuTemp: "", gpuBusy: "", nvmeTemp: "", dgpuPower: "" })
    property Process infoProc: Process {
        command: ["sh", "-c", ". /etc/os-release 2>/dev/null; echo \"distro=$PRETTY_NAME\"; echo \"kernel=$(uname -r)\";"
            + " echo \"cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2-)\"; echo \"threads=$(nproc)\";"
            + " echo \"tck=$(getconf CLK_TCK)\"; echo \"page=$(getconf PAGESIZE)\";"
            + " for d in /sys/class/hwmon/hwmon*; do echo \"hwmon=$(cat $d/name 2>/dev/null) $d\"; done;"
            + " lspci -mm 2>/dev/null | grep -E 'VGA|3D' | sed 's/^/gpu=/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = { cpuTemp: "", gpuTemp: "", gpuBusy: "", nvmeTemp: "", dgpuPower: "" };
                for (const line of this.text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i < 0) continue;
                    const k = line.slice(0, i), v = line.slice(i + 1).trim();
                    if (k === "distro") root.distro = v;
                    else if (k === "kernel") root.kernel = v;
                    else if (k === "cpu") root.cpuModel = v;
                    else if (k === "threads") root.cpuThreads = Math.max(1, Number(v) || 1);
                    else if (k === "tck") root.clockTicks = Number(v) || 100;
                    else if (k === "page") root.pageSize = Number(v) || 4096;
                    else if (k === "hwmon") {
                        const [name, dir] = v.split(" ");
                        if (!p.cpuTemp && ["k10temp", "coretemp", "zenpower"].indexOf(name) >= 0) p.cpuTemp = dir + "/temp1_input";
                        else if (name === "amdgpu" && !p.gpuTemp) {
                            p.gpuTemp = dir + "/temp1_input";
                            p.gpuBusy = dir + "/device/gpu_busy_percent";
                        } else if (name === "nvme" && !p.nvmeTemp) p.nvmeTemp = dir + "/temp1_input";
                    } else if (k === "gpu") {
                        // "... "NVIDIA Corporation" "GA107BM [GeForce RTX 3050 6GB Laptop GPU]" ..."
                        const fields = v.match(/"[^"]*"/g) || [];
                        const vendor = (fields[1] || "").replace(/"/g, "");
                        const model = (fields[2] || "").replace(/"/g, "");
                        const bracket = model.match(/\[([^\]]+)\]/);
                        if (/nvidia/i.test(vendor)) {
                            root.dgpuName = (bracket ? bracket[1] : model).replace(/\s*Laptop GPU$/, "").replace(/^GeForce\s+/, "");
                            const slot = v.split(" ")[0];
                            p.dgpuPower = "/sys/bus/pci/devices/" + (slot.split(":").length === 2 ? "0000:" : "") + slot + "/power/runtime_status";
                        }
                        else if (!root.igpuName) root.igpuName = bracket ? bracket[1] : "";
                    }
                }
                // La grafica integrada de AMD viene nombrada en el modelo de CPU
                // ("Ryzen 7 8845HS w/ Radeon 780M Graphics").
                const inCpu = root.cpuModel.match(/w\/\s*(Radeon[^,]*?)\s*Graphics/i);
                if (inCpu) root.igpuName = inCpu[1];
                if (!root.igpuName && p.gpuTemp) root.igpuName = "Gráfica integrada";
                root.cpuModel = root.cpuModel.replace(/\s*w\/.*$/, "").replace(/^AMD\s+/, "").replace(/\s+\d+-Core Processor$/, "").trim();
                root.paths = p;
                root.infoLoaded = true;
                if (root.sampling) root.sample();
            }
        }
    }

    // ---- CPU (/proc/stat, linea "cpu") -------------------------------------------
    property real cpu: 0          // 0..1
    property int cpuHighCount: 0  // muestras seguidas por encima del 90 %
    property var prev: null       // { total, idle, at }
    property FileView statFile: FileView {
        path: "/proc/stat"
        printErrors: false
        onLoaded: {
            const f = this.text().split("\n", 1)[0].trim().split(/\s+/).slice(1, 9).map(Number);
            if (f.length < 8) return;
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            const now = Date.now();
            const p = root.prev;
            root.prev = { total: total, idle: idle, at: now };
            // Sin muestra reciente (recien abierto): una segunda en 300 ms, para
            // no mostrar el promedio de todo el rato que estuvo cerrado.
            if (!p || now - p.at > 5000) {
                quick.restart();
                return;
            }
            const dt = total - p.total;
            if (dt <= 0) return;
            root.cpu = Math.max(0, Math.min(1, 1 - (idle - p.idle) / dt));
            root.cpuHighCount = root.cpu >= 0.9 ? root.cpuHighCount + 1 : 0;
        }
    }
    property Timer quick: Timer {
        interval: 300
        onTriggered: if (root.sampling) statFile.reload()
    }

    // ---- Memoria (/proc/meminfo) -------------------------------------------------
    property real memTotal: 0     // bytes
    property real memUsed: 0      // MemTotal - MemAvailable
    property real swapTotal: 0
    property real swapUsed: 0
    readonly property real memFrac: root.memTotal > 0 ? root.memUsed / root.memTotal : 0
    property FileView memFile: FileView {
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: {
            const t = this.text();
            const kb = k => {
                const m = t.match(new RegExp("^" + k + ":\\s+(\\d+)", "m"));
                return m ? Number(m[1]) * 1024 : 0;
            };
            root.memTotal = kb("MemTotal");
            root.memUsed = root.memTotal - kb("MemAvailable");
            root.swapTotal = kb("SwapTotal");
            root.swapUsed = root.swapTotal - kb("SwapFree");
        }
    }

    // ---- Temperaturas (hwmon) --------------------------------------------------------
    property real temp: NaN       // CPU, °C
    property real gpuTemp: NaN    // grafica integrada
    property real nvmeTemp: NaN
    function milli(text: string): real {
        const v = Number(text.trim());
        return isNaN(v) ? NaN : v / 1000;
    }
    property FileView tempFile: FileView {
        path: root.paths.cpuTemp
        printErrors: false
        onLoaded: root.temp = root.milli(this.text())
    }
    property FileView gpuTempFile: FileView {
        path: root.paths.gpuTemp
        printErrors: false
        onLoaded: root.gpuTemp = root.milli(this.text())
    }
    property FileView nvmeTempFile: FileView {
        path: root.paths.nvmeTemp
        printErrors: false
        onLoaded: root.nvmeTemp = root.milli(this.text())
    }

    // ---- Graficas ----------------------------------------------------------------
    property real gpuBusy: NaN    // integrada, 0..1
    property FileView gpuBusyFile: FileView {
        path: root.paths.gpuBusy
        printErrors: false
        onLoaded: {
            const v = Number(this.text().trim());
            root.gpuBusy = isNaN(v) ? NaN : v / 100;
        }
    }
    // dGPU NVIDIA: su estado de energia (runtime PM) se lee de sysfs en cada
    // muestra, sin despertarla. Que procesos la usan lo dice nvidia-status.sh
    // (~90 ms de CPU: python + lsof), asi que se corre solo al entrar en la
    // vista y cuando el estado cambia, no en cada muestra.
    // nvidia: { active, text, processes: [{ pid, name }] }
    property var nvidia: null
    property string dgpuPower: ""
    property FileView dgpuPowerFile: FileView {
        path: root.paths.dgpuPower
        printErrors: false
        onLoaded: {
            const state = this.text().trim();
            if (state === root.dgpuPower) return;
            root.dgpuPower = state;
            if (state === "active") {
                if (!nvidiaProc.running) nvidiaProc.running = true;
            } else {
                root.nvidia = { active: false, text: "En reposo", processes: [] };
            }
        }
    }
    property Process nvidiaProc: Process {
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/nvidia-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.nvidia = JSON.parse(this.text);
                } catch (e) {
                    root.nvidia = null;
                }
            }
        }
    }

    // ---- Tiempo encendido --------------------------------------------------------
    property real uptime: 0       // segundos
    property FileView uptimeFile: FileView {
        path: "/proc/uptime"
        printErrors: false
        onLoaded: root.uptime = Number(this.text().split(" ")[0]) || 0
    }

    // ---- Red (/proc/net/dev de la interfaz en uso) -------------------------------
    property real rxRate: 0       // bytes/s
    property real txRate: 0
    property var netPrev: null
    property FileView netFile: FileView {
        path: "/proc/net/dev"
        printErrors: false
        onLoaded: {
            const iface = NetworkState.interfaceName;
            const line = iface ? this.text().split("\n").find(l => l.trim().startsWith(iface + ":")) : null;
            if (!line) {
                root.rxRate = 0;
                root.txRate = 0;
                root.netPrev = null;
                return;
            }
            const f = line.split(":")[1].trim().split(/\s+/).map(Number);
            const now = Date.now();
            const p = root.netPrev;
            root.netPrev = { iface: iface, rx: f[0], tx: f[8], at: now };
            if (!p || p.iface !== iface || now - p.at > 5000) return;
            const dt = (now - p.at) / 1000;
            root.rxRate = Math.max(0, (f[0] - p.rx) / dt);
            root.txRate = Math.max(0, (f[8] - p.tx) / dt);
        }
    }

    // ---- Almacenamiento (al abrir Sistema; Mantenimiento lo pide con refreshStorage) --
    // [{ mount, size, used, avail }] de / y, si es otro sistema de archivos, /home.
    property var storage: []
    function refreshStorage(): void {
        if (!storageProc.running) storageProc.running = true;
    }
    property Process storageProc: Process {
        command: ["df", "-B1", "--output=target,size,used,avail", "/", Quickshell.env("HOME")]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const line of this.text.trim().split("\n").slice(1)) {
                    const f = line.trim().split(/\s+/);
                    if (f.length < 4 || seen[f[0]]) continue;
                    seen[f[0]] = true;
                    out.push({ mount: f[0], size: Number(f[1]), used: Number(f[2]), avail: Number(f[3]) });
                }
                root.storage = out;
            }
        }
    }

    // ---- Aplicaciones (vista Sistema) -----------------------------------------------
    // Procesos agrupados por aplicacion: cada proceso cuenta para el que lanzo
    // Hyprland (o una terminal, o systemd): todas las pestanas de Zen suman en
    // "Zen Browser", un compilador lanzado desde kitty cuenta como el mismo.
    // CPU = uso entre dos muestras, como parte de TODO el equipo (igual que el
    // medidor de CPU); memoria = suma de RSS (cuenta de mas la memoria
    // compartida entre procesos de la misma app).
    // apps: [{ key, name, icon, cpu (0..1), mem (bytes), count }], las 5 que mas usan.
    property var apps: []
    property var procPrev: null   // { at, ticks: { pid: ticks } }
    readonly property var shells: ["sh", "bash", "zsh", "fish", "dash", "nu"]
    function groupProcesses(text: string): void {
        // Una lectura que termina despues de soltar la vista no vuelve a llenar nada.
        if (!root.detail.active) return;
        const procs = {};
        for (const line of text.split("\n")) {
            const open = line.indexOf(" (");
            const close = line.lastIndexOf(") ");
            if (open < 0 || close < 0) continue;
            const pid = Number(line.slice(0, open));
            const f = line.slice(close + 2).split(" ");
            const ppid = Number(f[1]);
            if (pid === 2 || ppid === 2) continue; // hilos del kernel
            procs[pid] = { comm: line.slice(open + 2, close), ppid: ppid, ticks: Number(f[11]) + Number(f[12]), rss: Number(f[21]) };
        }
        // Raiz de cada proceso: se sube mientras el padre no sea un "lanzador".
        const isStop = p => !p || p.ppid <= 1 || !procs[p.ppid] || p.comm === "Hyprland"
            || procs[p.ppid].comm === "Hyprland" || procs[p.ppid].comm === "systemd" || root.shells.indexOf(procs[p.ppid].comm) >= 0;
        const rootOf = {};
        const findRoot = pid => {
            if (rootOf[pid] !== undefined) return rootOf[pid];
            const p = procs[pid];
            const r = isStop(p) ? pid : findRoot(p.ppid);
            rootOf[pid] = r;
            return r;
        };
        const now = Date.now();
        const prev = root.procPrev && now - root.procPrev.at < 6000 ? root.procPrev : null;
        const dt = prev ? (now - prev.at) / 1000 : 0;
        const ticks = {};
        const groups = {};
        for (const k in procs) {
            const pid = Number(k), p = procs[pid];
            ticks[pid] = p.ticks;
            const r = procs[findRoot(pid)];
            const key = AppInfo.normalize(r.comm);
            const g = groups[key] || (groups[key] = { key: key, comm: r.comm, cpu: 0, mem: 0, count: 0 });
            g.mem += p.rss * root.pageSize;
            g.count++;
            if (prev) {
                const before = prev.ticks[pid];
                const d = before === undefined ? 0 : p.ticks - before;
                g.cpu += Math.max(0, d) / (root.clockTicks * dt * root.cpuThreads);
            }
        }
        root.procPrev = { at: now, ticks: ticks };
        // Lo que casi no usa CPU (< 0,5 %) se ordena por memoria: sin esto, con
        // el equipo en reposo el orden seria ruido de una muestra a otra.
        const busy = g => g.cpu >= 0.005 ? g.cpu : 0;
        root.apps = Object.values(groups)
            .sort((a, b) => (busy(b) - busy(a)) || (b.mem - a.mem))
            .slice(0, 5)
            .map(g => ({ key: g.key, name: AppInfo.name(g.comm), icon: AppInfo.icon(g.comm), cpu: g.cpu, mem: g.mem, count: g.count }));
    }
    property Process procsProc: Process {
        command: ["sh", "-c", "cat /proc/[0-9]*/stat 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.groupProcesses(this.text)
        }
    }

    // ---- Estado general -----------------------------------------------------------
    // level: 0 bien, 1 atencion, 2 critico. El primero que aplique, por gravedad.
    readonly property var status: {
        if (BatteryState.critical) return { level: 2, text: "Batería crítica" };
        if (root.temp >= 95) return { level: 2, text: "Temperatura muy alta" };
        if (root.temp >= 88) return { level: 1, text: "Temperatura alta" };
        if (root.memFrac >= 0.92) return { level: 1, text: "Memoria casi llena" };
        if (root.cpuHighCount >= 3) return { level: 1, text: "CPU al máximo" };
        if (BatteryState.warning) return { level: 1, text: "Batería baja" };
        return { level: 0, text: "Todo en orden" };
    }
    // Palabras de estado (las mismas en Inicio y en Sistema).
    function cpuWord(v: real): string {
        return v < 0.25 ? "Tranquila" : v < 0.6 ? "Moderada" : v < 0.9 ? "Exigida" : "Al máximo";
    }
    function memWord(v: real): string {
        return v < 0.6 ? "Holgada" : v < 0.85 ? "En uso" : v < 0.92 ? "Justa" : "Casi llena";
    }
    function diskWord(v: real): string {
        return v < 0.8 ? "Con espacio" : v < 0.92 ? "Ajustado" : "Casi lleno";
    }
    function tempWord(t: real): string {
        return isNaN(t) ? "" : t < 60 ? "fresca" : t < 80 ? "normal" : t < 95 ? "alta" : "muy alta";
    }

    // ---- Formato -------------------------------------------------------------------
    // "3 h 20 min", "45 min".
    function duration(seconds: real): string {
        const m = Math.round(seconds / 60);
        if (m < 60) return m + " min";
        const h = Math.floor(m / 60);
        if (h >= 48) return Math.floor(h / 24) + " días";
        return h + " h" + (m % 60 ? " " + (m % 60) + " min" : "");
    }
    // "7,9 GB", "420 MB" (coma decimal, como el resto de la shell).
    function bytes(b: real): string {
        const gb = b / 1073741824;
        if (gb >= 100) return Math.round(gb) + " GB";
        if (gb >= 1) return gb.toFixed(1).replace(".", ",") + " GB";
        return Math.round(b / 1048576) + " MB";
    }
    function rate(bps: real): string {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1).replace(".", ",") + " MB/s";
        if (bps >= 1024) return Math.round(bps / 1024) + " kB/s";
        return Math.round(bps) + " B/s";
    }
}
