-- ============================================================================
-- Fuzzy Finder: nvim-telescope/telescope.nvim + fzf-native
-- Búsqueda de archivos, texto, símbolos LSP, historial Git y buffers
-- Estilo visual adaptado a bordes redondeados y herencia del tema base16
-- ============================================================================

return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	cmd = "Telescope",
	keys = {
		-- Búsqueda general
		{ "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Buscar archivos del proyecto" },
		{ "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Buscar texto en proyecto (Live Grep)" },
		{ "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buscar buffers activos" },
		{ "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Archivos abiertos recientemente" },
		{ "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Buscar en páginas de ayuda" },
		{ "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "Buscar atajos de teclado (Keymaps)" },
		{ "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Buscar diagnósticos del proyecto" },
		-- Símbolos de código y LSP
		{ "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Símbolos del buffer actual" },
		{ "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<CR>", desc = "Símbolos del workspace" },
		-- Git
		{ "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Historial de commits de Git" },
		{ "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Estado de cambios Git (Status)" },
		-- Buffer local
		{ "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Buscar en buffer actual" },
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				prompt_prefix = "   ",
				selection_caret = " ❯ ",
				entry_prefix = "   ",
				border = true,
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						prompt_position = "top",
						preview_width = 0.55,
					},
					width = 0.88,
					height = 0.85,
				},
				sorting_strategy = "ascending",
				mappings = {
					i = {
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
						["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
						["<Esc>"] = actions.close,
					},
					n = {
						["q"] = actions.close,
					},
				},
			},
			pickers = {
				find_files = {
					hidden = true,
					find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden", "--exclude", ".git" },
				},
			},
		})

		pcall(telescope.load_extension, "fzf")
	end,
}
