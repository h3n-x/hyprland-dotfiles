-- Bytecode compilation cache (Neovim 0.10+): acelera el arranque un 30-50%
if vim.loader then
	vim.loader.enable()
end

-- ============================================================================
-- Neovim -- entry point. Estructura modular, mismo criterio que
-- hypr/.config/hypr/modules/ en el resto de este dotfiles.
-- ============================================================================

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
