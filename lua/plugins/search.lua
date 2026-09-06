local function find(provider, scope, opts)
    return function()
        local options = vim.deepcopy(opts or {})
        if scope == "project" then
            options.cwd = require("helper.project").root()
        elseif scope == "buffer" then
            options.cwd = require("helper.project").directory()
        elseif scope == "cwd" then
            options.cwd = vim.fn.getcwd()
        end
        return require("fzf-lua")[provider](options)
    end
end

return {
    {
        "ibhagwan/fzf-lua",
        cmd = "FzfLua",
        init = function()
            -- Warm the picker only on the dashboard, during idle time.
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("SungpDashboardPickerWarmup", { clear = true }),
                pattern = "snacks_dashboard",
                once = true,
                callback = function()
                    require("helper.utils").defer_plugin_after_vimenter("fzf-lua", 100)()
                end,
            })
        end,
        keys = {
            {
                "<leader>ff",
                function()
                    require("fzf-lua").files({
                        cwd = require("helper.project").root(),
                        file_icons = true,
                        git_icons = false,
                        previewer = "builtin",
                        winopts = {
                            preview = {
                                delay = 100,
                            },
                        },
                    })
                end,
                desc = "Find: Project Files",
            },
            {
                "<leader>fg",
                function()
                    -- Keep file icons without running a Git status scan per query.
                    require("fzf-lua").live_grep({
                        cwd = require("helper.project").root(),
                        file_icons = true,
                        -- Git status would run during every live reload.
                        git_icons = false,
                        previewer = "builtin",
                        winopts = {
                            preview = {
                                delay = 100,
                            },
                        },
                    })
                end,
                desc = "Find: Project Grep",
            },
            {
                "<leader>fb",
                function()
                    require("fzf-lua").buffers()
                end,
                desc = "Find: Buffers",
            },
            {
                "<leader>fh",
                function()
                    require("fzf-lua").helptags()
                end,
                desc = "Find: Help",
            },
            {
                "<leader>fe",
                find("files", "buffer"),
                desc = "Find: Files From Buffer Directory",
            },
            { "<leader>fF", find("files", "cwd"), desc = "Find: Files (CWD)" },
            { "<leader>fG", find("live_grep", "cwd"), desc = "Find: Grep (CWD)" },
            { "<leader>fE", find("live_grep", "buffer"), desc = "Find: Grep From Buffer Directory" },
            { "<leader>fN", find("live_grep_native", "project"), desc = "Find: Fast Project Grep (No Icons)" },
            { "<leader>fR", find("resume"), desc = "Find: Resume Last Picker" },
            {
                "<leader>fw",
                find("grep_cword", "project", { file_icons = true, git_icons = false }),
                desc = "Find: Word in Project",
            },
            {
                "<leader>fw",
                find("grep_visual", "project", { file_icons = true, git_icons = false }),
                mode = "x",
                desc = "Find: Selection in Project",
            },
            { "<leader>fl", find("blines"), desc = "Find: Lines in Buffer" },
            { "<leader>fO", find("oldfiles"), desc = "Find: Recent Files" },
            { "<leader>fk", find("keymaps"), desc = "Find: Keymaps" },
        },
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("integrations.fzf")
        end,
    },
    {
        "MagicDuck/grug-far.nvim",
        cmd = { "GrugFar", "GrugFarWithin" },
        keys = {
            {
                "<leader>fr",
                function()
                    require("grug-far").open()
                end,
                desc = "Find: Search and Replace",
            },
            {
                "<leader>fr",
                function()
                    require("grug-far").open({
                        visualSelectionUsage = "auto-detect",
                    })
                end,
                mode = "x",
                desc = "Find: Replace Selection",
            },
        },
        opts = {
            headerMaxWidth = 80,
        },
    },
}
