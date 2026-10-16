-- Generado por matugen -- no editar a mano, editar templates/nvim-colors.lua
-- Paleta base16 (RRethy/base16.nvim): base00-07 son el marco (roles de Material); base08-0F,
-- la sintaxis, salen de la paleta de codigo (Fase 18, palette code) con la convencion de base16:
-- 08 etiquetas/integrados, 09 numeros, 0A tipos, 0B cadenas, 0C escapes, 0D funciones,
-- 0E palabras clave, 0F anotaciones. Los colores de estado fijos (P8.7) no van en base16:
-- config/matugen.lua los pone en diagnosticos, diff y git (tabla "semantic"), con los estilos.
-- Modo de la paleta (P5.5): base16 no lo fija; asi los plugins que miran
-- 'background' eligen sus colores claros u oscuros. Corre cada vez que se lee
-- este archivo (al arrancar y en cada recarga de la paleta).
vim.o.background = "{{theme.mode}}"

return {
	base00 = "{{colors.surface.default.hex_stripped}}",
	base01 = "{{colors.surface_container_low.default.hex_stripped}}",
	base02 = "{{colors.surface_container_high.default.hex_stripped}}",
	base03 = "{{code.comment.default.hex_stripped}}",
	base04 = "{{colors.on_surface_variant.default.hex_stripped}}",
	base05 = "{{colors.on_surface.default.hex_stripped}}",
	base06 = "{{colors.on_surface.default.hex_stripped}}",
	base07 = "{{colors.surface_bright.default.hex_stripped}}",
	base08 = "{{code.tag.default.hex_stripped}}",
	base09 = "{{code.number.default.hex_stripped}}",
	base0A = "{{code.type.default.hex_stripped}}",
	base0B = "{{code.string.default.hex_stripped}}",
	base0C = "{{code.escape.default.hex_stripped}}",
	base0D = "{{code.function.default.hex_stripped}}",
	base0E = "{{code.keyword.default.hex_stripped}}",
	base0F = "{{code.annotation.default.hex_stripped}}",
	semantic = {
		error = "#{{status.error.default.hex_stripped}}",
		warning = "#{{status.warning.default.hex_stripped}}",
		success = "#{{status.success.default.hex_stripped}}",
		styles = {
			comment = "{{code_style.comment}}",
			keyword = "{{code_style.keyword}}",
			type = "{{code_style.type}}",
		},
	},
}
