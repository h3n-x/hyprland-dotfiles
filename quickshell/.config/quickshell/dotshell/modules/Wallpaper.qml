// Wallpaper dibujado por la shell (Fase 3 B6, decision W2). Una ventana por
// pantalla en la capa Background, sin entrada, debajo de todo.
//
// La imagen sale de Colors.image (el wallpaper que matugen acaba de usar, del
// mismo JSON que los colores): wallpaper y paleta cambian en el mismo momento
// y con la misma duracion (decision B6a). El cambio es un fundido entre dos
// Image: la nueva aparece encima solo cuando ya esta decodificada.
//
// Para que la decodificacion (hasta ~0.4 s en una imagen grande) no atrase el
// fundido respecto de los colores, la imagen se precarga apenas se pide el
// cambio (ThemeState.current, que theme-apply.sh escribe al pedir, ~1 s antes
// de que matugen termine) y el fundido arranca cuando llega el JSON.
//
// Vuelta atras: con prefs.wallpaper_backend = "hyprpaper" (theme-apply.sh
// --backend hyprpaper) esta ventana se oculta y suelta la imagen.
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import ".." // Colors.qml, Tokens.qml, ThemeState.qml

PanelWindow {
    id: root

    // Recargar la shell: Quickshell llena los FileView (colores, estado) recien
    // despues de crear los modulos. Hasta entonces vale lo que se mostraba
    // antes de la recarga: la ventana no se desmapea y la imagen sale de la
    // cache de Qt al instante, sin pasar por el color liso.
    PersistentProperties {
        id: persist
        reloadableId: "wallpaper"
        // Ya habia una imagen en pantalla (recarga, no arranque de la shell).
        property bool shown: false
        // Escala final de la ventana (ver dprStable).
        property real dpr: 0
        property bool active: true
        // Ultima: se restauran en orden y la imagen dispara la carga.
        property string image: ""
    }

    readonly property bool active: ThemeState.settled ? ThemeState.wallpaperBackend === "quickshell" : persist.active
    // Sin JSON de colores todavia: el wallpaper registrado por theme-apply.sh.
    readonly property string wallpaper: Colors.image || (ThemeState.current && ThemeState.current.wallpaper) || persist.image
    readonly property url target: (root.active && root.wallpaper) ? "file://" + root.wallpaper : ""
    // El que se acaba de pedir: se decodifica mientras corre matugen.
    readonly property url upcoming: (root.active && ThemeState.current && ThemeState.current.wallpaper)
        ? "file://" + ThemeState.current.wallpaper : ""

    // Tamaño fijo de decodificacion (pixeles reales de la pantalla): atarlo al
    // tamaño de la ventana reinicia la decodificacion mientras se mapea.
    readonly property size decodeSize: Qt.size(Math.round(root.screen.width * root.screen.devicePixelRatio),
                                               Math.round(root.screen.height * root.screen.devicePixelRatio))

    visible: root.active
    // Sin imagen o si no se puede leer: color de fondo de la paleta, nunca
    // negro. Transparente hasta que la primera imagen termino de entrar: al
    // volver de hyprpaper se sigue viendo el suyo debajo durante el fundido.
    color: root.painted ? Colors.m3surface : "transparent"

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    mask: Region {}

    onActiveChanged: if (ThemeState.settled) persist.active = root.active
    onWallpaperChanged: if (root.wallpaper) persist.image = root.wallpaper

    // front: la imagen visible; back: la que entra. Se intercambian al terminar.
    property Image front: slotA
    property Image back: slotB
    // Avance del fundido (0..1). Si la nueva no se pudo leer, la vieja se
    // desvanece hacia el color de fondo en vez de cortar.
    property real mix: 0
    readonly property bool backFailed: root.back.status === Image.Error
    // Ya se mostro una imagen. La primera entra sin fundido tras una recarga
    // (ya estaba en pantalla) y con fundido desde el color de fondo al
    // arrancar la shell (inicio de sesion).
    property bool started: false
    // La primera imagen ya termino de entrar.
    property bool painted: false

    // Al mapear una ventana nueva, su escala pasa por 2 -> 1 -> 1.5 en pocos
    // ms (fractional scaling) y cada cambio hace que Image se recargue en
    // blanco. Se carga recien cuando la escala es la final: la recordada de
    // la generacion anterior (recarga, al instante) o, al arrancar la shell,
    // 50 ms sin cambios.
    property bool dprStable: false
    function checkDpr(): void {
        if (root.dprStable || !root.backingWindowVisible)
            return;
        if (persist.dpr > 0 && root.devicePixelRatio === persist.dpr)
            root.settleDpr();
        else
            dprSettle.restart();
    }
    function settleDpr(): void {
        dprSettle.stop();
        root.dprStable = true;
        persist.dpr = root.devicePixelRatio;
        root.show();
        root.preload();
    }
    Timer {
        id: dprSettle
        interval: 50
        onTriggered: root.settleDpr()
    }
    onBackingWindowVisibleChanged: {
        root.dprStable = false;
        root.checkDpr();
    }
    onDevicePixelRatioChanged: root.checkDpr()

    onTargetChanged: root.show()
    onUpcomingChanged: root.preload()
    Component.onCompleted: root.checkDpr()

    // Mostrar root.target: si ya esta precargada en back, el fundido arranca
    // ya; si no, en cuanto se decodifique.
    function show(): void {
        if (fade.running)
            fade.complete();
        const src = String(root.target);
        // Backend hyprpaper (ventana oculta) o sin wallpaper: se suelta todo.
        if (src === "") {
            slotA.source = "";
            slotB.source = "";
            root.mix = 0;
            root.started = false;
            root.painted = false;
            persist.shown = false;
            return;
        }
        if (src === String(root.front.source) || !root.dprStable)
            return;
        if (src !== String(root.back.source))
            root.back.source = src;
        // Ya decodificada (precarga o cache): onStatusChanged no vuelve a pasar.
        if (root.back.status !== Image.Loading)
            root.reveal(root.back);
    }

    // Decodificar en back el wallpaper pedido, sin mostrarlo todavia.
    function preload(): void {
        const src = String(root.upcoming);
        if (!root.started || !root.dprStable || src === "" || src === String(root.target)
            || src === String(root.front.source) || src === String(root.back.source))
            return;
        if (fade.running)
            fade.complete();
        root.back.source = src;
    }

    function reveal(img: Image): void {
        // Solo la que entra, y solo si es la que corresponde a los colores
        // actuales (una precarga espera al JSON).
        if (img !== root.back || String(img.source) !== String(root.target))
            return;
        if ((!root.started && persist.shown) || Tokens.motion.scale <= 0) {
            root.swap();
        } else {
            fade.start();
        }
        root.started = true;
    }

    // La que entra pasa a ser la visible; la vieja se suelta (memoria).
    function swap(): void {
        const old = root.front;
        root.front = root.back;
        root.back = old;
        root.mix = 0;
        old.source = "";
        root.painted = true;
        persist.shown = true;
    }

    component Slot: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: root.decodeSize
        asynchronous: true
        smooth: true
        // La que entra va arriba.
        z: this === root.back ? 1 : 0
        opacity: this === root.back ? root.mix : (root.backFailed ? 1 - root.mix : 1)
        onStatusChanged: {
            if (status === Image.Ready || status === Image.Error)
                root.reveal(this);
        }
    }

    Slot {
        id: slotA
    }
    Slot {
        id: slotB
    }

    // Misma curva y duracion que el cambio de colores (Colors.qml).
    NumberAnimation {
        id: fade
        target: root
        property: "mix"
        from: 0
        to: 1
        duration: Tokens.motion.theme
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Tokens.motion.easeStandard
        onFinished: root.swap()
    }
}
