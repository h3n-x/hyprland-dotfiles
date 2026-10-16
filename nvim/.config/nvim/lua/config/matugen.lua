-- ============================================================================
-- Módulo de Theming Dinámico: Matugen Material You -> Neovim (base16-nvim)
-- Soporta recarga reactiva sin reiniciar Neovim vía :MatugenReload,
-- file-watcher nativo con vim.uv.fs_event() y sockets RPC remotos.
-- ============================================================================

local M = {}

-- Paleta fallback (Catppuccin Mocha) en caso de que matugen_colors.lua aún no exista
M.fallback_colors = {
	base00 = "1e1e2e", -- Fondo principal
	base01 = "181825", -- Superficie baja
	base02 = "313244", -- Superficie alta / Selección
	base03 = "45475a", -- Comentarios / Delimitadores tenues
	base04 = "a6adc8", -- Texto secundario / On-surface variant
	base05 = "cdd6f4", -- Texto principal / On-surface
	base06 = "cdd6f4", -- Texto brillante
	base07 = "b4befe", -- Superficie clara / Acentos
	base08 = "f38ba8", -- Error / Rojo (Material You Error)
	base09 = "fab387", -- Naranja / Alerta (Tertiary Container)
	base0A = "f9e2af", -- Amarillo / Warning (Secondary Container)
	base0B = "a6e3a1", -- Verde / Éxito (Tertiary)
	base0C = "94e2d5", -- Cian / Info
	base0D = "89b4fa", -- Azul / Secundario (Secondary)
	base0E = "cba6f7", -- Morado / Acento principal (Primary)
	base0F = "f2cdcd", -- Marrón / Acento tenue (Outline)
}

---Obtiene la tabla de colores actual agregando el prefijo '#' requerido por base16-nvim.
---@return table<string, string> Tabla con claves base00..base0F y valores hexadecimales con '#'
function M.get_colors()
	-- Forzar re-lectura limpiando la caché de módulos de Lua
	package.loaded["matugen_colors"] = nil

	local ok, raw_colors = pcall(require, "matugen_colors")
	if not ok or type(raw_colors) ~= "table" then
		raw_colors = M.fallback_colors
	end

	local prefixed = {}
	for k, v in pairs(raw_colors) do
		if type(v) == "string" then
			prefixed[k] = v:sub(1, 1) == "#" and v or ("#" .. v)
		end
	end

	-- Tabla "semantic" (Fase 18): colores de estado y estilos, fuera de base16
	return prefixed, raw_colors.semantic
end

-- Grupos con significado (principio 23): siempre los colores de estado, nunca la sintaxis
local STATUS_GROUPS = {
	error = { "DiagnosticError", "DiagnosticSignError", "DiagnosticFloatingError", "DiagnosticVirtualTextError",
		"ErrorMsg", "DiffDelete", "Removed", "@diff.minus", "GitSignsDelete", "diffRemoved" },
	warning = { "DiagnosticWarn", "DiagnosticSignWarn", "DiagnosticFloatingWarn", "DiagnosticVirtualTextWarn",
		"WarningMsg", "DiffChange", "Changed", "@diff.delta", "GitSignsChange", "diffChanged" },
	success = { "DiagnosticOk", "DiagnosticSignOk", "DiffAdd", "Added", "@diff.plus", "GitSignsAdd", "diffAdded" },
}
local UNDERLINES = { error = "DiagnosticUnderlineError", warning = "DiagnosticUnderlineWarn", success = "DiagnosticUnderlineOk" }
-- Estilos de las opciones (appearance.code.style.*)
local STYLE_GROUPS = {
	comment = { "Comment", "@comment", "SpecialComment" },
	keyword = { "Keyword", "Statement", "Conditional", "Repeat", "@keyword", "@keyword.function", "@keyword.return" },
	type = { "Type", "@type", "@type.builtin", "StorageClass", "Structure" },
}

---Pone los colores de estado y los estilos encima de base16 (Fase 18)
---@param semantic? table { error, warning, success, styles = { comment, keyword, type } }
function M.apply_semantic(semantic)
	if type(semantic) ~= "table" then
		return
	end
	for state, groups in pairs(STATUS_GROUPS) do
		local color = semantic[state]
		if color then
			for _, g in ipairs(groups) do
				local hl = vim.api.nvim_get_hl(0, { name = g, link = false })
				-- Los diff de fondo (DiffAdd...) conservan su fondo y toman el color de estado como texto
				hl.fg = color
				hl.link = nil
				vim.api.nvim_set_hl(0, g, hl)
			end
			vim.api.nvim_set_hl(0, UNDERLINES[state], { undercurl = true, sp = color })
		end
	end
	for role, groups in pairs(STYLE_GROUPS) do
		local style = semantic.styles and semantic.styles[role]
		if style then
			for _, g in ipairs(groups) do
				local hl = vim.api.nvim_get_hl(0, { name = g, link = false })
				hl.link = nil
				hl.italic = style == "italic"
				hl.bold = style == "bold"
				vim.api.nvim_set_hl(0, g, hl)
			end
		end
	end
end

---Aplica transparencia de fondo para integrarse armónicamente con Hyprland y kitty
function M.apply_transparency()
	if not vim.g.transparent_background then
		return
	end

	local transparent_groups = {
		"Normal",
		"NormalFloat",
		"NormalNC",
		"FloatBorder",
		"SignColumn",
		"EndOfBuffer",
		"FoldColumn",
		"Folded",
		"StatusLine",
		"StatusLineNC",
		"LineNr",
		"CursorLineNr",
		"WhichKeyFloat",
		"TelescopeNormal",
		"TelescopeBorder",
		"TelescopePromptNormal",
		"TelescopePromptBorder",
		"TelescopeResultsNormal",
		"TelescopeResultsBorder",
		"TelescopePreviewNormal",
		"TelescopePreviewBorder",
		"SnacksNormal",
		"SnacksBackdrop",
		"SnacksPickerNormal",
		"SnacksPickerBorder",
		"DressingInput",
		"TroubleNormal",
		"TroubleNormalNC",
	}

	for _, group in ipairs(transparent_groups) do
		vim.api.nvim_set_hl(0, group, { bg = "none", ctermbg = "none" })
	end
end

---Recarga la paleta completa de colores dinámicos y repinta la interfaz entera.
---@param silent? boolean Si es true, no muestra notificación flotante al recargar
function M.reload(silent)
	local colors, semantic = M.get_colors()

	local ok_base16, base16 = pcall(require, "base16-colorscheme")
	if ok_base16 and base16 and base16.setup then
		base16.setup(colors)
	end
	M.apply_semantic(semantic)

	-- Aplicar transparencia si el usuario la tiene activada
	M.apply_transparency()

	-- Disparar ColorScheme para que todos los plugins (lualine, bufferline,
	-- snacks, trouble, telescope, dap-ui, etc.) repinten sus estilos
	vim.cmd("doautocmd ColorScheme")

	-- Notificar discretamente si el editor ya está cargado y no está en modo silencioso
	if not silent and vim.v.vim_did_enter == 1 then
		vim.notify("Paleta de colores Matugen actualizada", vim.log.levels.INFO, {
			title = "Theming Dinámico",
			icon = "󰏘",
			timeout = 2000,
		})
	end
end

-- Handle persistente para el file watcher de libuv
local fs_event_handle = nil
local debounce_timer = nil

---Inicia el file watcher nativo con vim.uv.fs_event() sobre matugen_colors.lua
function M.setup_watcher()
	if fs_event_handle then
		return
	end

	local colors_file = vim.fn.stdpath("config") .. "/lua/matugen_colors.lua"
	local real_path = vim.uv.fs_realpath(colors_file) or colors_file
	local watch_dir = vim.fs.dirname(real_path)

	local fs_event, err = vim.uv.new_fs_event()
	if not fs_event then
		vim.notify("No se pudo inicializar fs_event de libuv: " .. tostring(err), vim.log.levels.WARN)
		return
	end

	debounce_timer = vim.uv.new_timer()

	-- Observamos el directorio contenedor para capturar eventos atómicos de escritura/renombrado
	local start_res, start_err = fs_event:start(watch_dir, {}, function(event_err, filename, events)
		if event_err then
			return
		end

		if filename and filename:match("matugen_colors%.lua$") then
			if debounce_timer then
				debounce_timer:stop()
				debounce_timer:start(100, 0, function()
					vim.schedule(function()
						M.reload(false)
					end)
				end)
			end
		end
	end)

	if start_res == 0 then
		fs_event_handle = fs_event
	else
		if start_err then
			vim.notify("Error al iniciar fs_event watcher en " .. watch_dir .. ": " .. tostring(start_err), vim.log.levels.DEBUG)
		end
	end
end

---Inicializa el sistema de theming matugen, comandos y watcher
function M.setup()
	-- Ejecutar carga inicial de colores
	M.reload(true)

	-- Registrar comando de usuario :MatugenReload
	vim.api.nvim_create_user_command("MatugenReload", function()
		M.reload(false)
	end, { desc = "Recarga el tema dinámico generado por Matugen" })

	-- Registrar autocmd para reaplicar transparencia si algo cambia el colorscheme
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("MatugenTransparency", { clear = true }),
		callback = function()
			M.apply_transparency()
		end,
	})

	-- Iniciar watcher tras inicializar el editor
	vim.schedule(function()
		M.setup_watcher()
	end)
end

return M
