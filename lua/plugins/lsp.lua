local lsp_filetypes = {
    "c",
    "cpp",
    "css",
    "go",
    "gomod",
    "gotmpl",
    "gowork",
    "html",
    "java",
    "javascript",
    "javascriptreact",
    "json",
    "jsonc",
    "less",
    "lua",
    "python",
    "scss",
    "typescript",
    "typescriptreact",
    "vim",
    "vue",
}

local defer_on_filetype = require("helper.utils").defer_plugin_on_filetype
local defer_after_vimenter = require("helper.utils").defer_plugin_after_vimenter

local mason_tools = {
    "clang-format",
    "eslint_d",
    "gomodifytags",
    "gofumpt",
    "goimports",
    "google-java-format",
    "gotests",
    "iferr",
    "impl",
    "java-debug-adapter",
    "jdtls",
    "js-debug-adapter",
    "markdownlint-cli2",
    "prettier",
    "ruff",
    "shellcheck",
    "stylua",
    "typescript-language-server",
}

return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        cmd = { "LspInfo", "LspRestart" },
        dependencies = {
            "saghen/blink.cmp",
            "mason-org/mason.nvim",
            "mason-org/mason-lspconfig.nvim",
        },
        config = function()
            require("integrations.lsp")
        end,
    },
    {
        "rachartier/tiny-code-action.nvim",
        event = "LspAttach",
        dependencies = {
            "ibhagwan/fzf-lua",
        },
        config = function()
            require("integrations.tiny-code-action")
        end,
    },
    {
        "folke/lazydev.nvim",
        lazy = true,
        init = defer_on_filetype("lazydev.nvim", "lua", 20),
        opts = {
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
    {
        "b0o/SchemaStore.nvim",
        ft = { "json", "jsonc" },
        lazy = true,
    },
    {
        "mason-org/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
        keys = {
            { "<leader>cm", "<cmd>Mason<cr>", desc = "Code: Mason" },
        },
        opts = {
            ui = {
                border = "rounded",
            },
        },
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        lazy = true,
        init = defer_after_vimenter("mason-tool-installer.nvim", 30000),
        cmd = {
            "MasonToolsClean",
            "MasonToolsInstall",
            "MasonToolsInstallSync",
            "MasonToolsUpdate",
            "MasonToolsUpdateSync",
        },
        dependencies = {
            "mason-org/mason.nvim",
        },
        opts = {
            ensure_installed = mason_tools,
            auto_update = false,
            run_on_start = true,
            start_delay = 5000,
            debounce_hours = 168,
        },
    },
    {
        "stevearc/conform.nvim",
        -- Load before the first save so format_on_save is active immediately.
        event = { "BufReadPre", "BufNewFile" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>cf",
                function()
                    require("conform").format({ async = true, lsp_format = "fallback" })
                end,
                mode = { "n", "v" },
                desc = "Code: Format",
            },
        },
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "ruff_organize_imports", "ruff_format" },
                javascript = { "prettier" },
                javascriptreact = { "prettier" },
                typescript = { "prettier" },
                typescriptreact = { "prettier" },
                vue = { "prettier" },
                json = { "prettier" },
                jsonc = { "prettier" },
                css = { "prettier" },
                scss = { "prettier" },
                html = { "prettier" },
                markdown = { "prettier" },
                c = { "clang_format" },
                cpp = { "clang_format" },
                go = { "goimports", "gofumpt" },
                java = { "google-java-format" },
            },
            format_on_save = function(bufnr)
                return require("helper.format").on_save(bufnr)
            end,
            notify_on_error = true,
            notify_no_formatters = false,
        },
        init = function()
            vim.api.nvim_create_user_command("FormatDisable", function(opts)
                if opts.bang then
                    vim.b.disable_autoformat = true
                else
                    vim.g.disable_autoformat = true
                end
            end, {
                bang = true,
                desc = "Disable autoformat globally or for this buffer with !",
            })
            vim.api.nvim_create_user_command("FormatEnable", function()
                vim.b.disable_autoformat = false
                vim.g.disable_autoformat = false
            end, {
                desc = "Enable autoformat",
            })
        end,
    },
    {
        "mfussenegger/nvim-lint",
        lazy = true,
        init = defer_on_filetype("nvim-lint", { "markdown", "sh" }, 30),
        keys = {
            {
                "<leader>cL",
                function()
                    require("lint").try_lint()
                end,
                desc = "Code: Lint",
            },
        },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {
                markdown = { "markdownlint-cli2" },
                sh = { "shellcheck" },
            }
            vim.api.nvim_create_autocmd("BufWritePost", {
                group = vim.api.nvim_create_augroup("SungpLint", { clear = true }),
                callback = function(args)
                    if not vim.b[args.buf].bigfile and lint.linters_by_ft[vim.bo[args.buf].filetype] then
                        lint.try_lint(nil, { bufnr = args.buf })
                    end
                end,
            })
        end,
    },
}
