-- ============================================================================
-- lazy.nvim -- Gestor moderno de plugins para Neovim
-- Bootstrap automático, carga diferida (lazy loading) e imports modulares
--
-- NOTA TÉCNICA (Neovim 0.12+):
-- Neovim 0.12 introduce experimentalmente `vim.pack` (gestión declarativa
-- nativa de paquetes sin dependencias de terceros). Sin embargo, `lazy.nvim`
-- se mantiene como la solución de producción estándar gracias a su avanzado
-- ecosistema de resolución de dependencias, bloqueo reproducible vía
-- `lazy-lock.json`, compilación de bytecode y profiling milimétrico.
-- ============================================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local out = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Error crítico al clonar lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPresiona cualquier tecla para continuar..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	defaults = {
		lazy = true, -- Lazy loading por defecto en todas las especificaciones
		version = false, -- Usar última versión de git por defecto
	},
	install = {
		colorscheme = { "base16-default-dark", "default" },
	},
	checker = {
		enabled = false, -- Evitar chequeos de red innecesarios al iniciar
		notify = false,
	},
	change_detection = {
		enabled = true,
		notify = false,
	},
	rocks = {
		enabled = false,
	},
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
				"netrwPlugin",
			},
		},
	},
	ui = {
		border = "rounded",
	},
})
