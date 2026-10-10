-- ============================================================================
-- Servidor LSP: lua_ls (Lua Language Server)
-- ============================================================================

return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { { ".luarc.json", ".luarc.jsonc" }, { ".git" } },
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = {
				globals = { "vim", "Snacks" },
			},
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
					"${3rd}/luv/library",
				},
			},
			completion = {
				callSnippet = "Replace",
			},
			telemetry = { enable = false },
			hint = {
				enable = true,
				arrayIndex = "Disable",
			},
		},
	},
}
