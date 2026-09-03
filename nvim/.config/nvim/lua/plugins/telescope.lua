return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	cmd = "Telescope",
	keys = {
		{ "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Buscar archivos" },
		{ "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Buscar en contenido (grep)" },
		{ "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buscar buffers" },
		{ "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Buscar en ayuda" },
		{ "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Archivos recientes" },
		{ "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnosticos" },
		{ "<leader>fc", "<cmd>Telescope git_commits<CR>", desc = "Commits de git" },
	},
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			defaults = {
				border = true,
				layout_strategy = "horizontal",
				layout_config = { prompt_position = "top" },
				sorting_strategy = "ascending",
			},
		})
		pcall(telescope.load_extension, "fzf")
	end,
}
