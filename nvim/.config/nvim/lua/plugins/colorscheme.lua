-- ============================================================================
-- Plugin: RRethy/base16-nvim
-- Theming dinámico integrado con Matugen (Material You)
-- Paleta sincronizada con el wallpaper activo vía lua/matugen_colors.lua
-- ============================================================================

return {
	"RRethy/base16-nvim",
	lazy = false,
	priority = 1000,
	config = function()
		-- Cargar e inicializar el sistema de theming matugen con watcher libuv y :MatugenReload
		require("config.matugen").setup()
	end,
}
