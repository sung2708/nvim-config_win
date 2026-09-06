local core_group = vim.api.nvim_create_augroup("SungpCore", { clear = true })

-- Registered before plugin/filetype detection: catch dense or many-line files
-- that fall below the disk-size cutoff without reading the file a second time.
vim.api.nvim_create_autocmd("BufReadPost", {
    group = core_group,
    callback = function(args)
        local buf = args.buf
        local count = vim.api.nvim_buf_line_count(buf)
        local large = vim.b[buf].bigfile or count > (vim.g.sungp_bigfile_lines or 10000)
        if not large then
            for first = 0, count - 1, 256 do
                for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, first, math.min(first + 256, count), false)) do
                    if #line > (vim.g.sungp_bigfile_line_length or 2000) then
                        large = true
                        break
                    end
                end
                if large then
                    break
                end
            end
        end
        if not large then
            return
        end
        vim.b[buf].bigfile = true
        vim.b[buf].completion = false
        vim.b[buf].minianimate_disable = true
        vim.b[buf].minihipatterns_disable = true
        vim.bo[buf].filetype = "bigfile"
        vim.bo[buf].syntax = "OFF"
        vim.diagnostic.enable(false, { bufnr = buf })
        vim.api.nvim_buf_call(buf, function()
            vim.opt_local.foldmethod = "manual"
            vim.opt_local.cursorcolumn = false
            vim.opt_local.cursorline = false
            vim.opt_local.relativenumber = false
            vim.opt_local.statuscolumn = ""
        end)
    end,
})

-- Neovim's built-in ftplugins for these filetypes start Treesitter
-- synchronously inside FileType, which delays the first rendered frame. Defer
-- only those built-in calls, including files selected from an empty-start dashboard.
-- Explicit plugin/user calls keep normal semantics.
if not vim.g.sungp_deferred_builtin_treesitter then
    vim.g.sungp_deferred_builtin_treesitter = true
    local treesitter_start = vim.treesitter.start
    local deferred_filetypes = { help = true, lua = true, markdown = true, query = true }

    vim.treesitter.start = function(bufnr, lang)
        local caller = debug.getinfo(2, "S")
        local source = caller and caller.source:gsub("\\", "/") or ""
        local builtin_ft = source:match("/runtime/ftplugin/([%w_]+)%.lua$")

        if not deferred_filetypes[builtin_ft] then
            return treesitter_start(bufnr, lang)
        end

        bufnr = bufnr and bufnr ~= 0 and bufnr or vim.api.nvim_get_current_buf()
        local filetype = vim.bo[bufnr].filetype
        vim.defer_fn(function()
            if
                vim.api.nvim_buf_is_valid(bufnr)
                and vim.api.nvim_buf_is_loaded(bufnr)
                and vim.fn.bufwinid(bufnr) ~= -1
                and vim.bo[bufnr].filetype == filetype
                and not vim.b[bufnr].bigfile
            then
                pcall(treesitter_start, bufnr, lang)
            end
        end, 35)
    end
end

vim.api.nvim_create_autocmd("FocusGained", {
    group = core_group,
    callback = function()
        if vim.fn.getcmdwintype() == "" then
            vim.cmd("checktime")
        end
    end,
})

vim.api.nvim_create_autocmd("BufEnter", {
    group = core_group,
    callback = function(args)
        if
            vim.fn.getcmdwintype() == ""
            and vim.api.nvim_buf_is_valid(args.buf)
            and vim.bo[args.buf].buftype == ""
            and vim.api.nvim_buf_get_name(args.buf) ~= ""
        then
            vim.cmd(("checktime %d"):format(args.buf))
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = core_group,
    callback = function()
        vim.opt_local.formatoptions:remove({ "c", "r", "o" })
    end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
    group = core_group,
    callback = function()
        local win = vim.api.nvim_get_current_win()
        vim.w[win].sungp_restore_cursorcolumn = vim.wo[win].cursorcolumn
        vim.w[win].sungp_restore_cursorline = vim.wo[win].cursorline
        vim.w[win].sungp_restore_relativenumber = vim.wo[win].relativenumber
        vim.wo[win].cursorcolumn = false
        vim.wo[win].cursorline = false
        vim.wo[win].relativenumber = false
    end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
    group = core_group,
    callback = function()
        local win = vim.api.nvim_get_current_win()
        if vim.w[win].sungp_restore_cursorcolumn then
            vim.wo[win].cursorcolumn = true
        end
        if vim.w[win].sungp_restore_cursorline then
            vim.wo[win].cursorline = true
        end
        if vim.w[win].sungp_restore_relativenumber then
            vim.wo[win].relativenumber = true
        end
        vim.w[win].sungp_restore_cursorcolumn = nil
        vim.w[win].sungp_restore_cursorline = nil
        vim.w[win].sungp_restore_relativenumber = nil
    end,
})
