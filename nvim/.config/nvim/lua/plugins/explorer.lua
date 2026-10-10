-- ============================================================================
-- Explorador de archivos del proyecto
--
-- JUSTIFICACIÓN DE ELECCIÓN: Snacks Explorer vs Neo-tree / Nvim-Tree
-- 1. Cero dependencias pesadas: No arrastra nui.nvim ni árboles de procesos lentos.
-- 2. Velocidad de apertura instantánea (<1ms) integrada con el motor asíncrono de Snacks.
-- 3. Theming dinámico perfecto: Hereda los highlights de base16-nvim y la transparencia
--    de ventana sin bordes discordantes ni fondos duros.
-- 4. Coexistencia con Yazi: El atajo `<leader>e` abre el explorador tipo sidebar nativo,
--    mientras que `<leader>-` permite abrir el gestor TUI Yazi (también sincronizado con Matugen).
-- ============================================================================

return {
	-- Yazi como explorador TUI modal integrado con Matugen
	{
		"mikavilpas/yazi.nvim",
		version = "*",
		cmd = { "Yazi" },
		keys = {
			{ "<leader>-", mode = { "n", "v" }, "<cmd>Yazi<CR>", desc = "Yazi (directorio de archivo actual)" },
			{ "<leader>cy", "<cmd>Yazi cwd<CR>", desc = "Yazi (raíz del proyecto)" },
		},
		opts = {
			open_for_directories = false,
			keymaps = { show_help = "<f1>" },
		},
	},

	-- Snacks Explorer como barra lateral de navegación ágil
	{
		"folke/snacks.nvim",
		opts = {
			explorer = {
				enabled = true,
			},
		},
		keys = {
			{
				"<leader>e",
				function()
					Snacks.explorer()
				end,
				desc = "Alternar explorador de archivos (Snacks Explorer)",
			},
			{
				"<leader>fe",
				function()
					Snacks.explorer()
				end,
				desc = "Explorador de archivos lateral",
			},
		},
	},
}
