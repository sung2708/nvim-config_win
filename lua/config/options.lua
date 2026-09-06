local opt = vim.opt

-- The machine-local profile is loaded before this file. Keep the fast profile
-- opt-in so capable machines retain the full UI/LSP experience.
vim.g.sungp_low_spec = vim.g.sungp_low_spec == true
if vim.g.sungp_animations == nil then
    vim.g.sungp_animations = not vim.g.sungp_low_spec
end
if vim.g.sungp_breadcrumbs == nil then
    vim.g.sungp_breadcrumbs = not vim.g.sungp_low_spec
end

-- This configuration does not use the legacy Node, Perl, or Ruby remote
-- providers. Disabling them avoids platform-specific health warnings and
-- does not affect regular Lua plugins or external formatters/LSP servers.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Neovim 0.12 supplies modern Lua mappings for Markdown headings. Disable the
-- older Vimscript duplicates to avoid conflicting mappings.
vim.g.no_markdown_maps = 1

local path_separator = vim.fn.has("win32") == 1 and ";" or ":"

local function prepend_path(directory)
    if directory and vim.fn.isdirectory(directory) == 1 then
        local path_entries = vim.split(vim.env.PATH or "", path_separator, { plain = true, trimempty = true })
        local normalized_directory = directory:gsub("\\\\", "/"):gsub("/+$", "")
        if vim.fn.has("win32") == 1 then
            normalized_directory = normalized_directory:lower()
        end

        local remaining_entries = {}
        for _, entry in ipairs(path_entries) do
            local normalized_entry = entry:gsub("\\\\", "/"):gsub("/+$", "")
            if vim.fn.has("win32") == 1 then
                normalized_entry = normalized_entry:lower()
            end
            if normalized_entry ~= normalized_directory then
                table.insert(remaining_entries, entry)
            end
        end

        vim.env.PATH = directory
        if #remaining_entries > 0 then
            vim.env.PATH = vim.env.PATH .. path_separator .. table.concat(remaining_entries, path_separator)
        end
    end
end

local function prepend_node_directory()
    local candidates = {}
    if vim.env.NVM_SYMLINK then
        table.insert(candidates, vim.env.NVM_SYMLINK)
    end
    if vim.env.NVM_HOME then
        table.insert(candidates, vim.env.NVM_HOME .. "/current")
    end

    for _, directory in ipairs(candidates) do
        local node = directory .. (vim.fn.has("win32") == 1 and "/node.exe" or "/node")
        if vim.fn.filereadable(node) == 1 then
            prepend_path(directory)
            return
        end
    end
end

-- Mason owns the configured LSP/formatter/linter executables. Put its bin
-- directory on PATH before any lazy plugin event so first-save formatting and
-- linting work even when Mason's UI plugin has not been loaded yet.
prepend_path(vim.fn.stdpath("data") .. "/mason/bin")

for _, directory in ipairs({ vim.env.UV_PYTHON_BIN_DIR, vim.env.UV_TOOL_BIN_DIR }) do
    prepend_path(directory)
end

if vim.fn.has("win32") == 1 then
    local scoop_home = vim.env.SCOOP or vim.fn.expand("~/scoop")

    -- Prefer the active NVM4W link when it exists. Do not override another
    -- Node manager or a user-selected runtime on machines without NVM4W.
    prepend_node_directory()

    prepend_path(scoop_home .. "/apps/go/current/bin")
    prepend_path(scoop_home .. "/apps/maven/current/bin")
    prepend_path(scoop_home .. "/apps/imagemagick/current")

    -- Volta exposes tree-sitter through a shim that fails when nvim-treesitter
    -- runs it from a downloaded grammar project. Prefer the real executable.
    local volta_tree_sitter = vim.env.LOCALAPPDATA
        and vim.env.LOCALAPPDATA .. "/Volta/tools/image/packages/tree-sitter-cli"
    if volta_tree_sitter and vim.fn.isdirectory(volta_tree_sitter) == 1 then
        prepend_path(volta_tree_sitter)
    end

    local python_provider = vim.fn.stdpath("data") .. "/python-provider/Scripts/python.exe"
    if vim.fn.filereadable(python_provider) == 1 then
        vim.g.python3_host_prog = python_provider
    end

    local scoop_jdk = scoop_home .. "/apps/temurin21-jdk/current"
    if vim.fn.isdirectory(scoop_jdk) == 1 then
        vim.env.JAVA_HOME = vim.env.JAVA_HOME or scoop_jdk
        prepend_path(scoop_jdk .. "/bin")
    end
end

local machine = vim.uv.os_uname().machine:lower()
if vim.fn.has("win32") == 1 and not vim.env.GOARCH and (machine == "x86_64" or machine == "amd64") then
    vim.env.GOARCH = "amd64"
end

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.cursorcolumn = false
opt.termguicolors = true
opt.winborder = "rounded"
opt.signcolumn = "yes"
opt.laststatus = 3
opt.scrolloff = 4
opt.sidescrolloff = 4
opt.list = false
opt.mouse = "a"
opt.showmode = false
opt.fillchars:append({
    eob = " ",
    fold = " ",
    foldopen = "",
    foldclose = "",
    foldsep = " ",
})

opt.autoindent = true
opt.smartindent = true
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.smarttab = true

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

opt.encoding = "utf-8"
opt.hidden = true
opt.updatetime = 400
opt.timeoutlen = 600
opt.ttimeoutlen = 10
opt.redrawtime = 1500
opt.synmaxcol = 400
opt.confirm = true
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 12
opt.winblend = 0
opt.pumblend = 0

if vim.fn.has("win32") == 1 then
    opt.clipboard = "unnamed"
else
    opt.clipboard = "unnamedplus"
end

opt.backup = false
opt.writebackup = false
opt.swapfile = true
opt.undofile = true

opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

opt.foldlevel = 99
opt.foldmethod = "manual"

if vim.g.sungp_low_spec then
    opt.relativenumber = false
    opt.updatetime = 800
    opt.timeoutlen = 400
    opt.redrawtime = 800
    opt.synmaxcol = 200
end
