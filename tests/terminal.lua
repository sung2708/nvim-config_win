local job = vim.fn.jobstart({ vim.v.progpath, "--embed", "--headless", "-u", "NONE", "-i", "NONE" }, { rpc = true })
assert(job > 0)
local ok, err = xpcall(function()
    vim.rpcrequest(
        job,
        "nvim_exec_lua",
        [[
        local root, plugins = ...
        vim.opt.rtp:prepend(root)
        vim.opt.rtp:append(plugins .. '/toggleterm.nvim')
        _G.original_shell = {vim.o.shell, vim.o.shellcmdflag}
        require('integrations.toggleterm')
        assert(vim.deep_equal(original_shell, {vim.o.shell, vim.o.shellcmdflag}))
        _G.test_terminal = require('toggleterm.terminal').Terminal:new({
            cmd='echo SUNGP_TERMINAL_OK', direction='horizontal', close_on_exit=false,
        })
        test_terminal:open()
    ]],
        { vim.fn.getcwd(), vim.fn.stdpath("data") .. "/lazy" }
    )
    local found = false
    for _ = 1, 50 do
        found = vim.rpcrequest(
            job,
            "nvim_exec_lua",
            [[
            return table.concat(vim.api.nvim_buf_get_lines(test_terminal.bufnr,0,-1,false),'\n'):find('SUNGP_TERMINAL_OK',1,true) ~= nil
        ]],
            {}
        )
        if found then
            break
        end
        vim.wait(100)
    end
    assert(found, "terminal output missing")
    vim.rpcrequest(
        job,
        "nvim_exec_lua",
        [[
        test_terminal:shutdown()
        assert(vim.deep_equal(original_shell, {vim.o.shell, vim.o.shellcmdflag}))
    ]],
        {}
    )
end, debug.traceback)
vim.fn.jobstop(job)
assert(ok, err)
print("PASS real terminal command and unchanged global shell")
