local function padded_border(padding)
    return {
        style = "rounded",
        padding = padding or { 1, 2 },
    }
end

require("noice").setup({
    notify = {
        enabled = false,
    },
    cmdline = {
        enabled = true,
        view = "cmdline_popup",
        format = {
            cmdline = { pattern = "^:", icon = "", lang = "vim" },
            search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
            search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
            filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
            lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
            help = { pattern = "^:%s*he?l?p?%s+", icon = "󰋖" },
            input = { view = "cmdline_input", icon = "󰥻 " },
        },
    },
    lsp = {
        progress = { enabled = false },
        signature = { enabled = false },
        hover = { enabled = false },
        message = { enabled = true },
        override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
            ["vim.lsp.util.stylize_markdown"] = false,
            ["cmp.entry.get_documentation"] = false,
        },
    },
    presets = {
        bottom_search = false,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
    },
    messages = {
        enabled = true,
        view = "mini",
        view_search = "cmdline_popup",
    },
    popupmenu = {
        enabled = false,
        backend = "nui",
    },
    views = {
        mini = {
            win_options = {
                winblend = 0,
            },
        },
        cmdline_popup = {
            border = padded_border({ 0, 2 }),
            filter_options = {},
            win_options = {
                winblend = 0,
            },
        },
        cmdline_popupmenu = {
            position = {
                row = 6,
                col = "50%",
            },
            border = padded_border(),
            win_options = {
                winblend = 0,
                winhighlight = {
                    Normal = "NoicePopupmenu",
                    FloatBorder = "NoicePopupmenuBorder",
                    CursorLine = "NoicePopupmenuSelected",
                    PmenuMatch = "NoicePopupmenuMatch",
                },
            },
        },
        popupmenu = {
            border = padded_border(),
            win_options = {
                winblend = 0,
                winhighlight = {
                    Normal = "NoicePopupmenu",
                    FloatBorder = "NoicePopupmenuBorder",
                    CursorLine = "NoicePopupmenuSelected",
                    PmenuMatch = "NoicePopupmenuMatch",
                },
            },
        },
        cmdline_input = {
            border = padded_border({ 0, 2 }),
            win_options = {
                winblend = 0,
            },
        },
        confirm = {
            border = padded_border(),
            win_options = {
                winblend = 0,
            },
        },
        popup = {
            border = padded_border(),
            win_options = {
                winblend = 0,
            },
        },
        hover = {
            border = padded_border(),
            win_options = {
                winblend = 0,
            },
        },
    },
})
