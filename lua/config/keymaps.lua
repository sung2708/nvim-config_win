local map = vim.keymap.set

map("n", "<A-h>", "<C-w>h", { desc = "Window Left" })
map("n", "<A-j>", "<C-w>j", { desc = "Window Down" })
map("n", "<A-k>", "<C-w>k", { desc = "Window Up" })
map("n", "<A-l>", "<C-w>l", { desc = "Window Right" })

map("t", "<A-h>", "<C-\\><C-n><C-w>h", { desc = "Terminal Window Left" })
map("t", "<A-j>", "<C-\\><C-n><C-w>j", { desc = "Terminal Window Down" })
map("t", "<A-k>", "<C-\\><C-n><C-w>k", { desc = "Terminal Window Up" })
map("t", "<A-l>", "<C-\\><C-n><C-w>l", { desc = "Terminal Window Right" })

map("n", "<leader>j", "<cmd>move .+1<cr>==", { desc = "Move Line Down" })
map("n", "<leader>k", "<cmd>move .-2<cr>==", { desc = "Move Line Up" })
map("v", "<leader>j", ":move '>+1<cr>gv=gv", { desc = "Move Selection Down" })
map("v", "<leader>k", ":move '<-2<cr>gv=gv", { desc = "Move Selection Up" })
map("v", "<", "<gv", { desc = "Indent Left" })
map("v", ">", ">gv", { desc = "Indent Right" })

map("n", "n", "nzzzv", { desc = "Next Search Centered" })
map("n", "N", "Nzzzv", { desc = "Previous Search Centered" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half Page Down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half Page Up" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { silent = true, desc = "Clear Search" })

-- Keep every producer (search, TODO, Git, LSP) usable through the same list
-- navigation. Quicker improves the qf window when it is opened.
map("n", "]q", "<cmd>cnext<cr>", { desc = "Quickfix: Next" })
map("n", "[q", "<cmd>cprev<cr>", { desc = "Quickfix: Previous" })

map("n", "<leader>xD", function()
    vim.diagnostic.setqflist({ open = true })
end, { desc = "Diagnostics: Quickfix" })

map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

map("n", "<leader>bc", function()
    require("snacks").bufdelete()
end, { silent = true, desc = "Close Buffer" })
