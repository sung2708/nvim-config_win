vim.env.XDG_STATE_HOME = vim.fn.getcwd() .. "/.nvim-data/test-state"
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.o.hidden = true
local function check(name, fn)
    fn()
    print("PASS " .. name)
end
check("restart preserves unsaved buffers and original attachments after window switch", function()
    local source = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(source)
    vim.api.nvim_buf_set_lines(source, 0, -1, false, { "unsaved" })
    local other = vim.api.nvim_create_buf(true, false)
    local restarted = {}
    local client = { id = 999, name = "test", config = { name = "test" }, attached_buffers = { [source] = true } }
    function client:stop()
        self.stopped = true
    end
    function client:is_stopped()
        return self.stopped
    end
    local get, start = vim.lsp.get_clients, vim.lsp.start
    vim.lsp.get_clients = function()
        return { client }
    end
    vim.lsp.start = function(_, opts)
        restarted[#restarted + 1] = opts.bufnr
    end
    require("helper.lsp").restart()
    require("helper.lsp").restart()
    vim.api.nvim_set_current_buf(other)
    assert(vim.wait(1000, function()
        return #restarted > 0
    end))
    vim.lsp.get_clients, vim.lsp.start = get, start
    assert(#restarted == 1 and restarted[1] == source)
    assert(vim.api.nvim_get_current_buf() == other)
    assert(vim.api.nvim_buf_get_lines(source, 0, -1, false)[1] == "unsaved" and vim.bo[source].modified)
end)
check("terminal setup leaves global shell unchanged", function()
    local names = { "shell", "shellcmdflag", "shellredir", "shellpipe", "shellquote", "shellxquote", "shelltemp" }
    local before = {}
    for _, name in ipairs(names) do
        before[name] = vim.o[name]
    end
    local config
    package.loaded.toggleterm = {
        setup = function(opts)
            config = opts
        end,
    }
    package.loaded["toggleterm.terminal"] =
        { Terminal = {
            new = function(_, opts)
                return opts
            end,
        } }
    require("integrations.toggleterm")
    for _, name in ipairs(names) do
        assert(vim.o[name] == before[name], name)
    end
    assert(config.size({ direction = "vertical" }) % 1 == 0)
end)
check("LSP completion takes precedence over AI when the menu is visible", function()
    local mapping = require("plugins.completion")[1].opts.keymap["<Tab>"]
    local accepted = false
    assert(mapping[1]({
        is_visible = function()
            return true
        end,
        select_and_accept = function()
            accepted = true
            return true
        end,
    }))
    assert(accepted)
end)
check("test debug lazy keys belong to Neotest", function()
    local specs = require("plugins.debug")
    for _, spec in ipairs(specs) do
        for _, key in ipairs(spec.keys or {}) do
            if key[1] == "<leader>nd" or key[1] == "<leader>nD" then
                assert(spec[1] == "nvim-neotest/neotest")
            end
        end
    end
end)
check("Go filetype does not schedule imports on InsertLeave", function()
    local buf = vim.api.nvim_get_current_buf()
    local before = #vim.api.nvim_get_autocmds({ event = "InsertLeave", buffer = buf })
    dofile("after/ftplugin/go.lua")
    assert(#vim.api.nvim_get_autocmds({ event = "InsertLeave", buffer = buf }) == before)
end)
