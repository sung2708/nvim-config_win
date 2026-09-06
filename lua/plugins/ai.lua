local plugin_data_home = vim.fs.joinpath(vim.fn.stdpath("data"), "nvim-config")
local codex_sqlite_home = vim.fs.joinpath(plugin_data_home, "codex-sqlite")
local selection_actions = require("integrations.codecompanion")

local codex_command = vim.fn.has("win32") ~= 0 and { "cmd.exe", "/d", "/s", "/c", "codex-acp" } or { "codex-acp" }

local function stop_last_chat()
    local chat = require("codecompanion").last_chat()
    if not chat then
        vim.notify("CodeCompanion has no active chat", vim.log.levels.WARN)
        return
    end

    chat:stop()
end

local function with_chat(callback)
    local codecompanion = require("codecompanion")
    local chat = codecompanion.last_chat() or codecompanion.chat()

    if not chat then
        vim.notify("CodeCompanion could not create a chat", vim.log.levels.ERROR)
        return
    end

    if chat.ui and not chat.ui:is_visible() then
        chat.ui:open()
    end

    callback(chat)
end

local function with_ready_acp_session(chat, callback)
    if chat.adapter.type ~= "acp" then
        callback(chat)
        return
    end

    local attempts = 0
    local max_attempts = 400

    local function wait_for_session()
        if not vim.api.nvim_buf_is_valid(chat.bufnr) then
            return
        end

        local connection = chat.acp_connection
        if connection and connection:is_connected() then
            callback(chat)
            return
        end

        attempts = attempts + 1
        if attempts >= max_attempts then
            vim.notify("Timed out while preparing the ACP session", vim.log.levels.ERROR)
            return
        end

        vim.defer_fn(wait_for_session, 50)
    end

    wait_for_session()
end

local function change_model_or_provider()
    with_chat(function(chat)
        with_ready_acp_session(chat, function(ready_chat)
            require("codecompanion.interactions.chat.keymaps.change_adapter").callback(ready_chat)
        end)
    end)
end

local function change_acp_session_options()
    with_chat(function(chat)
        with_ready_acp_session(chat, function(ready_chat)
            if ready_chat.adapter.type ~= "acp" then
                vim.notify("Effort is available through an ACP provider such as Codex", vim.log.levels.WARN)
                return
            end

            require("codecompanion.interactions.chat.slash_commands.builtin.acp_session_options")
                .new({ Chat = ready_chat })
                :execute()
        end)
    end)
end

local function open_review_diff(target)
    vim.api.nvim_cmd({
        cmd = "DiffviewOpen",
        args = {
            "-C" .. target.root,
            target.baseline_ref,
            "--",
            target.path,
        },
    }, {})
end

return {
    {
        "olimorris/codecompanion.nvim",
        version = "^19.0.0",
        cmd = {
            "CodeCompanion",
            "CodeCompanionActions",
            "CodeCompanionChat",
            "CodeCompanionCodeReview",
        },
        keys = {
            {
                "<leader>a?",
                "<cmd>CodeCompanionActions<cr>",
                mode = { "n", "v" },
                desc = "CodeCompanion: Actions",
            },
            {
                "<leader>aa",
                "<cmd>CodeCompanionActions<cr>",
                mode = "n",
                desc = "CodeCompanion: Actions",
            },
            {
                "<leader>aa",
                "<cmd>CodeCompanionChat Add<cr>",
                mode = "v",
                desc = "CodeCompanion: Add Selection",
            },
            {
                "<leader>am",
                selection_actions.selection_menu,
                mode = "v",
                desc = "CodeCompanion: Selection Menu",
            },
            {
                "<leader>aq",
                selection_actions.ask_selection,
                mode = "v",
                desc = "CodeCompanion: Ask Selection",
            },
            {
                "<leader>ae",
                function()
                    selection_actions.run_selection_prompt("explain")
                end,
                mode = "v",
                desc = "CodeCompanion: Explain Selection",
            },
            {
                "<leader>af",
                function()
                    selection_actions.run_selection_prompt("fix")
                end,
                mode = "v",
                desc = "CodeCompanion: Fix Selection",
            },
            {
                "<leader>al",
                function()
                    selection_actions.run_selection_prompt("lsp")
                end,
                mode = "v",
                desc = "CodeCompanion: Explain Selection Diagnostics",
            },
            {
                "<leader>at",
                function()
                    selection_actions.run_selection_prompt("tests_chat")
                end,
                mode = "v",
                desc = "CodeCompanion: Generate Selection Tests",
            },
            {
                "<leader>aR",
                function()
                    selection_actions.run_selection_prompt("refactor_selection")
                end,
                mode = "v",
                desc = "CodeCompanion: Refactor Selection",
            },
            {
                "<leader>ac",
                "<cmd>CodeCompanionCodeReview Comment<cr>",
                mode = { "n", "v" },
                desc = "CodeCompanion: Review Comment",
            },
            {
                "<leader>ai",
                "<cmd>CodeCompanionChat Toggle<cr>",
                mode = { "n", "v" },
                desc = "CodeCompanion: Toggle Chat",
            },
            {
                "<leader>an",
                "<cmd>CodeCompanionChat<cr>",
                mode = { "n", "v" },
                desc = "CodeCompanion: New Chat",
            },
            {
                "<leader>aM",
                change_model_or_provider,
                mode = "n",
                desc = "CodeCompanion: Change Provider / Model",
            },
            {
                "<leader>ao",
                change_acp_session_options,
                mode = "n",
                desc = "CodeCompanion: ACP Model / Effort",
            },
            {
                "<leader>ar",
                "<cmd>CodeCompanionChat RefreshCache<cr>",
                desc = "CodeCompanion: Refresh Cache",
            },
            {
                "<leader>aS",
                stop_last_chat,
                desc = "CodeCompanion: Stop",
            },
            {
                "<leader>av",
                "<cmd>CodeCompanionCodeReview<cr>",
                desc = "CodeCompanion: Review Agent Changes",
            },
            {
                "<leader>aV",
                "<cmd>CodeCompanionCodeReview All<cr>",
                desc = "CodeCompanion: Review All Changes",
            },
            {
                "<leader>ax",
                "<cmd>CodeCompanionChat Changes<cr>",
                desc = "CodeCompanion: Changed Files",
            },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "MunifTanjim/nui.nvim",
            {
                "HakonHarnes/img-clip.nvim",
                opts = {
                    filetypes = {
                        codecompanion = {
                            prompt_for_file_name = false,
                            template = "[Image]($FILE_PATH)",
                            use_absolute_path = true,
                        },
                    },
                },
            },
        },
        config = function(_, opts)
            vim.fn.mkdir(codex_sqlite_home, "p")
            require("codecompanion").setup(opts)
        end,
        opts = {
            adapters = {
                acp = {
                    codex = function()
                        return require("codecompanion.adapters").extend("codex", {
                            commands = {
                                default = codex_command,
                            },
                            defaults = {
                                auth_method = "chat-gpt",
                                mcpServers = "inherit_from_config",
                            },
                            env = {
                                NODE_NO_WARNINGS = "1",
                                -- Keep authentication/configuration in ~/.codex,
                                -- but isolate ACP's live SQLite files from Codex Desktop.
                                CODEX_SQLITE_HOME = codex_sqlite_home,
                            },
                        })
                    end,
                },
            },
            prompt_library = selection_actions.prompt_library(),
            rules = {
                opts = {
                    chat = {
                        autoload_groups_in_prompt_library = true,
                    },
                },
            },
            interactions = {
                chat = {
                    adapter = "codex",
                    slash_commands = {
                        acp_session_options = {
                            keymaps = {
                                modes = { n = "<leader>am" },
                            },
                        },
                        buffer = {
                            keymaps = {
                                modes = { n = "<leader>ab" },
                            },
                            opts = {
                                provider = "fzf_lua",
                            },
                        },
                        fetch = {
                            opts = {
                                provider = "fzf_lua",
                            },
                        },
                        file = {
                            keymaps = {
                                modes = { n = "<leader>af" },
                            },
                            opts = {
                                provider = "fzf_lua",
                            },
                        },
                        help = {
                            keymaps = {
                                modes = { n = "<leader>ah" },
                            },
                            opts = {
                                provider = "fzf_lua",
                            },
                        },
                        image = {
                            keymaps = {
                                modes = { n = "<leader>ap" },
                            },
                            opts = {
                                provider = "snacks",
                            },
                        },
                        mcp = {
                            opts = {
                                provider = "snacks",
                            },
                        },
                        resume = {
                            keymaps = {
                                modes = { n = "<leader>aR" },
                            },
                        },
                        symbols = {
                            keymaps = {
                                modes = { n = "<leader>as" },
                            },
                            opts = {
                                provider = "fzf_lua",
                            },
                        },
                    },
                    keymaps = {
                        -- This default is specific to Copilot and otherwise shadows mini.splitjoin.
                        copilot_stats = false,
                        paste_image = {
                            modes = { n = "<leader>aP" },
                            callback = function()
                                vim.cmd("PasteImage")
                            end,
                            description = "Paste image from clipboard",
                        },
                    },
                    opts = {
                        completion_provider = "blink",
                    },
                },
                code_review = {
                    display = {
                        diff = {
                            provider = open_review_diff,
                        },
                    },
                },
                shared = {
                    keymaps = {
                        -- Keep Vim's `gv` reselect behavior while an approval prompt is active.
                        view_diff = {
                            modes = { n = "<leader>ad" },
                        },
                    },
                },
            },
            display = {
                action_palette = {
                    provider = "snacks",
                    opts = {
                        -- Inline prompt-library entries need an HTTP adapter; show the
                        -- ACP-safe chat replacements defined above instead.
                        show_preset_prompts = false,
                    },
                },
                chat = {
                    start_in_insert_mode = true,
                    -- ACP agents can emit a separate reasoning stream. It adds many
                    -- buffer updates without making code generation faster.
                    show_reasoning = false,
                    window = {
                        layout = "vertical",
                        position = "right",
                        width = 0.4,
                        border = "rounded",
                    },
                },
            },
        },
    },
    {
        "github/copilot.vim",
        cmd = "Copilot",
        event = "InsertEnter",
        init = function()
            vim.g.copilot_no_tab_map = true
        end,
    },
}
