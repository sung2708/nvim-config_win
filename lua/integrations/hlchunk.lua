local M = require("helper.utils")
local hlchunk = M.safe_require("hlchunk")

if hlchunk then
    local function get_hl(name, fallback)
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        if next(hl) ~= nil then
            return hl
        end
        return vim.api.nvim_get_hl(0, { name = fallback, link = false })
    end

    local exclude_ft = {
        bigfile = true,
        codecompanion = true,
        terminal = true,
        toggleterm = true,
        fzf = true,
        ["neo-tree"] = true,
    }

    hlchunk.setup({
        chunk = {
            enable = true,
            use_treesitter = false,
            style = function()
                return {
                    get_hl("Special", "Directory"),
                    get_hl("DiagnosticError", "ErrorMsg"),
                }
            end,
            chars = {
                left_arrow = "─",
                horizontal_line = "─",
                vertical_line = "│",
                left_top = "╭",
                left_bottom = "╰",
                right_arrow = ">",
            },
            exclude_filetypes = exclude_ft,
            -- Avoid the plugin's async animation path, which can produce
            -- mismatched render state and crash on cursor moves.
            delay = 0,
            max_file_size = 1024 * 1024,
            priority = 15,
        },
        line_num = {
            enable = false,
            exclude_filetypes = exclude_ft,
            priority = 10,
            use_treesitter = true,
        },
        indent = {
            enable = true,
            use_treesitter = false,
            style = function()
                return { get_hl("Whitespace", "NonText") }
            end,
            exclude_filetypes = exclude_ft,
            chars = { "│" },
            priority = 10,
            ahead_lines = 5,
            delay = 100,
        },
        blank = {
            enable = false,
            exclude_filetypes = exclude_ft,
            chars = {
                " ",
            },
        },
    })
end
