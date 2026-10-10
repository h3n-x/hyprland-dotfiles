-- ============================================================================
-- Sintaxis y Árbol de Parseo: Treesitter (Rama 'main' para Neovim 0.12+)
-- Utiliza el motor nativo vim.treesitter.start() para resaltado en tiempo real
-- y nvim-treesitter-textobjects para selección semántica avanzada.
-- ============================================================================

return {
	-- Parser y analizador sintáctico principal
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = function()
			local parsers = {
				"lua", "vim", "vimdoc", "bash", "python", "rust", "go",
				"gomod", "gowork", "c", "cpp", "javascript", "typescript",
				"tsx", "html", "css", "json", "yaml", "toml", "markdown",
				"markdown_inline", "dockerfile", "regex", "query",
			}
			pcall(require("nvim-treesitter").install, parsers)
		end,
		config = function()
			-- Filetypes para inicio automático de resaltado sintáctico con Neovim nativo
			local filetypes = {
				"lua",
				"vim",
				"help",
				"sh",
				"bash",
				"zsh",
				"python",
				"rust",
				"go",
				"gomod",
				"c",
				"cpp",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"html",
				"css",
				"json",
				"yaml",
				"toml",
				"markdown",
				"dockerfile",
				"query",
			}

			vim.api.nvim_create_autocmd("FileType", {
				pattern = filetypes,
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
		end,
	},

	-- Objetos de texto basados en árboles sintácticos (funciones, clases, etc.)
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},

	-- Sticky Context: Mantiene visible la cabecera de la función/bloque al desplazarse
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			max_lines = 3,
			trim_scope = "outer",
			mode = "cursor",
		},
		keys = {
			{
				"[c",
				function()
					require("treesitter-context").go_to_context(vim.v.count1)
				end,
				desc = "Saltar al inicio del contexto actual (Treesitter)",
			},
		},
	},
}
