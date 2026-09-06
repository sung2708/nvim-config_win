local M = require("helper.utils")
local toggleterm = M.safe_require("toggleterm")

if not toggleterm then
    return
end

-- =============================================================================
-- 1. SHELL CONFIGURATION (Cross-platform support)
-- =============================================================================
local shell_executable = vim.o.shell
if vim.fn.has("win32") == 1 then
    if vim.fn.executable("pwsh") == 1 then
        shell_executable = "pwsh"
    else
        shell_executable = "powershell"
    end

    shell_executable = shell_executable .. " -NoLogo -NoProfile"
end

-- Force termguicolors for better highlight support
vim.opt.termguicolors = true

-- =============================================================================
-- 2. SETUP TOGGLETERM
-- =============================================================================
toggleterm.setup({
    size = function(term)
        if term.direction == "horizontal" then
            return 15
        elseif term.direction == "vertical" then
            return math.floor(vim.o.columns * 0.4)
        end
    end,
    open_mapping = [[<C-\>]],
    hide_numbers = true,
    shade_terminals = false,
    start_in_insert = true,
    insert_mappings = false,
    terminal_mappings = true,
    persist_size = true,
    persist_mode = true,
    direction = "float",
    close_on_exit = true,
    shell = shell_executable,
    auto_scroll = true,
    float_opts = {
        border = "curved",
        winblend = 0,
    },
    winbar = {
        enabled = false,
    },
    highlights = {
        Normal = { link = "Normal" },
        NormalFloat = { link = "NormalFloat" },
        FloatBorder = { link = "FloatBorder" },
        SignColumn = { link = "SignColumn" },
        EndOfBuffer = { link = "EndOfBuffer" },
    },
})

-- =============================================================================
-- 3. CUSTOM TERMINAL INSTANCES
-- =============================================================================
local Terminal = require("toggleterm.terminal").Terminal

local function python_command()
    if vim.fn.executable("uv") == 1 then
        return "uv run python"
    end
    if vim.fn.executable("python3") == 1 then
        return "python3"
    end
    if vim.fn.executable("python") == 1 then
        return "python"
    end
end

local function create_custom_term(opts)
    opts.float_opts = opts.float_opts or {}
    opts.float_opts.winblend = 0
    return Terminal:new(opts)
end

-- Python REPL
local python_cmd = python_command()
local python = python_cmd
    and create_custom_term({
        cmd = python_cmd,
        direction = "horizontal",
        hidden = true,
    })

function _PYTHON_TOGGLE()
    if not python then
        vim.notify("Python REPL unavailable: install uv, python3, or python", vim.log.levels.WARN)
        return
    end
    python:toggle()
end

local lazydocker
if vim.fn.executable("lazydocker") == 1 then
    lazydocker = create_custom_term({
        cmd = "lazydocker",
        direction = "float",
        hidden = true,
    })

    function _lazydocker_toggle()
        lazydocker:toggle()
    end
end

-- =============================================================================
-- 4. KEYMAPS (Normal Mode)
-- =============================================================================
local opts = { noremap = true, silent = true }

local function is_sidebar(win)
    local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    return filetype == "neo-tree" or filetype == "oil" or filetype == "NvimTree"
end

local function is_terminal(win)
    local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    return filetype == "toggleterm" or filetype == "terminal"
end

local function focus_editor_window()
    local current = vim.api.nvim_get_current_win()
    if not is_sidebar(current) and not is_terminal(current) then
        return
    end

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if
            vim.api.nvim_win_is_valid(win)
            and vim.api.nvim_win_get_config(win).relative == ""
            and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
            and not is_sidebar(win)
            and not is_terminal(win)
        then
            vim.api.nvim_set_current_win(win)
            return
        end
    end
end

local function open_horizontal_terminal()
    focus_editor_window()
    vim.cmd("ToggleTerm direction=horizontal")
end

-- Custom Apps
vim.keymap.set("n", "<leader>py", _PYTHON_TOGGLE, { desc = "Terminal: Python REPL" })
-- Disabled temporarily: Windows terminal input/ConPTY issue with LazyGit.
-- vim.keymap.set("n", "<leader>gg", _lazygit_toggle, { desc = "Terminal: Lazygit" })
if lazydocker then
    vim.keymap.set("n", "<leader>ld", _lazydocker_toggle, { desc = "Terminal: Lazydocker" })
end

-- Toggle different directions
vim.keymap.set("n", "<leader>th", open_horizontal_terminal, { desc = "Terminal: Horizontal" })
vim.keymap.set("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Terminal: Vertical" })
vim.keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Terminal: Float" })

-- Send visual selection to terminal
vim.keymap.set("v", "<space>s", function()
    require("toggleterm").send_lines_to_terminal("visual_selection", true, { args = vim.v.count })
end, { desc = "Terminal: Send Selection" })

-- =============================================================================
-- 5. TERMINAL MODE MAPPINGS & AUTOCMDS
-- =============================================================================
function _G.set_terminal_keymaps()
    local t_opts = { buffer = 0 }
    vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], t_opts)

    -- Navigation
    vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], t_opts)
    vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], t_opts)
    vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], t_opts)
    vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], t_opts)
end

vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("SungpTerminalKeymaps", { clear = true }),
    pattern = "term://*toggleterm#*",
    callback = function()
        set_terminal_keymaps()
    end,
})

-- =============================================================================
-- 6. CUSTOM COMMANDS
-- =============================================================================
vim.cmd([[command! -count=1 TermGitPush  lua require'toggleterm'.exec("git push",    <count>, 12)]])
vim.cmd([[command! -count=1 TermGitPushF lua require'toggleterm'.exec("git push -f", <count>, 12)]])
