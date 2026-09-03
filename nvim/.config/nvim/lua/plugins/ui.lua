return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "VeryLazy",
		config = function()
			local ok, c = pcall(require, "matugen_colors")
			if not ok then
				c = {
					base00 = "1e1e2e", base01 = "181825", base02 = "313244",
					base04 = "a6adc8", base05 = "cdd6f4", base0D = "89b4fa",
					base0E = "cba6f7", base08 = "f38ba8",
				}
			end
			for k, v in pairs(c) do
				c[k] = "#" .. v
			end

			local theme = {
				normal = {
					a = { bg = c.base0E, fg = c.base00, gui = "bold" },
					b = { bg = c.base02, fg = c.base05 },
					c = { bg = c.base01, fg = c.base04 },
				},
				insert = { a = { bg = c.base0D, fg = c.base00, gui = "bold" } },
				visual = { a = { bg = c.base0A or c.base0C, fg = c.base00, gui = "bold" } },
				replace = { a = { bg = c.base08, fg = c.base00, gui = "bold" } },
				inactive = {
					a = { bg = c.base01, fg = c.base04 },
					b = { bg = c.base01, fg = c.base04 },
					c = { bg = c.base01, fg = c.base04 },
				},
			}

			require("lualine").setup({
				options = {
					theme = theme,
					component_separators = { left = "│", right = "│" },
					section_separators = { left = "", right = "" },
					globalstatus = true,
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { { "filename", path = 1 } },
					lualine_x = { "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
			})
		end,
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = { preset = "modern" },
	},
}
