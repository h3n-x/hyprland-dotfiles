-- ============================================================================
-- Servidor LSP: html (HTML Language Server)
-- ============================================================================

return {
	cmd = { "vscode-html-language-server", "--stdio" },
	filetypes = { "html", "templ" },
	root_markers = { { "package.json" }, { ".git" } },
	settings = {
		html = {
			format = { enable = true },
			hover = { documentation = true },
		},
	},
}
