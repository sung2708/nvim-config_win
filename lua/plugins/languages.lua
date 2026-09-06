local defer_on_filetype = require("helper.utils").defer_plugin_on_filetype

return {
    {
        "linux-cultist/venv-selector.nvim",
        lazy = true,
        init = defer_on_filetype("venv-selector.nvim", "python", 30),
        cmd = { "VenvSelect", "VenvSelectLog" },
        keys = {
            { "<leader>pv", "<cmd>VenvSelect<cr>", desc = "Python: Select Virtualenv" },
        },
        opts = {
            options = {
                picker = "fzf-lua",
                notify_user_on_venv_activation = true,
            },
        },
        config = function(_, opts)
            require("venv-selector").setup(opts)

            local bufnr = vim.api.nvim_get_current_buf()
            if vim.bo[bufnr].filetype == "python" then
                vim.schedule(function()
                    if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "python" then
                        return
                    end
                    for _, group in ipairs({ "VenvSelectorCachedVenv", "VenvSelectorUvDetect" }) do
                        pcall(vim.api.nvim_exec_autocmds, "FileType", {
                            group = group,
                            buffer = bufnr,
                            modeline = false,
                        })
                    end
                end)
            end
        end,
    },
    {
        "ray-x/go.nvim",
        lazy = true,
        init = defer_on_filetype("go.nvim", { "go", "gomod", "gowork", "gotmpl" }, 50),
        dependencies = {
            "ray-x/guihua.lua",
            "nvim-treesitter/nvim-treesitter",
        },
        keys = {
            { "<leader>Gi", "<cmd>GoIfErr<cr>", desc = "Go: Add If Error" },
            { "<leader>Gt", "<cmd>GoAddTag json<cr>", desc = "Go: Add JSON Tags" },
            { "<leader>GT", "<cmd>GoRmTag json<cr>", desc = "Go: Remove JSON Tags" },
            { "<leader>Gc", "<cmd>GoCmt<cr>", desc = "Go: Generate Comment" },
            { "<leader>Gf", "<cmd>GoAddTest<cr>", desc = "Go: Generate Function Test" },
            { "<leader>GF", "<cmd>GoAddAllTest<cr>", desc = "Go: Generate File Tests" },
            { "<leader>Ga", "<cmd>GoAlt<cr>", desc = "Go: Alternate Test File" },
            { "<leader>Gs", "<cmd>GoFillStruct<cr>", desc = "Go: Fill Struct" },
            { "<leader>GI", "<cmd>GoImpl<cr>", desc = "Go: Implement Interface" },
        },
        opts = {
            lsp_cfg = false,
            lsp_document_formatting = false,
            goimports = "gopls",
            gofmt = "gofumpt",
            lsp_inlay_hints = {
                enable = false,
            },
            tag_options = "json=omitempty",
            verbose = false,
        },
    },
    {
        "pmizio/typescript-tools.nvim",
        enabled = false,
        ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        keys = {
            { "<leader>Ti", "<cmd>TSToolsOrganizeImports<cr>", desc = "TypeScript: Organize Imports" },
            { "<leader>Ta", "<cmd>TSToolsAddMissingImports<cr>", desc = "TypeScript: Add Missing Imports" },
            { "<leader>Tu", "<cmd>TSToolsRemoveUnused<cr>", desc = "TypeScript: Remove Unused" },
            { "<leader>Tf", "<cmd>TSToolsFixAll<cr>", desc = "TypeScript: Fix All" },
            { "<leader>Tr", "<cmd>TSToolsRenameFile<cr>", desc = "TypeScript: Rename File" },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "neovim/nvim-lspconfig",
            "saghen/blink.cmp",
        },
        config = function()
            require("integrations.typescript")
        end,
    },
    {
        "mfussenegger/nvim-jdtls",
        lazy = true,
        init = defer_on_filetype("nvim-jdtls", "java", 50),
        dependencies = {
            "mfussenegger/nvim-dap",
            "mason-org/mason.nvim",
        },
        config = function()
            require("integrations.java").setup()
        end,
    },
}
