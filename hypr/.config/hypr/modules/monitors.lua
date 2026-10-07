-- ============================================================================
-- Monitores
-- https://wiki.hypr.land/configuring/core/monitors/
-- ============================================================================

-- Regla generica (de fabrica) para cualquier pantalla: su modo preferido, a la
-- derecha de las demas y la escala que Hyprland calcula. Lo que elijas en
-- Configuracion -> Pantallas (resolucion, frecuencia, escala, posicion,
-- rotacion, VRR, color...) se guarda en tu almacen y llega como reglas en
-- ~/.local/state/dotfiles/hypr-overrides.lua, que se carga al final y gana
-- (Fase 10 B5). Este archivo no lleva datos de un equipo en particular.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
