-- ============================================================================
-- Servidor LSP: rust_analyzer (Rust Language Server)
-- ============================================================================

return {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	root_markers = { { "Cargo.toml", "rust-project.json" }, { ".git" } },
	settings = {
		["rust-analyzer"] = {
			cargo = {
				allFeatures = true,
				loadOutDirsFromCheck = true,
				runBuildScripts = true,
			},
			checkOnSave = {
				command = "clippy",
			},
			procMacro = {
				enable = true,
			},
			inlayHints = {
				lifetimeElisionHints = { enable = "skip_trivial" },
				typeHints = { enable = true },
				chainingHints = { enable = true },
				parameterHints = { enable = true },
			},
		},
	},
}
