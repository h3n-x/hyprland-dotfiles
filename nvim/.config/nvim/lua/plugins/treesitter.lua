-- nvim-treesitter -- branch "main", NO "master": master esta congelada y
-- documentada como incompatible con Neovim 0.12 (la instalada aca). main
-- reescribio toda la API: no hay mas require("nvim-treesitter.configs")
-- ni el sistema de "modules" (incluido incremental_selection, que existia
-- en la config vieja y no tiene equivalente directo todavia).
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		-- "jsonc" no es un parser separado en esta branch (main), json ya
		-- cubre los .jsonc via el propio filetype/injection.
		local parsers = {
			"lua", "vim", "vimdoc", "bash", "python", "json", "yaml",
			"toml", "markdown", "markdown_inline", "regex", "query",
		}
		require("nvim-treesitter").install(parsers)

		-- Nombres de filetype reales de vim, no siempre coinciden con el
		-- nombre del parser (ej. parser "vimdoc" -> filetype "help").
		local filetypes = {
			"lua", "vim", "help", "sh", "python", "json", "yaml",
			"toml", "markdown",
		}
		vim.api.nvim_create_autocmd("FileType", {
			pattern = filetypes,
			callback = function() vim.treesitter.start() end,
		})
	end,
}
