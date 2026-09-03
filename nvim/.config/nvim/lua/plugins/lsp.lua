-- LSP: mason instala los servers, y desde Neovim 0.11+ vim.lsp.config()/
-- vim.lsp.enable() (nativos) reemplazan al viejo patron de
-- lspconfig[server].setup() -- mason-lspconfig v2 ya no usa `handlers`,
-- solo llama vim.lsp.enable() por vos. nvim-lspconfig sigue haciendo falta:
-- es el que trae las definiciones vim.lsp.config[...] de cientos de servers.
return {
	{
		"mason-org/mason.nvim",
		opts = { ui = { border = "rounded" } },
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		-- lazy = false (no event): dispara su instalacion via un autocmd de
		-- VimEnter registrado en su propio plugin/ -- si se carga lazy en un
		-- evento posterior (ej. BufReadPre), VimEnter ya paso y ese autocmd
		-- nunca llega a registrarse a tiempo.
		lazy = false,
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			-- Formatters de conform.nvim (editing.lua) via mason, para no
			-- depender de que esten instalados aparte por pacman.
			ensure_installed = { "stylua", "shfmt" },
		},
	},
	{ "neovim/nvim-lspconfig", event = { "BufReadPre", "BufNewFile" } },
	{
		"mason-org/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig", "saghen/blink.cmp" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			vim.lsp.config("*", { capabilities = capabilities })
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
					},
				},
			})

			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls", "bashls", "pyright", "jsonls", "yamlls", "marksman", "taplo",
				},
			})

			vim.diagnostic.config({
				virtual_text = { prefix = "●" },
				severity_sort = true,
				float = { border = "rounded" },
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(ev)
					local map = function(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
					end
					map("n", "gd", vim.lsp.buf.definition, "Ir a definicion")
					map("n", "gD", vim.lsp.buf.declaration, "Ir a declaracion")
					map("n", "gr", vim.lsp.buf.references, "Referencias")
					map("n", "gI", vim.lsp.buf.implementation, "Implementacion")
					map("n", "K", vim.lsp.buf.hover, "Hover")
					map("n", "<leader>rn", vim.lsp.buf.rename, "Renombrar")
					map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
					map("n", "<leader>e", vim.diagnostic.open_float, "Diagnostico (linea)")
					map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Diagnostico anterior")
					map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Diagnostico siguiente")
				end,
			})
		end,
	},
}
