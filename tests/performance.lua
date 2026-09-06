local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
require("config.autocmds")
local function check(lines, expected)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_exec_autocmds("BufReadPost", { buffer = buf })
    assert((vim.b[buf].bigfile == true) == expected)
    if expected then
        assert(vim.bo[buf].filetype == "bigfile")
        assert(vim.b[buf].completion == false)
    end
    vim.api.nvim_buf_delete(buf, { force = true })
end
check({ "local normal = true" }, false)
vim.g.sungp_bigfile_line_length = 3000
check({ string.rep("x", 2500) }, false)
vim.g.sungp_bigfile_line_length = nil
check({ string.rep("x", 2001) }, true)
local lines = {}
for i = 1, 10001 do
    lines[i] = "x"
end
check(lines, true)
local opts = require("plugins.completion")[1].opts
assert(opts.cmdline.sources)
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(buf)
assert(opts.enabled())
vim.bo.buftype = "nofile"
assert(not opts.enabled())
assert(#opts.sources.providers.buffer.opts.get_bufnrs() == 0)
print("PASS large/minified buffers and completion isolation")

-- A picker-open FileType must not load LSP synchronously or revive a closed file.
local loaded = 0
local loading_buf
package.loaded["lazy.core.config"] = { plugins = { ["nvim-lspconfig"] = { _ = {} } } }
package.loaded.lazy = {
    load = function()
        loaded = loaded + 1
        loading_buf = vim.api.nvim_get_current_buf()
    end,
}
local spec = require("plugins.lsp")[1]
spec.init()
local stale = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(stale)
vim.bo[stale].filetype = "lua"
vim.api.nvim_exec_autocmds("FileType", { pattern = "lua", modeline = false })
vim.api.nvim_buf_delete(stale, { force = true })
-- Use a current real buffer so the callback captures the selected file.
local target = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(target)
vim.bo.filetype = "lua"
vim.api.nvim_exec_autocmds("FileType", { pattern = "lua", modeline = false })
assert(loaded == 0, "LSP blocked FileType")
local other = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(other)
assert(
    vim.wait(1000, function()
        return loaded > 0
    end),
    "deferred LSP did not load"
)
assert(loaded == 1, "duplicate deferred LSP load")
assert(loading_buf == target, "deferred plugin configured the wrong buffer")
assert(vim.api.nvim_get_current_buf() == other, "deferred setup stole focus")
print("PASS LSP loading occurs after FileType")
