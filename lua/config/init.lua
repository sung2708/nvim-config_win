vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local local_config = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "config", "local.lua")
if vim.uv.fs_stat(local_config) then
    local ok, err = pcall(require, "config.local")
    vim.g.config_local_loaded = ok
    if not ok then
        vim.schedule(function()
            vim.notify("Failed to load config.local: " .. tostring(err), vim.log.levels.ERROR)
        end)
    end
else
    vim.g.config_local_loaded = false
end

require("config.options")

vim.api.nvim_create_user_command("ConfigHealth", function()
    vim.g.sungp_health_buffer = vim.api.nvim_get_current_buf()
    vim.cmd.checkhealth("config")
end, { desc = "Check this configuration and its external tools" })

require("config.autocmds")
require("config.keymaps")
require("config.lazy")
