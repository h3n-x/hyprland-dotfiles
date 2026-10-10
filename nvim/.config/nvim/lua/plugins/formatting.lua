-- ============================================================================
-- Formateo automático de código: stevearc/conform.nvim
-- Formateadores ultra rápidos para Rust, Go, Python, TypeScript, Lua, C/C++, Bash
-- Incluye comando :FormatToggle y fallback transparente a LSP
-- ============================================================================

return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo", "Format", "FormatToggle" },
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				desc = "Formatear buffer actual (Conform)",
			},
			{
				"<leader>uf",
				function()
					vim.cmd("FormatToggle")
				end,
				desc = "Alternar formateo automático al guardar",
			},
		},
		opts = function()
			-- Variable global para controlar si el formateo automático está activo
			vim.g.autoformat = true

			-- Comando para alternar formateo automático al guardar
			vim.api.nvim_create_user_command("FormatToggle", function()
				vim.g.autoformat = not vim.g.autoformat
				local state = vim.g.autoformat and "activado" or "desactivado"
				vim.notify("Formateo automático al guardar: " .. state, vim.log.levels.INFO, {
					title = "Conform",
					icon = "󰉢",
				})
			end, { desc = "Alternar formateo automático al guardar" })

			-- Comando explícito :Format
			vim.api.nvim_create_user_command("Format", function(args)
				local range = nil
				if args.count ~= -1 then
					local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
					range = {
						start = { args.line1, 0 },
						["end"] = { args.line2, end_line and end_line:len() or 0 },
					}
				end
				require("conform").format({ async = true, lsp_format = "fallback", range = range })
			end, { range = true, desc = "Formatear buffer o selección" })

			return {
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "ruff_format", "ruff_fix" },
					rust = { "rustfmt" },
					go = { "gofmt", "goimports" },
					c = { "clang-format" },
					cpp = { "clang-format" },
					sh = { "shfmt" },
					bash = { "shfmt" },
					zsh = { "shfmt" },
					javascript = { "prettierd", "prettier", stop_after_first = true },
					typescript = { "prettierd", "prettier", stop_after_first = true },
					javascriptreact = { "prettierd", "prettier", stop_after_first = true },
					typescriptreact = { "prettierd", "prettier", stop_after_first = true },
					json = { "prettierd", "prettier", stop_after_first = true },
					jsonc = { "prettierd", "prettier", stop_after_first = true },
					yaml = { "prettierd", "prettier", stop_after_first = true },
					markdown = { "prettierd", "prettier", stop_after_first = true },
					html = { "prettierd", "prettier", stop_after_first = true },
					css = { "prettierd", "prettier", stop_after_first = true },
					scss = { "prettierd", "prettier", stop_after_first = true },
				},
				format_on_save = function(bufnr)
					-- Respetar bandera global y evitar formatear si está deshabilitado
					if not vim.g.autoformat or vim.b[bufnr].disable_autoformat then
						return nil
					end
					return {
						timeout_ms = 2500,
						lsp_format = "fallback",
					}
				end,
			}
		end,
	},
}
