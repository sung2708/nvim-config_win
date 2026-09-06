vim.env.XDG_STATE_HOME = vim.fn.getcwd() .. "/.nvim-data/test-state"
vim.opt.rtp:prepend(vim.fn.getcwd())
require("config.options")
local fixture = vim.fn.getcwd() .. "/.nvim-data/" .. vim.fn.getpid() .. "-autoimport"
assert(not vim.uv.fs_stat(fixture))
vim.fn.mkdir(fixture, "p")
vim.fn.writefile(
    { '{"compilerOptions":{"module":"commonjs","target":"es2020"},"include":["*.ts"]}' },
    fixture .. "/tsconfig.json"
)
vim.fn.writefile({ "export function welcomeUser() { return 1; }" }, fixture .. "/helper.ts")
vim.fn.writefile({ "export {};", "welcomeU" }, fixture .. "/main.ts")
vim.cmd.edit(fixture .. "/main.ts")
vim.bo.filetype = "typescript"
local id
local ok, err = xpcall(function()
    local prefs
    package.loaded["blink.cmp"] = {
        get_lsp_capabilities = function()
            return vim.lsp.protocol.make_client_capabilities()
        end,
    }
    vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/nvim-lspconfig")
    package.loaded["mason-lspconfig"] = { setup = function() end }
    local enable = vim.lsp.enable
    vim.lsp.enable = function() end
    require("integrations.lsp")
    vim.lsp.enable = enable
    prefs = vim.lsp.config.ts_ls.init_options
    id = assert(vim.lsp.start({
        name = "autoimport-test",
        cmd = { "typescript-language-server", "--stdio" },
        root_dir = fixture,
        init_options = prefs,
        capabilities = {
            textDocument = {
                completion = {
                    completionItem = {
                        resolveSupport = {
                            properties = { "additionalTextEdits" },
                        },
                    },
                },
            },
        },
    }))
    assert(
        vim.wait(15000, function()
            local c = vim.lsp.get_client_by_id(id)
            return c and c.initialized
        end),
        "server initialize timeout"
    )
    local client = vim.lsp.get_client_by_id(id)
    local function request(method, params)
        local done, result, failure = false
        client:request(method, params, function(e, r)
            failure = e
            result = r
            done = true
        end, 0)
        assert(
            vim.wait(15000, function()
                return done
            end),
            method .. " timeout"
        )
        assert(not failure, vim.inspect(failure))
        return result
    end
    local item
    for _ = 1, 20 do
        local result = request("textDocument/completion", {
            textDocument = { uri = vim.uri_from_bufnr(0) },
            position = { line = 1, character = 8 },
            context = { triggerKind = 1 },
        })
        for _, candidate in ipairs(result.items or result) do
            if candidate.label:find("welcomeUser", 1, true) then
                item = candidate
                break
            end
        end
        if item then
            break
        end
        vim.wait(300)
    end
    assert(item, "unimported export missing after project indexing")
    item = request("completionItem/resolve", item)
    assert(item.additionalTextEdits and #item.additionalTextEdits > 0, "missing import edit")
    vim.lsp.util.apply_text_edits(item.additionalTextEdits, vim.api.nvim_get_current_buf(), client.offset_encoding)
    assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"):find("import { welcomeUser }", 1, true))
    print("PASS real TypeScript unimported completion, resolve and import edit")
end, debug.traceback)
if id then
    vim.lsp.get_client_by_id(id):stop(true)
end
vim.cmd.bwipeout({ bang = true })
assert(fixture:match("%-autoimport$"))
vim.fn.delete(fixture, "rf")
if not ok then
    error(err)
end
