-- ============================================================================
-- Snacks.nvim: Colección moderna de utilidades ultrarrápidas de folke
-- Dashboard, Notifier, Picker, Terminal Flotante, Lazygit, Explorer e Indent
-- ============================================================================

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		bigfile = { enabled = true },
		quickfile = { enabled = true },
		notifier = {
			enabled = true,
			timeout = 3000,
		},
		indent = {
			enabled = true,
			animate = { enabled = false },
		},
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
		zen = { enabled = true },
		dashboard = {
			enabled = true,
			preset = {
				header = [[
 ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
 ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
 ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
 ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
 ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
				keys = {
					{ icon = " ", key = "f", desc = "Buscar archivos", action = ":lua Snacks.picker.smart()" },
					{ icon = " ", key = "n", desc = "Nuevo archivo", action = ":ene | startinsert" },
					{ icon = " ", key = "g", desc = "Buscar en contenido (grep)", action = ":lua Snacks.picker.grep()" },
					{ icon = " ", key = "r", desc = "Archivos recientes", action = ":lua Snacks.picker.recent()" },
					{ icon = " ", key = "c", desc = "Configuración de Neovim", action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
					{ icon = " ", key = "s", desc = "Restaurar sesión", section = "session" },
					{ icon = "󰏘 ", key = "m", desc = "Recargar tema Matugen", action = ":MatugenReload" },
					{ icon = "󰒲 ", key = "l", desc = "Gestor de plugins (Lazy)", action = ":Lazy" },
					{ icon = " ", key = "q", desc = "Salir de Neovim", action = ":qa" },
				},
			},
		},
		input = { enabled = true },
		bufdelete = { enabled = true },
		terminal = { enabled = true },
		lazygit = { enabled = true },
		scratch = { enabled = true },
		gitbrowse = { enabled = true },
		explorer = { enabled = true },
		picker = {
			enabled = true,
			ui_select = true,
		},
	},
	keys = {
		-- ---- Modo Zen y Notificaciones ----
		{ "<leader>z", function() Snacks.zen() end, desc = "Alternar modo Zen" },
		{ "<leader>N", function() Snacks.notifier.show_history() end, desc = "Historial de notificaciones" },
		{ "<leader>un", function() Snacks.notifier.hide() end, desc = "Ocultar notificaciones activas" },

		-- ---- Terminal flotante integrada ----
		{ "<leader>t", function() Snacks.terminal() end, desc = "Terminal flotante" },
		{ "<C-/>", function() Snacks.terminal() end, desc = "Terminal flotante" },
		{ "<C-_>", function() Snacks.terminal() end, desc = "Terminal flotante" },

		-- ---- Git / Lazygit ----
		{ "<leader>gg", function() Snacks.lazygit() end, desc = "Abrir Lazygit" },
		{ "<leader>gB", function() Snacks.gitbrowse() end, desc = "Ver repositorio en navegador web" },

		-- ---- Scratchpad (notas y pruebas rápidas) ----
		{ "<leader>.", function() Snacks.scratch() end, desc = "Bloc de notas rápido (Scratch)" },
		{ "<leader>S", function() Snacks.scratch.select() end, desc = "Seleccionar scratchpad guardado" },

		-- ---- Snacks Picker (Buscadores ágiles) ----
		{ "<leader><space>", function() Snacks.picker.smart() end, desc = "Buscar archivos (Smart Picker)" },
		{ "<leader>,", function() Snacks.picker.buffers() end, desc = "Buscar buffers activos" },
		{ "<leader>:", function() Snacks.picker.command_history() end, desc = "Historial de comandos" },
		{ "<leader>sp", function() Snacks.picker.pickers() end, desc = "Lista de todos los pickers de Snacks" },
	},
}
