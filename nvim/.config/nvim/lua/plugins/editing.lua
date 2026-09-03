return {
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = "ConformInfo",
		keys = {
			{
				"<leader>cf",
				function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
				desc = "Formatear buffer",
			},
		},
		opts = {
			-- stylua/shfmt via mason (mason-tool-installer, lsp.lua). jq ya
			-- esta instalado via pacman (README). Otros formatters (prettier,
			-- ruff, etc.) se pueden sumar aca el dia que hagan falta.
			formatters_by_ft = {
				lua = { "stylua" },
				sh = { "shfmt" },
				json = { "jq" },
			},
			format_on_save = { timeout_ms = 2000, lsp_format = "fallback" },
		},
	},
}
