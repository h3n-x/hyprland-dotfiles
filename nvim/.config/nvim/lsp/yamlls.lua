-- ============================================================================
-- Servidor LSP: yamlls (YAML Language Server)
-- ============================================================================

return {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
	root_markers = { { ".git" } },
	settings = {
		yaml = {
			schemaStore = {
				enable = true,
				url = "https://www.schemastore.org/api/json/catalog.json",
			},
			format = { enable = true },
			validate = true,
		},
	},
}
