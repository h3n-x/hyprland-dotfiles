-- Renderiza markdown en el buffer (headers, code blocks, listas, etc.).
-- Solo aplica a buffers .md normales.
return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
	opts = {},
}
