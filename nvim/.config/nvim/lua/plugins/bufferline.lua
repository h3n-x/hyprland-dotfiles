-- ============================================================================
-- Pestañas y Buffers superiores: akinsho/bufferline.nvim
-- Indicadores de diagnóstico, pestañas fijadas (pin) y compatibilidad con transparencia
-- ============================================================================

return {
	{
		"akinsho/bufferline.nvim",
		version = "*",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Buffer anterior" },
			{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Buffer siguiente" },
			{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Buffer anterior" },
			{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Buffer siguiente" },
			{ "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Fijar/Desfijar buffer (Pin)" },
			{ "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Cerrar buffers no fijados" },
			{ "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Cerrar los demás buffers" },
			{ "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "Cerrar buffers a la derecha" },
			{ "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "Cerrar buffers a la izquierda" },
		},
		opts = {
			options = {
				mode = "buffers",
				close_command = function(n)
					if Snacks and Snacks.bufdelete then
						Snacks.bufdelete(n)
					else
						vim.cmd("bdelete " .. n)
					end
				end,
				right_mouse_command = function(n)
					if Snacks and Snacks.bufdelete then
						Snacks.bufdelete(n)
					else
						vim.cmd("bdelete " .. n)
					end
				end,
				diagnostics = "nvim_lsp",
				always_show_bufferline = false,
				diagnostics_indicator = function(count, level)
					local icon = level:match("error") and " " or (level:match("warning") and " " or "ℹ ")
					return " " .. icon .. count
				end,
				offsets = {
					{
						filetype = "yazi",
						text = "Yazi File Manager",
						highlight = "Directory",
						text_align = "left",
					},
					{
						filetype = "snacks_layout_box",
						text = "Explorador",
						highlight = "Directory",
						text_align = "left",
					},
				},
				show_buffer_close_icons = false,
				show_close_icon = false,
				separator_style = "thin",
				color_icons = true,
				hover = {
					enabled = true,
					delay = 200,
					reveal = { "close" },
				},
			},
		},
	},
}
