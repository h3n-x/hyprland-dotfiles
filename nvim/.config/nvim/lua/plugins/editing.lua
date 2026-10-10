-- ============================================================================
-- Utilidades de edición y manipulación modal de texto
-- Delimitadores inteligentes, pares automáticos y objetos de texto ampliados
-- ============================================================================

return {
	-- Cierre automático de paréntesis, corchetes, comillas y bloques
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {
			check_ts = true,
			ts_config = {
				lua = { "string", "source" },
				javascript = { "string", "template_string" },
			},
			disable_filetype = { "TelescopePrompt", "snacks_picker_input" },
			fast_wrap = {
				map = "<M-e>",
				chars = { "{", "[", "(", '"', "'" },
				pattern = [=[[%'%"%)%>%]%)%}%,]]=],
				end_key = "$",
				keys = "qwertyuiopzxcvbnmasdfghjkl",
				check_comma = true,
				highlight = "Search",
				highlight_grey = "Comment",
			},
		},
	},

	-- Manipulación de delimitadores envolventes (cs"', ysiw), ds", etc.)
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		opts = {},
	},

	-- Objetos de texto extendidos: funciones va/if, clases va/ic, argumentos va/ia
	{
		"echasnovski/mini.ai",
		version = "*",
		event = "VeryLazy",
		opts = {
			n_lines = 500,
		},
	},
}
