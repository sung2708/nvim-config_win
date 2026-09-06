vim.opt_local.expandtab = false
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 0
vim.opt_local.tabstop = 4

-- Import completion is handled by gopls; Conform runs goimports on save.
-- Avoid late InsertLeave edits racing with typing or the save formatter.
