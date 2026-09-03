-- ============================================================================
-- lazy.nvim -- bootstrap + carga de lua/plugins/*.lua
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
			{ "Fallo al clonar lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPresiona cualquier tecla para salir..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = { { import = "plugins" } },
	install = { colorscheme = { "default" } },
	checker = { enabled = true, notify = false },
	change_detection = { notify = false },
	ui = { border = "rounded" },
})
