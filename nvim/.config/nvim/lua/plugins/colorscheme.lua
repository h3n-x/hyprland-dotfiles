-- Colorscheme dinamico: base16.nvim + paleta generada por matugen
-- (../../matugen_colors.lua, ver ../../../../matugen/.config/matugen/templates/nvim-colors.lua)
return {
	"RRethy/base16-nvim",
	lazy = false,
	priority = 1000,
	config = function()
		local ok, colors = pcall(require, "matugen_colors")
		if not ok then
			-- Fallback si todavia no se corrio matugen una vez (paleta Catppuccin
			-- Mocha, mismos defaults que el resto del rice antes de matugen)
			colors = {
				base00 = "1e1e2e",
				base01 = "181825",
				base02 = "313244",
				base03 = "45475a",
				base04 = "a6adc8",
				base05 = "cdd6f4",
				base06 = "cdd6f4",
				base07 = "b4befe",
				base08 = "f38ba8",
				base09 = "fab387",
				base0A = "f9e2af",
				base0B = "a6e3a1",
				base0C = "94e2d5",
				base0D = "89b4fa",
				base0E = "cba6f7",
				base0F = "f2cdcd",
			}
		end

		local prefixed = {}
		for k, v in pairs(colors) do
			prefixed[k] = "#" .. v
		end

		require("base16-colorscheme").setup(prefixed)
	end,
}
