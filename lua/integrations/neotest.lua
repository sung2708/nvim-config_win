local neotest = require("neotest")
local adapters = {}

local function add_adapter(module_name)
    local ok, adapter = pcall(require, module_name)
    if not ok then
        return
    end

    local configured_ok, configured = pcall(adapter, {})
    if configured_ok then
        table.insert(adapters, configured)
    else
        vim.notify(module_name .. " is incompatible with the installed neotest version", vim.log.levels.WARN)
    end
end

add_adapter("neotest-python")
add_adapter("neotest-jest")
add_adapter("neotest-golang")
add_adapter("neotest-java")

neotest.setup({
    adapters = adapters,
    quickfix = {
        open = false,
    },
    output = {
        open_on_run = false,
    },
    floating = {
        border = "rounded",
        options = {
            winblend = 0,
        },
    },
})

vim.api.nvim_create_user_command("NeotestSummary", function()
    neotest.summary.toggle()
end, {})

vim.keymap.set("n", "<leader>nt", function()
    neotest.run.run()
end, { desc = "Test: Nearest" })
vim.keymap.set("n", "<leader>nf", function()
    neotest.run.run(vim.api.nvim_buf_get_name(0))
end, { desc = "Test: File" })
vim.keymap.set("n", "<leader>nT", function()
    neotest.run.run(require("helper.project").root())
end, { desc = "Test: Project" })
vim.keymap.set("n", "<leader>ns", neotest.summary.toggle, { desc = "Test: Summary" })
vim.keymap.set("n", "<leader>no", neotest.output.open, { desc = "Test: Output" })
vim.keymap.set("n", "<leader>nO", neotest.output_panel.toggle, { desc = "Test: Output Panel" })
vim.keymap.set("n", "<leader>nw", neotest.watch.toggle, { desc = "Test: Watch" })

local function debug_test(target)
    -- Keep DAP lazy; load it only when a test is explicitly debugged.
    local ok, err = pcall(function()
        require("lazy").load({ plugins = { "nvim-dap" } })
        neotest.run.run({ target, strategy = "dap" })
    end)
    if not ok then
        vim.notify("Neotest DAP strategy is unavailable: " .. tostring(err), vim.log.levels.WARN)
    end
end

vim.keymap.set("n", "<leader>nd", function()
    debug_test(nil)
end, { desc = "Test: Debug Nearest" })
vim.keymap.set("n", "<leader>nD", function()
    debug_test(vim.api.nvim_buf_get_name(0))
end, { desc = "Test: Debug File" })
