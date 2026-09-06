local capabilities = require("blink.cmp").get_lsp_capabilities()

vim.lsp.config("*", {
    capabilities = capabilities,
    flags = { debounce_text_changes = 150 },
})

local ts_root_dir = vim.lsp.config.ts_ls.root_dir
vim.lsp.config("ts_ls", {
    init_options = {
        preferences = {
            includeCompletionsForModuleExports = true,
            includeCompletionsWithInsertText = true,
            includeCompletionsForImportStatements = true,
        },
    },
    settings = {
        implicitProjectConfiguration = {
            checkJs = false,
        },
    },
    root_dir = function(bufnr, on_dir)
        -- Keep lspconfig's Deno detection, then prefer the nearest JS/TS project.
        ts_root_dir(bufnr, function(root)
            local project = vim.fs.root(bufnr, { "tsconfig.json", "jsconfig.json", "package.json", ".git" })
            on_dir(project and #project > #root and project or root)
        end)
    end,
})

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            completion = {
                callSnippet = "Replace",
            },
            diagnostics = {
                globals = { "vim" },
            },
            hint = {
                enable = true,
            },
            runtime = {
                version = "LuaJIT",
            },
            telemetry = {
                enable = false,
            },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                    "${3rd}/luv/library",
                },
            },
        },
    },
})

local function project_python(root_dir)
    if type(root_dir) ~= "string" or root_dir == "" then
        return nil
    end

    local python = vim.fn.has("win32") == 1 and vim.fs.joinpath(root_dir, ".venv", "Scripts", "python.exe")
        or vim.fs.joinpath(root_dir, ".venv", "bin", "python")

    return vim.fn.filereadable(python) == 1 and python or nil
end

vim.lsp.config("pyright", {
    on_init = function(client)
        local python = project_python(client.config.root_dir)
        if python then
            local settings = {
                python = { pythonPath = python },
            }
            client.settings = vim.tbl_deep_extend("force", client.settings or {}, settings)
            client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, settings)
            client:notify("workspace/didChangeConfiguration", { settings = client.settings })
        end
    end,
    settings = {
        python = {
            analysis = {
                autoImportCompletions = true,
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "basic",
            },
        },
    },
})

vim.lsp.config("ruff", {
    on_attach = function(client)
        client.server_capabilities.hoverProvider = false
    end,
})

local function clangd_cmd()
    local cmd = {
        "clangd",
        "--log=error",
        "--completion-style=detailed",
        "--header-insertion=iwyu",
    }

    if not vim.g.sungp_low_spec then
        table.insert(cmd, "--background-index")
        table.insert(cmd, "--clang-tidy")
    end

    local candidates = {
        vim.fn.exepath("g++"),
        vim.fn.exepath("clang++"),
        vim.fn.expand("~/scoop/apps/gcc/current/bin/g++.exe"),
        vim.fn.expand("~/scoop/apps/llvm/current/bin/clang++.exe"),
    }

    local seen = {}
    local drivers = {}
    for _, path in ipairs(candidates) do
        if path:find("*", 1, true) then
            table.insert(drivers, path)
        elseif path ~= "" and vim.fn.executable(path) == 1 then
            path = vim.fn.fnamemodify(path, ":p"):gsub("\\", "/")
            if not seen[path] then
                seen[path] = true
                table.insert(drivers, path)
            end
        end
    end

    if #drivers > 0 then
        table.insert(cmd, "--query-driver=" .. table.concat(drivers, ","))
    end

    return cmd
end

local function clangd_fallback_flags()
    local flags = {
        "--target=x86_64-w64-windows-gnu",
        "-std=c++20",
        "-D_REENTRANT",
    }

    local gcc_root = vim.fn.expand("~/scoop/apps/gcc/current")
    local cpp_root = gcc_root .. "/include/c++"
    local cpp_versions = vim.fn.glob(cpp_root .. "/*", false, true)

    if #cpp_versions == 0 then
        return flags
    end

    table.sort(cpp_versions)
    local cpp_include = cpp_versions[#cpp_versions]:gsub("\\", "/")
    local version = vim.fn.fnamemodify(cpp_include, ":t")
    local target = "x86_64-w64-mingw32"
    local gcc_lib = (gcc_root .. "/lib/gcc/" .. target .. "/" .. version):gsub("\\", "/")

    local includes = {
        cpp_include,
        cpp_include .. "/" .. target,
        cpp_include .. "/backward",
        gcc_lib .. "/include",
        gcc_lib .. "/include-fixed",
        gcc_root .. "/" .. target .. "/include",
        gcc_root .. "/include",
    }

    for _, include in ipairs(includes) do
        if vim.fn.isdirectory(include) == 1 then
            table.insert(flags, "-isystem")
            table.insert(flags, include)
        end
    end

    return flags
end

local clangd_enabled = false
local function enable_clangd()
    if clangd_enabled then
        return
    end
    clangd_enabled = true

    vim.lsp.config("clangd", {
        cmd = clangd_cmd(),
        init_options = {
            fallbackFlags = clangd_fallback_flags(),
        },
    })
    vim.lsp.enable("clangd")
end

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("SungpClangd", { clear = true }),
    pattern = { "c", "cpp" },
    callback = enable_clangd,
})

vim.schedule(function()
    if vim.bo.filetype == "c" or vim.bo.filetype == "cpp" then
        enable_clangd()
    end
end)

vim.lsp.config("gopls", {
    settings = {
        gopls = {
            analyses = {
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
            },
            completeUnimported = true,
            gofumpt = true,
            staticcheck = not vim.g.sungp_low_spec,
            usePlaceholders = true,
        },
    },
})

vim.lsp.config("jsonls", {
    before_init = function(_, config)
        config.settings = config.settings or {}
        config.settings.json = config.settings.json or {}
        config.settings.json.schemas = require("schemastore").json.schemas()
    end,
    settings = {
        json = {
            validate = { enable = true },
        },
    },
})

local function fzf(method, fallback)
    return function()
        local ok, picker = pcall(require, "fzf-lua")
        if ok then
            picker[method]()
        else
            fallback()
        end
    end
end

local function workspace_symbols()
    vim.ui.input({ prompt = "Workspace symbol: " }, function(query)
        if query and query ~= "" then
            vim.lsp.buf.workspace_symbol(query)
        end
    end)
end

local attach_group = vim.api.nvim_create_augroup("SungpLspAttach", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
    group = attach_group,
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end
        local uri_scheme = vim.uri_from_bufnr(bufnr):match("^([%w+.-]+):")

        if vim.b[bufnr].bigfile or vim.bo[bufnr].buftype ~= "" or (uri_scheme and uri_scheme ~= "file") then
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(bufnr) then
                    vim.lsp.buf_detach_client(bufnr, client.id)
                    if not next(client.attached_buffers) then
                        client:stop()
                    end
                end
            end)
            return
        end

        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, {
                buffer = bufnr,
                silent = true,
                desc = "LSP: " .. desc,
            })
        end

        if client.name == "ts_ls" then
            for lhs, action in pairs({
                ["<leader>Ti"] = { "source.organizeImports.ts", "Organize Imports" },
                ["<leader>Ta"] = { "source.addMissingImports.ts", "Add Missing Imports" },
                ["<leader>Tu"] = { "source.removeUnused.ts", "Remove Unused" },
                ["<leader>Tf"] = { "source.fixAll.ts", "Fix All" },
            }) do
                map("n", lhs, function()
                    require("helper.lsp").typescript_action(action[1])
                end, action[2])
            end
        end

        map("n", "gd", fzf("lsp_definitions", vim.lsp.buf.definition), "Definitions")
        map("n", "gy", fzf("lsp_typedefs", vim.lsp.buf.type_definition), "Type Definitions")
        map("n", "gi", fzf("lsp_implementations", vim.lsp.buf.implementation), "Implementations")
        map("n", "grr", fzf("lsp_references", vim.lsp.buf.references), "References")
        map("n", "gO", fzf("lsp_document_symbols", vim.lsp.buf.document_symbol), "Document Symbols")
        map("n", "<leader>cS", fzf("lsp_live_workspace_symbols", workspace_symbols), "Workspace Symbols")
        map("n", "K", function()
            vim.lsp.buf.hover({ border = "rounded" })
        end, "Hover")
        map("n", "<leader>e", function()
            vim.lsp.buf.hover({ border = "rounded" })
        end, "Hover")
        map({ "n", "v" }, "<leader>ca", function()
            require("tiny-code-action").code_action()
        end, "Code Action")
        vim.keymap.set("n", "<leader>rn", function()
            return ":IncRename " .. vim.fn.expand("<cword>")
        end, {
            buffer = bufnr,
            silent = false,
            expr = true,
            desc = "LSP: Rename with Preview",
        })
        map("n", "<leader>cd", function()
            vim.diagnostic.open_float({ border = "rounded", source = "if_many" })
        end, "Line Diagnostics")
        map("n", "]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
        end, "Next Diagnostic")
        map("n", "[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
        end, "Previous Diagnostic")

        if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map("n", "<leader>ci", function()
                local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
                vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
            end, "Toggle Inlay Hints")
        end

        if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_group = vim.api.nvim_create_augroup("SungpLspHighlight" .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd("CursorHold", {
                group = highlight_group,
                buffer = bufnr,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
                group = highlight_group,
                buffer = bufnr,
                callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd("LspDetach", {
                group = highlight_group,
                buffer = bufnr,
                callback = function()
                    vim.schedule(function()
                        if not vim.api.nvim_buf_is_valid(bufnr) then
                            pcall(vim.api.nvim_del_augroup_by_id, highlight_group)
                            return
                        end

                        local has_highlight_client = false
                        for _, attached_client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
                            if
                                attached_client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight)
                            then
                                has_highlight_client = true
                                break
                            end
                        end

                        if not has_highlight_client then
                            -- The buffer can disappear between the validity
                            -- check above and this scheduled callback. When
                            -- that happens, its namespaces are destroyed with
                            -- the buffer, so there is nothing to clear.
                            pcall(vim.api.nvim_del_augroup_by_id, highlight_group)
                        end
                    end)
                end,
            })
        end
    end,
})

vim.diagnostic.config({
    severity_sort = true,
    update_in_insert = false,
    underline = true,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = "󰌵 ",
        },
    },
    virtual_text = {
        prefix = "●",
        spacing = 2,
        source = "if_many",
    },
    float = {
        border = "rounded",
        source = "if_many",
    },
})

vim.api.nvim_create_user_command("LspInfo", function()
    vim.cmd("checkhealth vim.lsp")
end, {
    desc = "Show native LSP health and active client info",
})

vim.api.nvim_create_user_command("LspRestart", function(opts)
    require("helper.lsp").restart(opts.args)
end, {
    nargs = "?",
    complete = function()
        local names = {}
        for _, client in ipairs(vim.lsp.get_clients()) do
            table.insert(names, client.name)
        end
        return names
    end,
    desc = "Restart LSP clients for the current buffer or by server name",
})

local servers = {
    "cssls",
    "eslint",
    "gopls",
    "html",
    "jsonls",
    "lua_ls",
    "pyright",
    "ruff",
    "ts_ls",
    "vimls",
}

require("mason-lspconfig").setup({
    ensure_installed = vim.list_extend({ "clangd" }, vim.deepcopy(servers)),
    automatic_enable = false,
})

-- Enabling the list in one call makes Neovim replay FileType only once,
-- instead of once per server through mason-lspconfig's automatic loop.
vim.lsp.enable(servers)
