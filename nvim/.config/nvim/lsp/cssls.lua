-- ============================================================================
-- Servidor LSP: cssls (CSS / SCSS / LESS Language Server)
-- ============================================================================

return {
	cmd = { "vscode-css-language-server", "--stdio" },
	filetypes = { "css", "scss", "less" },
	root_markers = { { "package.json" }, { ".git" } },
	settings = {
		css = { validate = true },
		less = { validate = true },
		scss = { validate = true },
	},
}
