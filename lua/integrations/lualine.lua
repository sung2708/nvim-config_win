local function lsp_clients()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
        return ""
    end

    local names = {}
    local seen = {}
    for _, client in ipairs(clients) do
        if not seen[client.name] then
            seen[client.name] = true
            table.insert(names, client.name)
        end
    end
    table.sort(names)
    return "󰒋 " .. table.concat(names, ",")
end

local function python_venv()
    if vim.bo.filetype ~= "python" then
        return ""
    end

    local selector = package.loaded["venv-selector"]
    if not selector then
        return ""
    end

    local path = selector.venv()
    if not path or path == "" then
        return ""
    end

    return "󰌠 " .. vim.fn.fnamemodify(path, ":t")
end

require("lualine").setup({
    options = {
        globalstatus = true,
        refresh = {
            refresh_time = 100,
        },
        theme = "auto",
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
    },
    sections = {
        lualine_b = { "branch", "diff" },
        lualine_c = {
            { "filename", path = 0 },
            {
                "diagnostics",
                sources = { "nvim_diagnostic" },
                symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " },
            },
        },
        lualine_x = {
            python_venv,
            lsp_clients,
            "encoding",
            "fileformat",
            "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
    },
    extensions = {
        "fugitive",
        "neo-tree",
        "quickfix",
        "toggleterm",
        "trouble",
    },
    inactive_sections = {
        lualine_c = { { "filename", path = 0 } },
        lualine_x = { "location" },
    },
})
