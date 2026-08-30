-- Enhanced NVChad mappings module
-- Clean, organized with extra features

require "nvchad.mappings"

local map = vim.keymap.set
local opts = { silent = true, noremap = true }

-------------------------------------
-- GENERAL
-------------------------------------
map("n", ";", ":", { desc = "Enter command mode" })
map("i", "jk", "<ESC>", { desc = "Exit insert mode" })
map({"n","i","v"}, "<C-s>", "<cmd>w<CR>", { desc = "Save file" })

-------------------------------------
-- TERMINAL
-------------------------------------
map("t", "<C-q>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "jk", "<C-\\><C-n>", { desc = "Exit terminal mode with jk" })

-- Shortcut to create a new buffer with a terminal open
map("n", "<leader>bt", function()
  vim.cmd("enew | terminal")
end, { desc = "New buffer with terminal" })

-------------------------------------
-- BUFFER NAVIGATION
-------------------------------------
-- Move to next/previous buffer using native Neovim commands
map("n", "<leader>bl", ":bn<CR>", { desc = "Next buffer" })
map("n", "<leader>bh", ":bp<CR>", { desc = "Previous buffer" })

-- Close current buffer
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete current buffer" })

-------------------------------------
-- WINDOW NAVIGATION
-------------------------------------
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
map("n", "<C-w>", "<C-w>w", { desc = "Cycle windows" })
map("n", "<leader>sh", ":split<CR>", { desc = "Horizontal split" })
map("n", "<leader>sv", ":vsplit<CR>", { desc = "Vertical split" })
map("n", "<leader>cw", ":close<CR>", { desc = "Close current window" })
map("n", "<leader>so", ":only<CR>", { desc = "Maximize current window" })
map("n", "<leader>=", ":wincmd =<CR>", { desc = "Equalize window sizes" })

-------------------------------------
-- QUALITY OF LIFE
-------------------------------------
map("n", "<leader>rn", function() vim.o.relativenumber = not vim.o.relativenumber end, { desc = "Toggle relative number" })
map("n", "<Esc>", ":noh<CR>", { desc = "Clear search highlight" })
