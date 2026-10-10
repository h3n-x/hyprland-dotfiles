-- ============================================================================
-- Opciones generales del editor (Neovim 0.12+)
-- Optimizadas para velocidad, ergonomía modal e integración con Wayland/Hyprland
-- ============================================================================

local opt = vim.opt
local g = vim.g

-- Líderes para combinaciones de teclas
g.mapleader = " "
g.maplocalleader = " "

-- ---- Integración de Apariencia con el Sistema (Hyprland + kitty) ----
-- Si está en true, se remueve el fondo de Normal/NormalFloat para heredar
-- la transparencia y el blur configurados en Hyprland/kitty (0.92).
g.transparent_background = true

-- ---- UI y Ventanas ----
opt.background = "dark"
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen" -- Mantiene estabilidad visual del texto al crear splits
opt.smoothscroll = true -- Scroll suave en líneas largas con wrap
opt.wrap = false
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.pumheight = 12
opt.winborder = "rounded"

-- ---- Comportamiento y Modos ----
opt.confirm = true -- Solicita confirmación para guardar antes de abortar al salir
opt.virtualedit = "block" -- Movimiento libre en selección por bloque visual (<C-v>)

-- ---- Indentación ----
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.autoindent = true

-- ---- Búsqueda y Sustitución ----
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.inccommand = "split" -- Previsualización dividida en tiempo real de sustituciones (:%s)
opt.jumpoptions = "view" -- Conserva la vista exacta al saltar con <C-o>/<C-i>

-- ---- Archivos, Undo y Tiempos ----
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undo"
opt.updatetime = 200 -- Tiempo para disparar eventos CursorHold
opt.timeoutlen = 300 -- Tiempo de espera para secuencias de teclas

-- ---- Portapapeles del Sistema (Wayland wl-clipboard) ----
opt.clipboard = "unnamedplus"

-- ---- Autocompletado nativo y menús emergentes ----
-- Neovim 0.12 cuenta con autocompletado nativo vía `vim.o.autocomplete` y `completeopt`,
-- aunque en esta configuración utilizamos `saghen/blink.cmp` como motor principal.
opt.completeopt = { "menu", "menuone", "noselect" }

-- ---- Soporte de Ratón ----
opt.mouse = "a"

-- ============================================================================
-- Deshabilitar plugins built-in innecesarios de Neovim
-- Acelera significativamente el tiempo de inicio (<80ms startup)
-- ============================================================================
g.loaded_gzip = 1
g.loaded_zip = 1
g.loaded_zipPlugin = 1
g.loaded_tar = 1
g.loaded_tarPlugin = 1
g.loaded_getscript = 1
g.loaded_getscriptPlugin = 1
g.loaded_vimball = 1
g.loaded_vimballPlugin = 1
g.loaded_2html_plugin = 1
g.loaded_logiPat = 1
g.loaded_rrhelper = 1
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1
g.loaded_netrwSettings = 1
g.loaded_netrwFileHandlers = 1
