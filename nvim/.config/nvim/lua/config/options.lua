-- ============================================================================
-- Opciones generales
-- ============================================================================

local opt = vim.opt
local g = vim.g

g.mapleader = " "
g.maplocalleader = " "

-- ---- UI ----
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.wrap = false
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.pumheight = 12
opt.winborder = "rounded"

-- ---- Indentado ----
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.autoindent = true

-- ---- Busqueda ----
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- ---- Archivos / undo ----
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undo"
opt.updatetime = 250
opt.timeoutlen = 400

-- ---- Clipboard del sistema (wl-clipboard via Wayland, ya instalado) ----
opt.clipboard = "unnamedplus"

-- ---- Completado ----
opt.completeopt = { "menu", "menuone", "noselect" }

-- ---- Mouse ----
opt.mouse = "a"
