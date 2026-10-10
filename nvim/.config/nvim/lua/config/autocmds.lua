-- ============================================================================
-- Autocomandos generales del editor
-- Comportamiento automático, eventos del ciclo de vida y ergonomía
-- ============================================================================

local augroup = vim.api.nvim_create_augroup("DotfilesAutocmds", { clear = true })

-- ---- 1. Resaltar texto al copiar (yank) ----
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup,
	desc = "Resaltar temporalmente la región copiada",
	callback = function()
		if vim.hl and vim.hl.on_yank then
			vim.hl.on_yank({ timeout = 180 })
		else
			vim.highlight.on_yank({ timeout = 180 })
		end
	end,
})

-- ---- 2. Restaurar la última posición del cursor al abrir un archivo ----
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup,
	desc = "Restaurar cursor en la última posición editada",
	callback = function(args)
		local valid_line = vim.fn.line([['"]]) > 1 and vim.fn.line([['"]]) <= vim.fn.line("$")
		local not_commit = vim.b[args.buf].filetype ~= "commit"
		if valid_line and not_commit then
			vim.cmd([[normal! g`"]])
		end
	end,
})

-- ---- 3. Rebalancear splits automáticamente al cambiar el tamaño de ventana ----
vim.api.nvim_create_autocmd("VimResized", {
	group = augroup,
	desc = "Ajustar proporciones de splits al redimensionar ventana de kitty/Hyprland",
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- ---- 4. Cerrar ventanas auxiliares / solo lectura con tecla 'q' ----
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = {
		"help",
		"man",
		"qf",
		"lspinfo",
		"checkhealth",
		"notify",
		"startuptime",
		"gitsigns-blame",
		"dap-float",
	},
	desc = "Cerrar ventanas utilitarias fácilmente con 'q'",
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<CR>", {
			buffer = event.buf,
			silent = true,
			desc = "Cerrar ventana auxiliar",
		})
	end,
})

-- ---- 5. Crear directorios intermedios automáticamente al guardar ----
vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup,
	desc = "Crear directorios padre inexistentes antes de guardar archivo",
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- ---- 6. Recargar archivo si fue modificado externamente (FocusGained / BufEnter) ----
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "TermClose", "TermLeave" }, {
	group = augroup,
	desc = "Sincronizar cambios externos al recuperar el foco",
	callback = function()
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
})

-- ---- 7. Ajustes para buffers de terminal integrada ----
vim.api.nvim_create_autocmd("TermOpen", {
	group = augroup,
	desc = "Ajustes de buffer para terminal integrada",
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.cmd("startinsert")
	end,
})
