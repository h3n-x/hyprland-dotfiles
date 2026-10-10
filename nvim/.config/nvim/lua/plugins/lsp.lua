-- ============================================================================
-- LSP Nativo Moderno (Neovim 0.12+)
-- Exclusivamente vía vim.lsp.config() y vim.lsp.enable()
-- Mason se encarga exclusivamente de la instalación automática de binarios
-- Las configuraciones específicas residen en lsp/<server>.lua
-- ============================================================================

return {
	-- Gestor de ejecutables LSP, DAP, linters y formatters
	{
		"mason-org/mason.nvim",
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<CR>", desc = "Panel de Mason" } },
		opts = {
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},

	-- Instalador desatendido de herramientas complementarias
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		lazy = false,
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				-- Formateadores
				"stylua",
				"shfmt",
				"prettier",
				"ruff",
				"clang-format",
				-- Linters
				"shellcheck",
				"markdownlint",
				-- DAP (Debuggers)
				"debugpy",
				"delve",
				"codelldb",
			},
			auto_update = false,
			run_on_start = true,
		},
	},

	-- nvim-lspconfig: Provee metadatos y schemas globales
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"saghen/blink.cmp",
		},
		config = function()
			-- Servidores soportados para desarrollo integral
			local servers = {
				"lua_ls",
				"pyright",
				"ts_ls",
				"rust_analyzer",
				"gopls",
				"clangd",
				"bashls",
				"jsonls",
				"yamlls",
				"html",
				"cssls",
				"marksman",
				"dockerls",
			}

			-- Sincronizar instalación con mason-lspconfig
			require("mason-lspconfig").setup({
				ensure_installed = servers,
				automatic_installation = true,
			})

			-- Inyectar capabilities avanzadas de autocompletado (blink.cmp)
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local blink_ok, blink = pcall(require, "blink.cmp")
			if blink_ok and blink.get_lsp_capabilities then
				capabilities = blink.get_lsp_capabilities(capabilities)
			end

			-- Configuración global aplicable a todos los servidores LSP nativos
			vim.lsp.config("*", {
				capabilities = capabilities,
			})

			-- Habilitar todos los servidores de forma 100% nativa con la API de Neovim 0.12
			-- Neovim carga automáticamente las opciones de runtimepath lsp/<server>.lua
			vim.lsp.enable(servers)

			-- ---- Configuración visual de diagnósticos ----
			vim.diagnostic.config({
				severity_sort = true,
				virtual_text = {
					prefix = "●",
					spacing = 4,
				},
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.HINT] = " ",
						[vim.diagnostic.severity.INFO] = " ",
					},
				},
				float = {
					border = "rounded",
					source = "always",
					header = "",
					prefix = "",
				},
				underline = true,
				update_in_insert = false,
			})

			-- ---- Autocomando al asociar un cliente LSP a un buffer (LspAttach) ----
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("DotfilesLspConfig", { clear = true }),
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					local bufnr = event.buf

					local map = function(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "LSP: " .. desc })
					end

					-- Navegación e inspección de código
					map("n", "gd", vim.lsp.buf.definition, "Ir a definición")
					map("n", "gD", vim.lsp.buf.declaration, "Ir a declaración")
					map("n", "gr", vim.lsp.buf.references, "Ver referencias")
					map("n", "gI", vim.lsp.buf.implementation, "Ir a implementación")
					map("n", "gy", vim.lsp.buf.type_definition, "Ir a definición de tipo")
					map("n", "K", vim.lsp.buf.hover, "Documentación flotante (Hover)")
					map({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, "Firma de función (Signature Help)")

					-- Acciones y refactorización
					map("n", "<leader>cr", vim.lsp.buf.rename, "Renombrar símbolo")
					map("n", "<leader>rn", vim.lsp.buf.rename, "Renombrar símbolo")
					map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Acción de código (Code Action)")

					-- Diagnósticos de buffer
					map("n", "<leader>cd", vim.diagnostic.open_float, "Diagnóstico de la línea")
					map("n", "[d", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, "Diagnóstico anterior")
					map("n", "]d", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, "Diagnóstico siguiente")

					-- Inlay hints (pistas de tipo y argumentos inline)
					if client and client:supports_method("textDocument/inlayHint") then
						-- Activación automática
						vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

						-- Toggle manual de Inlay Hints
						map("n", "<leader>uh", function()
							local is_enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
							vim.lsp.inlay_hint.enable(not is_enabled, { bufnr = bufnr })
							vim.notify(
								"Inlay hints " .. (not is_enabled and "activados" or "desactivados"),
								vim.log.levels.INFO,
								{ title = "LSP Inlay Hints" }
							)
						end, "Alternar Inlay Hints")
					end
				end,
			})
		end,
	},
}
