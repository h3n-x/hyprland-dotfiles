// Design tokens de la shell (tarea P1.2 del roadmap). Los valores salen de
// las escalas aprobadas del sistema de diseno (decisiones D1-D14) -- no
// inventar valores aca: si falta un token, se agrega primero a la escala y
// despues a este archivo.
//
// Los colores NO van aca: salen de matugen via Colors.qml (generado, no se
// edita a mano). Este archivo es fuente, escrito a mano, sin valores de paleta.
//
// Los modulos migran a estos tokens en P1.10; hasta entonces nadie los lee
// todavia (agregarlo no cambia nada visible).
pragma Singleton
import QtQuick

// Cada grupo es un inline component (no un QtObject suelto) para que qmllint
// y el compilador de QML conozcan sus miembros: Tokens.space.sm queda tipado
// en los modulos que lo usen. Los inline components no ven el id "root",
// asi que los tokens derivados (gap, pad, bar) se asignan al instanciarlos.
QtObject {
    id: root

    // ---- Tipografia (D1, D2) ----------------------------------------------
    // Interfaz = Plus Jakarta Sans; codigo/terminal = Maple Mono NF; iconos =
    // Material Symbols Rounded. Nombres de familia tal cual los expone
    // fontconfig (verificar con fc-list despues de instalarlas en P1.3).
    component FontFamilies: QtObject {
        readonly property string ui: "Plus Jakarta Sans"
        readonly property string mono: "Maple Mono NF"
        readonly property string icon: "Material Symbols Rounded"
        readonly property string emoji: "Noto Color Emoji"   // selector de emoji (P4 B3)
    }
    readonly property FontFamilies font: FontFamilies {}

    component TypeScale: QtObject {
        readonly property int caption: 11   // timestamps, metadata, badges
        readonly property int label: 12     // labels secundarios, botones
        readonly property int body: 13      // texto por defecto, items de lista
        readonly property int title: 15     // titulos de panel/seccion, reloj de la barra
        readonly property int headline: 18  // valores del OSD, titulares de tarjeta
        readonly property int display: 24   // dashboard, numeros grandes
        readonly property int displayLarge: 32
        readonly property int hero: 80      // reloj del lockscreen
    }
    readonly property TypeScale type: TypeScale {}

    component FontWeights: QtObject {
        readonly property int regular: Font.Normal     // 400
        readonly property int medium: Font.Medium      // 500
        readonly property int semibold: Font.DemiBold  // 600
    }
    readonly property FontWeights weight: FontWeights {}

    // Cifras tabulares para relojes, porcentajes y contadores (evita que el
    // texto "baile" al cambiar de digito). Se asigna a font.features.
    readonly property var tabularNumbers: ({ "tnum": 1 })

    // ---- Espaciado: grilla de 4 px (D3) -----------------------------------
    // DESIGN_TOKENS.md §3.3 los numera space.0..6; aca van con nombre porque
    // QML no admite propiedades numericas: hair=2, xs=4 (1), sm=8 (2),
    // md=12 (3), lg=16 (4), xl=24 (5), xxl=32 (6).
    component SpaceScale: QtObject {
        readonly property int none: 0
        readonly property int hair: 2
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 24
        readonly property int xxl: 32
    }
    readonly property SpaceScale space: SpaceScale {}

    // Alias semanticos: los componentes usan estos, no la escala cruda.
    component GapTokens: QtObject {
        property int inline   // icono <-> label
        property int stack    // filas apiladas
    }
    readonly property GapTokens gap: GapTokens {
        inline: root.space.sm
        stack: root.space.sm
    }

    component PadTokens: QtObject {
        property int pillH
        property int pillV
        property int panel
        property int card
    }
    readonly property PadTokens pad: PadTokens {
        pillH: root.space.md
        pillV: root.space.xs
        panel: root.space.lg
        card: root.space.sm
    }

    // = gaps_out de Hyprland (hypr/.config/hypr/modules/lookandfeel.lua), asi
    // los bordes de la barra y de los popups quedan alineados con las ventanas.
    readonly property int screenEdge: 12

    // ---- Radios: escala Material 3 (D4) -----------------------------------
    // md = rounding de las ventanas de Hyprland (12 desde P1.4). Regla de
    // anidado: radio interno = radio del padre - padding del padre (minimo xs),
    // ver nested(). Para pildoras usar pill(height), no un numero fijo.
    component RadiusScale: QtObject {
        readonly property int none: 0
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 24

        function pill(height) {
            return height / 2;
        }

        function nested(parentRadius, parentPadding) {
            return Math.max(xs, parentRadius - parentPadding);
        }
    }
    readonly property RadiusScale radius: RadiusScale {}

    // ---- Elevacion (D5, D6) -----------------------------------------------
    // Nivel -> rol de superficie vive en Colors (P1.9); aca solo lo que no es
    // color: sombras neutras (color = rol "shadow" de matugen) y opacidades.
    // blur/offset en px logicos; la conversion a MultiEffect se hace en P2.2.
    component ShadowSpec: QtObject {
        property int blur
        property int offsetY
        property real opacity
    }
    component ShadowScale: QtObject {
        readonly property ShadowSpec sm: ShadowSpec { blur: 8; offsetY: 2; opacity: 0.20 }
        readonly property ShadowSpec md: ShadowSpec { blur: 16; offsetY: 4; opacity: 0.28 }
        readonly property ShadowSpec lg: ShadowSpec { blur: 24; offsetY: 8; opacity: 0.36 }
    }
    readonly property ShadowScale shadow: ShadowScale {}

    // Nivel de elevacion -> sombra. elev.0/1 sin sombra; 2 dropdowns y centro
    // de control; 3 toasts, OSD, launcher; 4 menus sobre paneles, tooltips.
    readonly property var elevationShadow: [null, null, shadow.sm, shadow.md, shadow.lg]

    component Opacities: QtObject {
        // Mismo valor que active_opacity de las ventanas y kitty (D6, sujeto
        // a la prueba de rendimiento del blur en P2.1).
        readonly property real surface: 0.92
        readonly property real scrim: 0.40     // fondo de overlays a pantalla completa
        readonly property real disabled: 0.38  // contenido deshabilitado (M3)
    }
    readonly property Opacities opacity: Opacities {}

    // Capas de estado M3 (D11): opacidad del color de *contenido* del elemento
    // superpuesta a su fondo. Arregla el hover que hoy no se ve (KI-C12).
    component StateLayers: QtObject {
        readonly property real hover: 0.08
        readonly property real focus: 0.10
        readonly property real pressed: 0.10
        readonly property real dragged: 0.16
    }
    readonly property StateLayers stateLayer: StateLayers {}

    // ---- Movimiento (D7, D8, D9) ------------------------------------------
    // Mismas curvas que hl.curve() en lookandfeel.lua, asi la shell se mueve
    // como Hyprland. Las curvas van a easing.bezierCurve con
    // easing.type: Easing.BezierSpline.
    // mass/stiffness/damping: valores fuente del spring "easy" de Hyprland
    // (referencia). qmlSpring/qmlDamping: los mismos, traducidos a los
    // parametros de SpringAnimation -- calibrados empiricamente contra la
    // curva de Hyprland (60 corridas, error medio 1.1%, asienta en 254 vs
    // 241 ms; decision M1).
    // Uso: SpringAnimation { spring: Tokens.motion.spring.qmlSpring;
    //                        damping: Tokens.motion.spring.qmlDamping }
    component SpringSpec: QtObject {
        readonly property real mass: 1
        readonly property real stiffness: 238.1191
        readonly property real damping: 24.21279333
        readonly property real qmlSpring: 2.6
        readonly property real qmlDamping: 0.31
    }
    component MotionTokens: QtObject {
        // Reducir movimiento (D9): 1 = normal, 0 = sin animaciones. Unico
        // token escribible, para poder cambiarlo en runtime (IPC mas adelante).
        property real scale: 1

        readonly property int instant: 0
        readonly property int fast: Math.round(100 * scale)    // hover, press, knob
        readonly property int short: Math.round(200 * scale)   // salidas, popups chicos, OSD
        readonly property int medium: Math.round(300 * scale)  // paneles, dropdowns, toasts
        readonly property int long: Math.round(400 * scale)    // launcher, dashboard
        readonly property int theme: Math.round(600 * scale)   // crossfade de paleta (P3.11)

        // Una salida dura ~0.6x la entrada equivalente.
        function exitFor(enterDuration) {
            return Math.round(enterDuration * 0.6);
        }

        readonly property var easeEnter: [0.23, 1, 0.32, 1, 1, 1]      // easeOutQuint
        readonly property var easeExit: [0.5, 0.5, 0.75, 1, 1, 1]      // almostLinear
        readonly property var easeStandard: [0.33, 1, 0.68, 1, 1, 1]   // easeOutCubic
        // M3 emphasized decelerate: sale rapido y se posa despacio. Para
        // recorridos largos con destino (el vuelo de la miniatura, P4 B8).
        readonly property var easeEmphasized: [0.05, 0.7, 0.1, 1, 1, 1]

        // Resorte "easy" de Hyprland (movimiento espacial: pill de workspace,
        // knobs, toasts apilados). Valores fuente de hl.curve(); SpringAnimation
        // de QML usa otros parametros, el mapeo se calibra en P1.7.
        readonly property SpringSpec spring: SpringSpec {}
    }
    readonly property MotionTokens motion: MotionTokens {}

    // ---- Iconos (D10) -----------------------------------------------------
    // Material Symbols Rounded (fuente variable). Relleno 0 = apagado/inactivo,
    // 1 = encendido/activo. Se aplican con font.variableAxes.
    component IconTokens: QtObject {
        readonly property int sm: 16
        readonly property int md: 20
        readonly property int lg: 24
        readonly property int xl: 40   // OSD

        // Ejes de Material Symbols (I2): opsz sigue al tamano del icono, peso
        // 400 por defecto (500 junto a texto activo/semibold). Los iconos se
        // escriben por nombre de ligadura con font.family explicita (I4):
        // Text { text: "wifi"; font.family: Tokens.font.icon; font.pixelSize: Tokens.icon.md
        //        font.variableAxes: Tokens.icon.axes(true) }
        function axes(filled, weight, size) {
            return { "FILL": filled ? 1 : 0, "wght": weight === undefined ? 400 : weight,
                     "GRAD": 0, "opsz": size === undefined ? md : size };
        }
    }
    readonly property IconTokens icon: IconTokens {}

    // ---- Tokens de componente (D14) ---------------------------------------
    component BarTokens: QtObject {
        readonly property int height: 40
        property int marginTop
        property int marginSide
    }
    readonly property BarTokens bar: BarTokens {
        marginTop: root.space.sm
        marginSide: root.screenEdge
    }

    component PillTokens: QtObject {
        readonly property int height: 28
    }
    readonly property PillTokens pill: PillTokens {}

    component RowTokens: QtObject {
        readonly property int height: 36        // filas de lista
        readonly property int heightLarge: 44   // toggles tamaño tactil
    }
    readonly property RowTokens row: RowTokens {}

    component PanelTokens: QtObject {
        readonly property int widthSm: 280
        readonly property int widthMd: 320
        readonly property int widthLg: 360
        readonly property int launcherWidth: 560
    }
    readonly property PanelTokens panel: PanelTokens {}

    // Distancia de los popups (OSD, toasts, centro de control) al borde
    // superior: debajo de la barra + un paso de espaciado. Hoy es 60 fijo en
    // tres archivos; con los tokens da 8 + 40 + 12 = 60.
    readonly property int popupTop: bar.marginTop + bar.height + space.md
}
