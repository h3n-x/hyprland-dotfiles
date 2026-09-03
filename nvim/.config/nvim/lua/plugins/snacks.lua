-- snacks.nvim, configurado entero: dashboard, notificaciones,
-- indent guides, scroll suave, etc. Necesita cargar temprano (lazy=false),
-- lo pide el propio README del plugin.
return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		bigfile = { enabled = true },
		quickfile = { enabled = true },
		notifier = { enabled = true, timeout = 3000 },
		indent = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
		zen = { enabled = true },
		dashboard = { enabled = true },
	},
	-- notifier ya reemplaza vim.notify solo con enabled=true, no hace falta
	-- hacerlo a mano (ver docs/notifier.md, todos los ejemplos llaman
	-- vim.notify(...) directo).
	keys = {
		{ "<leader>z", function() Snacks.zen() end, desc = "Zen mode" },
		{ "<leader>N", function() Snacks.notifier.show_history() end, desc = "Historial de notificaciones" },
	},
}
