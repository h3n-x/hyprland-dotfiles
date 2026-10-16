-- ============================================================================
-- Interfaz de Usuario (UI) reactiva al Theming Dinámico de Matugen
-- Lualine, Which-Key, Trouble, Dropbar, Todo-Comments y Dressing
-- Todos los componentes derivan sus estilos de la paleta base16 activa
-- ============================================================================

return {
	-- ---- Statusline adaptativa: Lualine ----
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "VeryLazy",
		config = function()
			local matugen = require("config.matugen")

			---Genera la tabla de tema de lualine a partir de la paleta activa de Matugen
			local function generate_lualine_theme()
				local c = matugen.get_colors()
				return {
					normal = {
						a = { bg = c.base0E, fg = c.base00, gui = "bold" },
						b = { bg = c.base02, fg = c.base05 },
						c = { bg = vim.g.transparent_background and "NONE" or c.base01, fg = c.base04 },
					},
					insert = {
						a = { bg = c.base0B, fg = c.base00, gui = "bold" },
						b = { bg = c.base02, fg = c.base05 },
						c = { bg = vim.g.transparent_background and "NONE" or c.base01, fg = c.base04 },
					},
					visual = {
						a = { bg = c.base09, fg = c.base00, gui = "bold" },
						b = { bg = c.base02, fg = c.base05 },
						c = { bg = vim.g.transparent_background and "NONE" or c.base01, fg = c.base04 },
					},
					replace = {
						a = { bg = c.base08, fg = c.base00, gui = "bold" },
						b = { bg = c.base02, fg = c.base05 },
						c = { bg = vim.g.transparent_background and "NONE" or c.base01, fg = c.base04 },
					},
					command = {
						a = { bg = c.base0D, fg = c.base00, gui = "bold" },
						b = { bg = c.base02, fg = c.base05 },
						c = { bg = vim.g.transparent_background and "NONE" or c.base01, fg = c.base04 },
					},
					inactive = {
						a = { bg = c.base01, fg = c.base04 },
						b = { bg = c.base01, fg = c.base04 },
						c = { bg = vim.g.transparent_background and "NONE" or c.base00, fg = c.base03 },
					},
				}
			end

			local function setup_lualine()
				local c = matugen.get_colors()
				require("lualine").setup({
					options = {
						theme = generate_lualine_theme(),
						component_separators = { left = "│", right = "│" },
						section_separators = { left = "", right = "" },
						globalstatus = true,
						disabled_filetypes = { statusline = { "snacks_dashboard", "alpha" } },
					},
					sections = {
						lualine_a = { { "mode", icon = "" } },
						lualine_b = {
							{ "branch", icon = "" },
							{
								"diff",
								symbols = { added = " ", modified = " ", removed = " " },
							},
							{
								"diagnostics",
								sources = { "nvim_diagnostic" },
								symbols = { error = " ", warn = " ", info = " ", hint = " " },
							},
						},
						lualine_c = {
							{ "filename", path = 1, file_status = true },
						},
						lualine_x = {
							{ "encoding" },
							{ "fileformat" },
							{ "filetype" },
						},
						lualine_y = { "progress" },
						lualine_z = { { "location", icon = "" } },
					},
				})
			end

			setup_lualine()

			-- Suscribirse al evento ColorScheme para refrescar Lualine automáticamente al recargar Matugen
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("LualineMatugenSync", { clear = true }),
				callback = function()
					setup_lualine()
				end,
			})
		end,
	},

	-- ---- Guía de atajos visual: Which-Key ----
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			spec = {
				{ "<leader>f", group = "Buscar (Find)" },
				{ "<leader>g", group = "Control de versiones (Git)" },
				{ "<leader>l", group = "LSP y Lenguajes" },
				{ "<leader>c", group = "Código y Refactor" },
				{ "<leader>d", group = "Depuración (DAP)" },
				{ "<leader>b", group = "Buffers" },
				{ "<leader>u", group = "UI e Interruptores (Toggles)" },
				{ "<leader>t", group = "Terminal y Pestañas" },
				{ "<leader>q", group = "Sesión y Salida" },
				{ "<leader>x", group = "Diagnósticos (Trouble)" },
				{ "<leader>s", group = "División de Ventanas (Splits)" },
				{ "<leader>h", group = "Git Hunks" },
			},
		},
	},

	-- ---- Dropbar: Breadcrumbs contextuales interactivos ----
	{
		"Bekaboo/dropbar.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			bar = {
				enable = function(buf, win)
					return not vim.api.nvim_win_get_config(win).zindex
						and vim.bo[buf].buftype == ""
						and vim.api.nvim_buf_get_name(buf) ~= ""
						and not vim.wo[win].diff
				end,
			},
		},
	},

	-- ---- Dressing: Diálogos modales flotantes para vim.ui.select e input ----
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
		opts = {
			input = {
				border = "rounded",
				win_options = { winblend = 0 },
			},
			select = {
				backend = { "builtin", "nui" },
				builtin = {
					border = "rounded",
					win_options = { winblend = 0 },
				},
			},
		},
	},

	-- ---- Trouble: Panel moderno de diagnósticos y referencias ----
	{
		"folke/trouble.nvim",
		cmd = { "Trouble" },
		opts = {
			modes = {
				preview_float = {
					mode = "diagnostics",
					preview = {
						type = "float",
						relative = "editor",
						border = "rounded",
						title = "Vista previa de diagnóstico",
						title_pos = "center",
						position = { 0, -2 },
						size = { width = 0.35, height = 0.35 },
						zindex = 200,
					},
				},
			},
		},
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnósticos del proyecto (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnósticos del buffer actual" },
			{ "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Símbolos del código (Trouble)" },
			{ "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "Definiciones / Referencias LSP" },
			{ "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
			{ "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
		},
	},

	-- ---- Todo-comments: Resaltado y búsqueda de TODO, FIXME, NOTE, BUG ----
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			signs = true,
			sign_priority = 8,
		},
		keys = {
			{ "]t", function() require("todo-comments").jump_next() end, desc = "Siguiente TODO" },
			{ "[t", function() require("todo-comments").jump_prev() end, desc = "Anterior TODO" },
			{ "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Panel de TODOs (Trouble)" },
			{ "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Buscar TODOs (Telescope)" },
		},
	},
}
