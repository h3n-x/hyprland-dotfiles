-- persistence.nvim -- restauración automatizada de buffers, tabs, cursores y splits
return {
	"folke/persistence.nvim",
	event = "BufReadPre",
	opts = {
		need = 1,
		branch = true,
	},
	keys = {
		{
			"<leader>qs",
			function()
				require("persistence").load()
			end,
			desc = "Restaurar sesión del proyecto",
		},
		{
			"<leader>qS",
			function()
				require("persistence").select()
			end,
			desc = "Seleccionar sesión guardada",
		},
		{
			"<leader>ql",
			function()
				require("persistence").load({ last = true })
			end,
			desc = "Restaurar última sesión",
		},
		{
			"<leader>qd",
			function()
				require("persistence").stop()
			end,
			desc = "No guardar sesión al salir",
		},
	},
}
