-- ============================================================================
-- Git: gitsigns.nvim, Lazygit y Diffview
-- Resaltado en margen, gestión de hunks, blame en línea y visor de diferencias
-- Los colores se heredan automáticamente de los grupos GitSigns* de base16
-- ============================================================================

return {
	-- Indicadores visuales en la columna de signos e inspección rápida de hunks
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},
			current_line_blame = false, -- Se activa a demanda con <leader>gb
			current_line_blame_opts = {
				delay = 300,
				virt_text_pos = "eol",
			},
			on_attach = function(bufnr)
				local gs = require("gitsigns")
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Git: " .. desc })
				end

				-- Navegación de hunks
				map("n", "]h", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, "Siguiente hunk modificado")

				map("n", "[h", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, "Hunk anterior modificado")

				-- Acciones de Hunk y Buffer
				map("n", "<leader>hs", gs.stage_hunk, "Stage hunk actual")
				map("n", "<leader>hr", gs.reset_hunk, "Restaurar (reset) hunk actual")
				map("v", "<leader>hs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Stage selección actual")
				map("v", "<leader>hr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Restaurar selección actual")
				map("n", "<leader>hS", gs.stage_buffer, "Stage buffer completo")
				map("n", "<leader>hR", gs.reset_buffer, "Restaurar buffer completo")
				map("n", "<leader>hp", gs.preview_hunk, "Vista previa del hunk flotante")
				map("n", "<leader>gb", gs.blame_line, "Ver Git Blame de la línea actual")
				map("n", "<leader>ub", gs.toggle_current_line_blame, "Alternar Blame inline continuo")
				map("n", "<leader>hd", gs.diffthis, "Diff respecto al índice")
			end,
		},
	},

	-- Comparador visual side-by-side de ramas, commits y resolución de conflictos
	{
		"sindrets/diffview.nvim",
		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewToggleFiles",
			"DiffviewFocusFiles",
			"DiffviewFileHistory",
		},
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Abrir comparador Git (Diffview)" },
			{ "<leader>gD", "<cmd>DiffviewClose<CR>", desc = "Cerrar comparador Git (Diffview)" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "Historial Git del archivo actual" },
			{ "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Historial Git de todo el proyecto" },
		},
		opts = {
			enhanced_diff_hl = true,
			view = {
				default = {
					layout = "diff2_horizontal",
				},
			},
		},
	},

	-- Lazygit integrado en ventana flotante
	{
		"folke/snacks.nvim",
		keys = {
			{
				"<leader>gg",
				function()
					Snacks.lazygit()
				end,
				desc = "Abrir Lazygit (Terminal Flotante)",
			},
		},
	},
}
