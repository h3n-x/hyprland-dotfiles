-- ============================================================================
-- Keymaps generales de Neovim
-- Atajos del editor, gestión de ventanas, navegación y terminal integrada
-- Los atajos específicos de plugins se configuran en sus respectivos archivos
-- ============================================================================

local map = vim.keymap.set

-- ---- 1. Navegación entre ventanas y splits ----
map("n", "<C-h>", "<C-w>h", { desc = "Foco ventana izquierda" })
map("n", "<C-l>", "<C-w>l", { desc = "Foco ventana derecha" })
map("n", "<C-j>", "<C-w>j", { desc = "Foco ventana abajo" })
map("n", "<C-k>", "<C-w>k", { desc = "Foco ventana arriba" })

-- Splits de ventanas
map("n", "<leader>sv", "<C-w>v", { desc = "Dividir ventana verticalmente" })
map("n", "<leader>sh", "<C-w>s", { desc = "Dividir ventana horizontalmente" })
map("n", "<leader>se", "<C-w>=", { desc = "Igualar tamaño de ventanas" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Cerrar ventana dividida" })

-- Redimensionar ventanas con flechas
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Aumentar altura de ventana" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Reducir altura de ventana" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Reducir anchura de ventana" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Aumentar anchura de ventana" })

-- ---- 2. Navegación y gestión de buffers ----
map("n", "<S-h>", ":bprevious<CR>", { desc = "Buffer anterior" })
map("n", "<S-l>", ":bnext<CR>", { desc = "Buffer siguiente" })
map("n", "[b", ":bprevious<CR>", { desc = "Buffer anterior" })
map("n", "]b", ":bnext<CR>", { desc = "Buffer siguiente" })
map("n", "<leader>bd", function()
	if Snacks and Snacks.bufdelete then
		Snacks.bufdelete()
	else
		vim.cmd("bdelete")
	end
end, { desc = "Cerrar buffer actual sin alterar splits" })

-- ---- 3. Guardado, salida y acciones rápidas ----
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Guardar archivo" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Cerrar ventana" })
map("n", "<leader>Q", "<cmd>qa<CR>", { desc = "Salir de Neovim" })

-- ---- 4. Terminal integrada (:terminal) ----
-- Salir de modo terminal a modo normal con <Esc>
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Salir del modo terminal a modo normal" })
-- Navegación fluida entre splits directamente desde el modo terminal
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Foco split izquierdo desde terminal" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Foco split inferior desde terminal" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Foco split superior desde terminal" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Foco split derecho desde terminal" })

-- ---- 5. Theming dinámico con Matugen ----
map("n", "<leader>mr", "<cmd>MatugenReload<CR>", { desc = "Recargar tema Matugen (Material You)" })

-- ---- 6. Undotree nativo (Neovim 0.12 builtin) ----
map("n", "<leader>u", function()
	pcall(vim.cmd, "packadd nvim.undotree")
	vim.cmd("Undotree")
end, { desc = "Alternar árbol de deshacer (Undotree nativo)" })

-- ---- 7. Multicursores nativos (Neovim 0.12) ----
map({ "n", "x" }, "<leader>m", "Q", { remap = true, desc = "Alternar multicursor en posición" })

-- ---- 8. Limpiar búsqueda y deseleccionar ----
map("n", "<Esc>", function()
	vim.cmd("nohlsearch")
	pcall(function()
		local mc_ns = vim.api.nvim_create_namespace("nvim.multicursor")
		vim.api.nvim_buf_clear_namespace(0, mc_ns, 0, -1)
	end)
end, { desc = "Limpiar resaltado de búsqueda y multicursores" })

-- ---- 9. Quickfix y Location list ----
map("n", "[q", "<cmd>cprev<CR>", { desc = "Elemento anterior en Quickfix" })
map("n", "]q", "<cmd>cnext<CR>", { desc = "Elemento siguiente en Quickfix" })

-- ---- 10. Mover líneas en modo visual (Alt-style con J/K) ----
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Mover bloque seleccionado abajo" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Mover bloque seleccionado arriba" })

-- ---- 11. Ergonomía de centrado de pantalla ----
map("n", "<C-d>", "<C-d>zz", { desc = "Desplazar media pantalla abajo y centrar" })
map("n", "<C-u>", "<C-u>zz", { desc = "Desplazar media pantalla arriba y centrar" })
map("n", "n", "nzzzv", { desc = "Siguiente coincidencia centrada" })
map("n", "N", "Nzzzv", { desc = "Anterior coincidencia centrada" })

-- ---- 12. Indentación persistente en modo visual ----
map("v", "<", "<gv", { desc = "Desindentar manteniendo selección" })
map("v", ">", ">gv", { desc = "Indentar manteniendo selección" })

-- ---- 13. Manipulación limpia de registros de pegado y borrado ----
map("x", "<leader>p", [["_dP]], { desc = "Pegar sobre selección sin sobreescribir portapapeles" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Borrar hacia el registro vacío (_)" })
