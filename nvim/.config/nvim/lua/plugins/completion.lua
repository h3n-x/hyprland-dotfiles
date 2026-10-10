-- ============================================================================
-- Autocompletado de alto rendimiento: saghen/blink.cmp + LuaSnip
--
-- NOTA DE ARQUITECTURA (Neovim 0.12+):
-- Neovim 0.12 incorpora completado nativo mediante las opciones `vim.o.autocomplete`
-- y la ampliación de `completeopt` (capaz de resolver LSP nativamente sin plugins).
-- No obstante, `saghen/blink.cmp` es el estándar actual de producción por su motor
-- de búsqueda difusa escrito en Rust (o C precompilado), latencias inferiores a 2ms,
-- renderizado de snippets asíncrono y soporte multi-fuente unificado.
--
-- HERENCIA DE HIGHLIGHTS MATUGEN:
-- No se especifica ningún tema de color hardcodeado para blink.cmp. La interfaz
-- de completado hereda directamente los grupos estándar de Neovim (`NormalFloat`,
-- `FloatBorder`, `Pmenu`, `PmenuSel`, `CmpItemKind*`), asegurando coherencia
-- visual absoluta con la paleta dinámica base16 de Matugen.
-- ============================================================================

return {
	-- Motor de snippets LuaSnip + colección comunitaria friendly-snippets
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},

	-- Motor principal de autocompletado blink.cmp
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = {
			"L3MON4D3/LuaSnip",
			"rafamadriz/friendly-snippets",
		},
		opts = {
			keymap = {
				preset = "default",
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide", "fallback" },
				["<CR>"] = { "accept", "fallback" },
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
			},

			appearance = {
				nerd_font_variant = "mono",
				use_nvim_cmp_as_default = false,
			},

			snippets = {
				preset = "luasnip",
			},

			completion = {
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
					window = {
						border = "rounded",
						winblend = 0,
					},
				},
				menu = {
					border = "rounded",
					winblend = 0,
					draw = {
						treesitter = { "lsp" },
						columns = {
							{ "kind_icon" },
							{ "label", "label_description", gap = 1 },
							{ "source_name" },
						},
					},
				},
			},

			signature = {
				enabled = true,
				window = {
					border = "rounded",
					winblend = 0,
				},
			},

			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},

			fuzzy = {
				implementation = "prefer_rust_with_warning",
			},
		},
		opts_extend = { "sources.default" },
	},
}
