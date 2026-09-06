local M = {}

-- CodeCompanion's ACP handler writes each streamed chunk directly to the chat
-- buffer. Avoid asking render-markdown to rebuild decorations for every chunk;
-- restore the rendered view as soon as the request finishes.
local streaming_render_group = vim.api.nvim_create_augroup("SungpCodeCompanionStreaming", { clear = true })

local function chat_bufnr_from_event(args)
    local data = args.data
    local bufnr = type(data) == "table" and data.bufnr or nil

    if
        type(bufnr) ~= "number"
        or data.interaction ~= "chat"
        or not vim.api.nvim_buf_is_valid(bufnr)
        or vim.bo[bufnr].filetype ~= "codecompanion"
    then
        return nil
    end

    return bufnr
end

local function markdown_renderer_for(bufnr, allow_disabled)
    -- Do not load render-markdown just for a chat request. If it is active for
    -- this buffer, however, it is the most expensive part of token streaming.
    if not package.loaded["render-markdown"] then
        return nil
    end

    local ok, manager = pcall(require, "render-markdown.core.manager")
    if not ok or not manager.attached(bufnr) then
        return nil
    end

    local renderer = require("render-markdown")
    local state = require("render-markdown.state")
    if not allow_disabled and not state.get(bufnr).enabled then
        return nil
    end

    return renderer
end

local function disable_markdown_while_streaming(args)
    local bufnr = chat_bufnr_from_event(args)
    if not bufnr or vim.b[bufnr].codecompanion_markdown_suspended then
        return
    end

    local renderer = markdown_renderer_for(bufnr)
    if not renderer then
        return
    end

    vim.b[bufnr].codecompanion_markdown_suspended = true
    vim.api.nvim_buf_call(bufnr, function()
        renderer.buf_disable()
    end)
end

local function restore_markdown_after_streaming(args)
    local bufnr = chat_bufnr_from_event(args)
    if not bufnr or not vim.b[bufnr].codecompanion_markdown_suspended then
        return
    end

    vim.b[bufnr].codecompanion_markdown_suspended = nil
    local renderer = markdown_renderer_for(bufnr, true)
    if not renderer then
        return
    end

    vim.api.nvim_buf_call(bufnr, function()
        renderer.buf_enable()
    end)
end

vim.api.nvim_create_autocmd("User", {
    group = streaming_render_group,
    pattern = "CodeCompanionRequestStreaming",
    callback = disable_markdown_while_streaming,
})

vim.api.nvim_create_autocmd("User", {
    group = streaming_render_group,
    pattern = "CodeCompanionRequestFinished",
    callback = restore_markdown_after_streaming,
})

local function code_fence(context)
    return string.format("````%s\n%s\n````", context.filetype, context.code or "")
end

local function notify_missing_selection()
    vim.notify("Select code first, then run a CodeCompanion selection action", vim.log.levels.WARN)
end

local function selection_context()
    local context = require("codecompanion.utils.context").get(0, { range = 1 })

    if not context.is_visual or type(context.code) ~= "string" or vim.trim(context.code) == "" then
        notify_missing_selection()
        return nil
    end

    return context
end

local function resolve_prompt(alias, context)
    local action_palette = require("codecompanion.action_palette")
    local prompt = action_palette.resolve_from_alias(alias, context)

    if not prompt then
        vim.notify("CodeCompanion prompt is unavailable: " .. alias, vim.log.levels.ERROR)
        return
    end

    return action_palette.resolve(prompt, context)
end

local function submit_when_ready(chat)
    if chat.adapter.type ~= "acp" then
        chat:submit()
        return
    end

    local attempts = 0
    local max_attempts = 400

    local function try_submit()
        if not vim.api.nvim_buf_is_valid(chat.bufnr) or chat.current_request then
            return
        end

        local connection = chat.acp_connection
        if connection and connection:is_connected() then
            chat:submit()
            return
        end

        attempts = attempts + 1
        if attempts >= max_attempts then
            vim.notify(
                "Codex ACP chưa sẵn sàng để gửi câu hỏi. Kiểm tra :messages, rồi nhấn <CR> trong chat.",
                vim.log.levels.ERROR
            )
            return
        end

        vim.defer_fn(try_submit, 50)
    end

    try_submit()
end

local function start_chat(context, prompt)
    return require("codecompanion").chat({
        context = context,
        user_prompt = prompt,
        -- ACP connects asynchronously. Calling auto_submit here can send the
        -- prompt before Codex has created its session, leaving the chat idle.
        auto_submit = false,
        callbacks = {
            on_created = submit_when_ready,
        },
    })
end

local function ask_with_nui(context)
    local Input = require("nui.input")
    local event = require("nui.utils.autocmd").event
    local input

    input = Input({
        relative = "editor",
        position = "50%",
        size = {
            width = math.min(72, math.max(42, math.floor(vim.o.columns * 0.6))),
        },
        border = {
            style = "rounded",
            text = {
                top = " Ask selected code ",
                top_align = "center",
            },
        },
        -- Match the editor surface instead of introducing a separate NUI float
        -- background. The highlight groups follow the active colorscheme.
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:WinSeparator",
        },
    }, {
        prompt = "󰚩  ",
        default_value = "",
        on_submit = function(value)
            local prompt = vim.trim(value)
            if prompt == "" then
                return
            end

            vim.schedule(function()
                start_chat(context, prompt)
            end)
        end,
    })

    input:map("i", "<Esc>", function()
        input:unmount()
    end, { noremap = true, nowait = true })
    input:map("n", "<Esc>", function()
        input:unmount()
    end, { noremap = true, nowait = true })
    input:on(event.BufLeave, function()
        input:unmount()
    end, { once = true })
    input:mount()
end

local function selection_diagnostics(context)
    local diagnostics =
        require("codecompanion.helpers.code").get_diagnostics(context.start_line, context.end_line, context.bufnr)

    if #diagnostics == 0 then
        return "There are no LSP diagnostics in this selection. Review the code for likely issues anyway:\n\n"
            .. code_fence(context)
    end

    local items = {}
    for index, diagnostic in ipairs(diagnostics) do
        table.insert(
            items,
            string.format(
                "%d. Line %s (%s): %s",
                index,
                diagnostic.line_number,
                diagnostic.severity,
                diagnostic.message
            )
        )
    end

    return "Explain these LSP diagnostics and show focused fixes for the selected code:\n\n"
        .. table.concat(items, "\n")
        .. "\n\n"
        .. code_fence(context)
end

local function staged_diff()
    -- Prompt content is resolved synchronously by CodeCompanion. Bound the
    -- subprocess and use the project being edited, rather than unrelated CWD.
    local result = vim.system({ "git", "diff", "--no-ext-diff", "--staged" }, {
        text = true,
        cwd = require("helper.project").root(),
    }):wait(1500)
    local diff = result.stdout or ""

    if result.code ~= 0 then
        return "Git could not read the staged diff. Explain the error and ask for the next step:\n\n"
            .. (result.stderr or "")
    end

    if vim.trim(diff) == "" then
        return "There are no staged changes. Ask the user to stage the intended changes before generating a commit message."
    end

    return "Generate a concise Conventional Commit message for this staged diff:\n\n````diff\n" .. diff .. "\n````"
end

function M.run_selection_prompt(alias)
    local context = selection_context()
    if context then
        return resolve_prompt(alias, context)
    end
end

function M.ask_selection()
    local context = selection_context()
    if context then
        ask_with_nui(context)
    end
end

function M.selection_menu()
    local context = selection_context()
    if not context then
        return
    end

    local Menu = require("nui.menu")
    local event = require("nui.utils.autocmd").event
    local handlers = {
        ask = function()
            ask_with_nui(context)
        end,
        explain = function()
            resolve_prompt("explain", context)
        end,
        fix = function()
            resolve_prompt("fix", context)
        end,
        diagnostics = function()
            resolve_prompt("lsp", context)
        end,
        tests = function()
            resolve_prompt("tests_chat", context)
        end,
        refactor = function()
            resolve_prompt("refactor_selection", context)
        end,
        document = function()
            resolve_prompt("document_selection", context)
        end,
        workflow = function()
            resolve_prompt("selection_workflow", context)
        end,
    }
    local menu

    menu = Menu({
        relative = "editor",
        position = "50%",
        border = {
            style = "rounded",
            text = {
                top = " Selected code ",
                top_align = "center",
            },
        },
        -- Keep the selection colour, while the popup itself inherits the
        -- editor's background and colorscheme-defined separators.
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:WinSeparator,CursorLine:PmenuSel",
        },
    }, {
        lines = {
            Menu.separator("Ask / understand"),
            Menu.item("Ask…", { action = "ask" }),
            Menu.item("Explain", { action = "explain" }),
            Menu.item("Explain diagnostics", { action = "diagnostics" }),
            Menu.separator("Improve"),
            Menu.item("Fix", { action = "fix" }),
            Menu.item("Refactor", { action = "refactor" }),
            Menu.item("Generate tests", { action = "tests" }),
            Menu.item("Document", { action = "document" }),
            Menu.separator("Multi-step"),
            Menu.item("Code workflow", { action = "workflow" }),
        },
        max_width = 42,
        keymap = {
            close = { "<Esc>", "<C-c>" },
            focus_next = { "j", "<Down>", "<Tab>" },
            focus_prev = { "k", "<Up>", "<S-Tab>" },
            submit = { "<CR>", "<Space>" },
        },
        on_submit = function(item)
            local handler = handlers[item.action]
            if handler then
                vim.schedule(handler)
            end
        end,
    })

    menu:on(event.BufLeave, function()
        menu:unmount()
    end, { once = true })
    menu:mount()
end

function M.prompt_library()
    return {
        ["Explain selection"] = {
            interaction = "chat",
            description = "Explain the selected code",
            opts = {
                alias = "explain",
                auto_submit = true,
                index = 10,
                modes = { "v" },
                stop_context_insertion = true,
            },
            prompts = {
                {
                    role = "system",
                    content = "Explain code clearly, covering its purpose, control flow, inputs, outputs, and notable trade-offs.",
                },
                {
                    role = "user",
                    content = function(context)
                        return "Explain this selected code:\n\n" .. code_fence(context)
                    end,
                },
            },
        },
        ["Fix selection"] = {
            interaction = "chat",
            description = "Find and fix issues in the selected code",
            opts = {
                alias = "fix",
                auto_submit = true,
                index = 20,
                modes = { "v" },
                stop_context_insertion = true,
            },
            prompts = {
                {
                    role = "system",
                    content = "Identify issues, outline a focused fix, then provide corrected code and a short explanation. Preserve intended public behavior.",
                },
                {
                    role = "user",
                    content = function(context)
                        return "Fix this selected code:\n\n" .. code_fence(context)
                    end,
                },
            },
        },
        ["Explain selection diagnostics"] = {
            interaction = "chat",
            description = "Explain LSP diagnostics for the selected code",
            opts = {
                alias = "lsp",
                auto_submit = true,
                index = 30,
                modes = { "v" },
                stop_context_insertion = true,
            },
            prompts = {
                {
                    role = "system",
                    content = "Explain diagnostics precisely and recommend minimal, safe fixes with code when useful.",
                },
                {
                    role = "user",
                    content = selection_diagnostics,
                },
            },
        },
        ["Generate tests (chat)"] = {
            interaction = "chat",
            description = "Generate unit tests for the selected code",
            opts = {
                alias = "tests_chat",
                auto_submit = true,
                index = 40,
                modes = { "v" },
                stop_context_insertion = true,
            },
            prompts = {
                {
                    role = "system",
                    content = "Write practical, maintainable unit tests. Choose the project-appropriate test framework and cover ordinary, edge, and failure cases.",
                },
                {
                    role = "user",
                    content = function(context)
                        return "Plan and generate tests for this selected code. State the test plan briefly, then provide the tests:\n\n"
                            .. code_fence(context)
                    end,
                },
            },
        },
        ["Refactor selection"] = {
            interaction = "chat",
            description = "Propose a focused refactor for the selected code",
            opts = {
                alias = "refactor_selection",
                auto_submit = true,
                index = 50,
                modes = { "v" },
                stop_context_insertion = true,
            },
            prompts = {
                {
                    role = "system",
                    content = "Recommend focused refactors that improve clarity, correctness, or maintainability without changing intended behavior. Call out risks before showing code.",
                },
                {
                    role = "user",
                    content = function(context)
                        return "Review and refactor this selected code:\n\n" .. code_fence(context)
                    end,
                },
            },
        },
        ["Document selection"] = {
            interaction = "chat",
            description = "Write documentation for the selected code",
            opts = {
                alias = "document_selection",
                auto_submit = true,
                index = 60,
                modes = { "v" },
                stop_context_insertion = true,
            },
            prompts = {
                {
                    role = "system",
                    content = "Write concise documentation in the style appropriate to the source language. Cover purpose, inputs, outputs, errors, and side effects when relevant.",
                },
                {
                    role = "user",
                    content = function(context)
                        return "Document this selected code:\n\n" .. code_fence(context)
                    end,
                },
            },
        },
        ["Selection code workflow"] = {
            interaction = "workflow",
            description = "Review, improve, and verify the selected code in three chat turns",
            opts = {
                alias = "selection_workflow",
                index = 70,
                is_workflow = true,
                modes = { "v" },
                stop_context_insertion = true,
            },
            prompts = {
                {
                    {
                        role = "system",
                        content = "You are a careful software engineer. Give precise, actionable feedback and preserve intended behavior.",
                    },
                    {
                        role = "user",
                        content = function(context)
                            return "Review this selected code for correctness, clarity, edge cases, and maintainability:\n\n"
                                .. code_fence(context)
                        end,
                        opts = {
                            auto_submit = true,
                        },
                    },
                },
                {
                    {
                        role = "user",
                        content = "Now propose a focused implementation plan that addresses the highest-value findings.",
                        opts = {
                            auto_submit = true,
                        },
                    },
                },
                {
                    {
                        role = "user",
                        content = "Now provide the revised code and concise verification guidance.",
                        opts = {
                            auto_submit = true,
                        },
                    },
                },
            },
        },
        ["Commit message"] = {
            interaction = "chat",
            description = "Generate a Conventional Commit message from staged changes",
            opts = {
                alias = "commit",
                auto_submit = false,
                index = 80,
                is_slash_cmd = true,
                modes = { "n" },
                stop_context_insertion = true,
            },
            prompts = {
                {
                    role = "user",
                    content = staged_diff,
                },
            },
        },
    }
end

return M
