local M = {}
local last_key = 0
vim.on_key(function()
    last_key = vim.uv.hrtime()
end, vim.api.nvim_create_namespace("SungpIdlePlugins"))

M.safe_require = function(mod)
    local ok, m = pcall(require, mod)
    if not ok then
        vim.schedule(function()
            vim.notify("Failed to load " .. mod, vim.log.levels.WARN)
        end)
        return nil
    end
    return m
end

local function load_plugin(plugin)
    local ok, err = pcall(function()
        require("lazy").load({ plugins = { plugin } })
    end)
    if not ok then
        vim.schedule(function()
            vim.notify("Failed to load " .. plugin .. ": " .. tostring(err), vim.log.levels.WARN)
        end)
    end
end

local function plugin_loaded(plugin)
    local ok, config = pcall(require, "lazy.core.config")
    local spec = ok and config.plugins[plugin]
    return spec ~= nil and spec._ ~= nil and spec._.loaded ~= nil
end

-- Return a lazy.nvim `init` callback that loads a service shortly after the UI
-- is ready. This keeps BufRead/FileType free to put the buffer on screen first.
M.defer_plugin_after_vimenter = function(plugin, delay)
    return function()
        local function schedule_load()
            local function try_load()
                if plugin_loaded(plugin) then
                    return
                end
                -- Completion is needed during Insert; optional UI can wait for
                -- a pause instead of interrupting typing or terminal input.
                if
                    plugin ~= "blink.cmp"
                    and (vim.api.nvim_get_mode().mode ~= "n" or (vim.uv.hrtime() - last_key) / 1e6 < 300)
                then
                    vim.defer_fn(try_load, 300)
                    return
                end
                load_plugin(plugin)
                last_key = vim.uv.hrtime()
            end
            vim.defer_fn(try_load, delay or 100)
        end

        if vim.v.vim_did_enter == 1 then
            schedule_load()
            return
        end

        vim.api.nvim_create_autocmd("VimEnter", {
            group = vim.api.nvim_create_augroup("SungpDeferred_" .. plugin:gsub("%W", "_"), { clear = true }),
            once = true,
            callback = schedule_load,
        })
    end
end

-- Return a lazy.nvim `init` callback that waits until after the matching
-- FileType transaction. Native LSP and the language plugins used here all
-- attach to an already-open buffer, so no functionality is lost.
M.defer_plugin_on_filetype = function(plugin, filetypes, delay)
    return function()
        local pending = {}
        local group = vim.api.nvim_create_augroup("SungpFiletype_" .. plugin:gsub("%W", "_"), { clear = true })
        local finished = false

        local function cancel_pending(bufnr)
            local timer = pending[bufnr]
            pending[bufnr] = nil
            if timer and not timer:is_closing() then
                timer:stop()
                timer:close()
            end
        end

        local function finish()
            if finished then
                return
            end
            finished = true

            local timers = pending
            pending = {}
            for _, timer in pairs(timers) do
                if timer and not timer:is_closing() then
                    timer:stop()
                    timer:close()
                end
            end
            pcall(vim.api.nvim_del_augroup_by_id, group)
        end

        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            pattern = filetypes,
            callback = function(args)
                if vim.b[args.buf].bigfile then
                    return
                end

                if plugin_loaded(plugin) then
                    finish()
                    return
                end

                local bufnr = args.buf
                local filetype = vim.bo[bufnr].filetype
                cancel_pending(bufnr)

                pending[bufnr] = vim.defer_fn(function()
                    pending[bufnr] = nil
                    if
                        not vim.api.nvim_buf_is_valid(bufnr)
                        or not vim.api.nvim_buf_is_loaded(bufnr)
                        or vim.bo[bufnr].filetype ~= filetype
                        or vim.b[bufnr].bigfile
                    then
                        return
                    end
                    vim.api.nvim_buf_call(bufnr, function()
                        load_plugin(plugin)
                    end)

                    if plugin_loaded(plugin) then
                        finish()
                    end
                end, delay or 40)
            end,
        })

        vim.api.nvim_create_autocmd("BufWipeout", {
            group = group,
            callback = function(args)
                cancel_pending(args.buf)
            end,
        })
    end
end

return M
