-- Yazi como explorador de archivos -- reusa el yazi ya themeado con matugen
-- (ver ../../../yazi/.config/yazi/) en vez de un arbol de archivos aparte.
return {
	"mikavilpas/yazi.nvim",
	version = "*",
	event = "VeryLazy",
	dependencies = {
		{ "nvim-lua/plenary.nvim", lazy = true },
	},
	keys = {
		{ "<leader>-", mode = { "n", "v" }, "<cmd>Yazi<CR>", desc = "Yazi (archivo actual)" },
		{ "<leader>cw", "<cmd>Yazi cwd<CR>", desc = "Yazi (directorio de trabajo)" },
		{ "<C-Up>", "<cmd>Yazi toggle<CR>", desc = "Retomar ultima sesion de yazi" },
	},
	opts = {
		open_for_directories = true,
		keymaps = { show_help = "<f1>" },
	},
	init = function()
		vim.g.loaded_netrwPlugin = 1
	end,
}
