// ============================================================================
// LibreWolf -- user.js
// LibreWolf ya viene con privacidad/telemetria endurecidas por defecto
// (compilado, no vive en un archivo de prefs inspeccionable) -- esto NO
// duplica eso, solo agrega UX/Wayland que no toca.
// ============================================================================

// userChrome.css/userContent.css -- LibreWolf ya lo trae en true por
// defecto, se deja explicito por si un reset de perfil lo pisa.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Scroll suave
user_pref("general.smoothScroll", true);

// UI compacta (mas parecido al resto del rice, que es bastante denso)
user_pref("browser.uidensity", 1);
user_pref("browser.compactmode.show", true);

// Refuerzo de escalado fraccional en Wayland (mismo problema que arreglamos
// para XWayland/Steam con xwayland:force_zero_scaling en lookandfeel.lua --
// esto es el lado nativo-Wayland, monitor a scale=1.5 en monitors.lua)
user_pref("widget.wayland.fractional-scale.enabled", true);

// Aceleracion de hardware / VA-API (iGPU AMD 760M activa la mayor parte del
// tiempo, ver env.lua)
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("gfx.webrender.all", true);
