local M = {}
local restarting = {}

function M.restart(name)
    local filter = name and name ~= "" and { name = name } or { bufnr = 0 }
    for _, client in ipairs(vim.lsp.get_clients(filter)) do
        if not restarting[client.id] then
            restarting[client.id] = true
            local buffers = vim.tbl_keys(client.attached_buffers)
            local config = client.config
            client:stop(true)
            local attempts = 0
            local function resume()
                attempts = attempts + 1
                if not client:is_stopped() and attempts < 50 then
                    vim.defer_fn(resume, 100)
                    return
                end
                restarting[client.id] = nil
                if not client:is_stopped() then
                    vim.notify("LSP did not stop: " .. client.name, vim.log.levels.WARN)
                    return
                end
                for _, buf in ipairs(buffers) do
                    if
                        vim.api.nvim_buf_is_valid(buf)
                        and vim.api.nvim_buf_is_loaded(buf)
                        and vim.bo[buf].buftype == ""
                        and not vim.b[buf].bigfile
                    then
                        vim.lsp.start(config, { bufnr = buf })
                    end
                end
            end
            vim.defer_fn(resume, 100)
        end
    end
end

function M.typescript_action(kind)
    local buf = vim.api.nvim_get_current_buf()
    if #vim.lsp.get_clients({ bufnr = buf, name = "ts_ls" }) == 0 then
        vim.notify("TypeScript LSP is not ready yet", vim.log.levels.INFO)
        return
    end
    vim.lsp.buf.code_action({ context = { only = { kind }, diagnostics = {} }, apply = true })
end

return M
