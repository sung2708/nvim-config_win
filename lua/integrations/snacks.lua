local M = require("helper.utils")
local snacks = M.safe_require("snacks")

if snacks then
    local function dashboard_header()
        local lines = {
            "███████╗██╗   ██╗███╗   ██╗ ██████╗ ██████╗",
            "██╔════╝██║   ██║████╗  ██║██╔════╝ ██╔══██╗",
            "███████╗██║   ██║██╔██╗ ██║██║  ███╗██████╔╝",
            "╚════██║██║   ██║██║╚██╗██║██║   ██║██╔═══╝",
            "███████║╚██████╔╝██║ ╚████║╚██████╔╝██║",
            "╚══════╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝",
        }
        local width = 0

        for _, line in ipairs(lines) do
            width = math.max(width, vim.fn.strdisplaywidth(line))
        end
        for index, line in ipairs(lines) do
            lines[index] = line .. string.rep(" ", width - vim.fn.strdisplaywidth(line))
        end

        return table.concat(lines, "\n")
    end

    local function dashboard_pick(cmd, opts)
        local fzf = require("fzf-lua")
        local fzf_actions = require("fzf-lua.actions")
        local fzf_path = require("fzf-lua.path")
        local fzf_utils = require("fzf-lua.utils")

        opts = vim.tbl_deep_extend("force", opts or {}, {
            actions = {
                ["enter"] = {
                    -- Keep the picker visible while the selected buffer is
                    -- loaded underneath it, then close it. This avoids a
                    -- one-frame redraw of the dashboard on confirmation.
                    fn = function(selected, picker_opts)
                        local fzf_win = fzf_utils.fzf_winobj()
                        local source_win = fzf_win and fzf_win.src_winid
                        local ok, err

                        vim.cmd.stopinsert()
                        if #selected == 1 and source_win and vim.api.nvim_win_is_valid(source_win) then
                            local entry = fzf_path.entry_to_file(selected[1], picker_opts, picker_opts._uri)
                            local bufnr = entry.bufnr

                            if not (bufnr and vim.api.nvim_buf_is_valid(bufnr)) then
                                local path = entry.bufname or entry.path
                                if path and not fzf_path.is_absolute(path) then
                                    path = fzf_path.join({
                                        picker_opts.cwd or picker_opts._cwd or fzf_utils.cwd(),
                                        path,
                                    })
                                end
                                bufnr = path and vim.fn.bufadd(fzf_path.normalize(path)) or nil
                            end

                            ok, err = pcall(function()
                                assert(bufnr and bufnr ~= 0, "Unable to resolve selected file")
                                vim.bo[bufnr].buflisted = true
                                vim.api.nvim_set_current_win(source_win)
                                -- :buffer runs the swap recovery dialog; the buffer API does not.
                                local opened, open_err = pcall(vim.cmd.buffer, bufnr)
                                if not opened then
                                    if open_err == "Keyboard interrupt" then
                                        return
                                    end
                                    -- E325 is reported even after a successful recovery choice.
                                    if not tostring(open_err):match("^Vim:E325:") then
                                        error(open_err)
                                    end
                                end
                                if vim.api.nvim_win_get_buf(source_win) ~= bufnr then
                                    return
                                end

                                if entry.line and entry.line > 0 then
                                    vim.api.nvim_win_set_cursor(source_win, {
                                        entry.line,
                                        math.max(0, (entry.col or 1) - 1),
                                    })
                                    vim.cmd("normal! zvzz")
                                end
                            end)
                        else
                            if fzf_win then
                                fzf_win:close()
                                fzf_win = nil
                            end
                            ok, err = pcall(fzf_actions.file_edit_or_qf, selected, picker_opts)
                        end

                        if fzf_win then
                            fzf_win:close()
                        end
                        if fzf_utils.fzf_winobj() == nil then
                            fzf_utils.clear_CTX()
                        end
                        if not ok then
                            error(err)
                        end
                    end,
                    noclose = true,
                },
            },
        })

        return fzf[cmd](opts)
    end

    local dashboard_chrome

    local function hide_dashboard_chrome(refresh)
        if refresh or not dashboard_chrome then
            dashboard_chrome = {
                laststatus = vim.o.laststatus,
                showtabline = vim.o.showtabline,
            }
        end
        vim.o.laststatus = 0
        vim.o.showtabline = 0
    end

    local function restore_dashboard_chrome()
        if not dashboard_chrome then
            return
        end
        vim.o.laststatus = dashboard_chrome.laststatus
        vim.o.showtabline = dashboard_chrome.showtabline
        dashboard_chrome = nil
    end

    snacks.setup({
        bigfile = {
            -- bigfile.nvim handles this before BufRead to avoid duplicate
            -- detection and conflicting buffer-local state.
            enabled = false,
        },
        quickfile = { enabled = true },
        dashboard = {
            -- Avoid rendering a large dashboard on startup; it remains easy
            -- to re-enable locally when this profile is not needed.
            enabled = not vim.g.sungp_low_spec,
            width = 58,
            row = nil,
            col = nil,
            pane_gap = 2,
            preset = {
                header = dashboard_header(),
                pick = dashboard_pick,
                keys = {
                    {
                        icon = " ",
                        key = "f",
                        desc = "Find File",
                        action = function()
                            Snacks.dashboard.pick("files")
                        end,
                    },
                    {
                        icon = "󰱼 ",
                        key = "g",
                        desc = "Live Grep",
                        action = function()
                            Snacks.dashboard.pick("live_grep")
                        end,
                    },
                    {
                        icon = "󰈚 ",
                        key = "b",
                        desc = "Buffers",
                        action = function()
                            Snacks.dashboard.pick("buffers")
                        end,
                    },
                    { icon = "󰉋 ", key = "e", desc = "File Explorer", action = ":Neotree filesystem reveal left" },
                    { icon = "󰊢 ", key = "s", desc = "Git Status", action = ":Git" },
                    { icon = "󰦓 ", key = "d", desc = "Diff View", action = ":DiffviewOpen" },
                    { icon = "󰒡 ", key = "x", desc = "Diagnostics", action = ":Trouble diagnostics toggle" },
                    { icon = "󰙨 ", key = "t", desc = "Test Summary", action = ":NeotestSummary" },
                    {
                        icon = " ",
                        key = "c",
                        desc = "Config",
                        action = function()
                            Snacks.dashboard.pick("files", { cwd = vim.fn.stdpath("config") })
                        end,
                    },
                    { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                    { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                },
            },
            sections = {
                -- Keep the blank row below the header on the header itself.
                -- Snacks positions an item's cursor on its first rendered
                -- line, which would otherwise be the keys section's padding.
                { section = "header", padding = { 2, 2 } },
                { section = "keys", gap = 1 },
                {
                    icon = " ",
                    title = "Recent Files",
                    section = "recent_files",
                    limit = 4,
                    indent = 1,
                    padding = { 1, 1 },
                },
                {
                    icon = " ",
                    title = "Git Status",
                    section = "terminal",
                    enabled = function()
                        return snacks.git.get_root() ~= nil
                    end,
                    cmd = "git status --short --branch --renames",
                    height = 5,
                    padding = { 1, 0 },
                    ttl = 60,
                    indent = 1,
                },
            },
        },
        picker = {
            ui_select = true,
            sources = {
                files = {
                    cmd = "fd",
                    hidden = false,
                    ignored = false,
                    exclude = { "node_modules", "dist", "build", "target", ".next", "coverage" },
                },
            },
        },
    })

    local dashboard_group = vim.api.nvim_create_augroup("SungpDashboardChrome", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = dashboard_group,
        pattern = "SnacksDashboardOpened",
        callback = function()
            hide_dashboard_chrome()
        end,
    })
    vim.api.nvim_create_autocmd("User", {
        group = dashboard_group,
        pattern = "SnacksDashboardClosed",
        callback = restore_dashboard_chrome,
    })
    vim.api.nvim_create_autocmd("User", {
        group = dashboard_group,
        pattern = "VeryLazy",
        callback = function()
            if vim.bo.filetype == "snacks_dashboard" then
                -- Bufferline and Lualine finish their setup earlier in this
                -- event. Hide their global UI before Neovim renders again.
                -- Scheduling this leaves one visible tabline frame.
                hide_dashboard_chrome(true)
            end
        end,
    })

    vim.keymap.set("n", "<leader>sd", function()
        snacks.dashboard()
    end, { desc = "Dashboard: Open" })
end
