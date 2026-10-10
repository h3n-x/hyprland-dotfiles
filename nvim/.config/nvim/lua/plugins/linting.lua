-- ============================================================================
-- Linting asíncrono: mfussenegger/nvim-lint
-- Ejecuta analizadores estáticos de código en segundo plano complementando a LSP
-- ============================================================================

return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost", "InsertLeave" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				markdown = { "markdownlint" },
			}

			local lint_augroup = vim.api.nvim_create_augroup("DotfilesLint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					-- Solo ejecutar si el buffer tiene un archivo real en disco
					if vim.opt_local.buftype:get() == "" then
						lint.try_lint()
					end
				end,
			})
		end,
	},
}
