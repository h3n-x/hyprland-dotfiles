-- ============================================================================
-- Keymaps generales (no ligados a un plugin -- esos viven junto a su spec
-- en lua/plugins/*.lua, con la tabla `keys` de lazy.nvim)
-- ============================================================================

local map = vim.keymap.set

-- ---- Navegacion entre ventanas ----
map("n", "<C-h>", "<C-w>h", { desc = "Foco ventana izquierda" })
map("n", "<C-l>", "<C-w>l", { desc = "Foco ventana derecha" })
map("n", "<C-j>", "<C-w>j", { desc = "Foco ventana abajo" })
map("n", "<C-k>", "<C-w>k", { desc = "Foco ventana arriba" })

-- ---- Buffers ----
map("n", "<S-l>", ":bnext<CR>", { desc = "Buffer siguiente" })
map("n", "<S-h>", ":bprevious<CR>", { desc = "Buffer anterior" })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Cerrar buffer" })

-- ---- Guardar / salir ----
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Guardar" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Cerrar" })

-- ---- Mover lineas seleccionadas ----
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Mover seleccion abajo" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Mover seleccion arriba" })

-- ---- Mantener el cursor centrado al saltar ----
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- ---- Indentar sin perder la seleccion ----
map("v", "<", "<gv")
map("v", ">", ">gv")

-- ---- Pegar sin perder el registro (sobre seleccion) ----
map("x", "<leader>p", [["_dP]], { desc = "Pegar sin sobreescribir registro" })

-- ---- Copiar/borrar al registro nulo ----
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Borrar al registro nulo" })

-- ---- Split de ventanas ----
map("n", "<leader>sv", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>se", "<C-w>=", { desc = "Igualar tamano de splits" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Cerrar split" })

-- ---- Quitar highlight de busqueda ----
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
