local M = {}

local group = vim.api.nvim_create_augroup("SungpJava", { clear = true })

local function mason_package(name)
    return vim.fn.stdpath("data") .. "/mason/packages/" .. name
end

local function add_glob(target, pattern)
    local matches = vim.split(vim.fn.glob(pattern), "\n", { trimempty = true })
    for _, path in ipairs(matches) do
        if not vim.tbl_contains(target, path) then
            table.insert(target, path)
        end
    end
end

local function java_bundles()
    local bundles = {}
    local debug_root = mason_package("java-debug-adapter")

    add_glob(bundles, debug_root .. "/extension/server/com.microsoft.java.debug.plugin-*.jar")
    add_glob(bundles, debug_root .. "/com.microsoft.java.debug.plugin-*.jar")

    return bundles
end

local function root_dir(bufnr)
    return vim.fs.root(bufnr, {
        "gradlew",
        "mvnw",
        "pom.xml",
        "build.gradle",
        "build.gradle.kts",
        "settings.gradle",
        "settings.gradle.kts",
        ".git",
    }) or vim.fn.getcwd()
end

local function jdtls_command()
    local command = vim.fn.exepath("jdtls")
    if command ~= "" then
        return { command }
    end

    local script = mason_package("jdtls") .. "/bin/jdtls"
    local python = vim.fn.exepath("python3")
    if python == "" then
        python = vim.fn.exepath("python")
    end

    if python ~= "" and vim.fn.filereadable(script) == 1 then
        return { python, script }
    end
end

local function map_java(bufnr)
    local function map(lhs, rhs, desc, mode)
        vim.keymap.set(mode or "n", lhs, rhs, {
            buffer = bufnr,
            silent = true,
            desc = "Java: " .. desc,
        })
    end

    map("<leader>Jo", function()
        require("jdtls").organize_imports()
    end, "Organize Imports")
    map("<leader>Jv", function()
        require("jdtls").extract_variable()
    end, "Extract Variable")
    map("<leader>Jv", function()
        require("jdtls").extract_variable(true)
    end, "Extract Variable", "v")
    map("<leader>Jc", function()
        require("jdtls").extract_constant()
    end, "Extract Constant")
    map("<leader>Jc", function()
        require("jdtls").extract_constant(true)
    end, "Extract Constant", "v")
    map("<leader>Jm", function()
        require("jdtls").extract_method(true)
    end, "Extract Method", "v")

    local function run_test(target)
        require("lazy").load({ plugins = { "neotest" } })
        require("neotest").run.run(target)
    end

    map("<leader>Jt", function()
        run_test()
    end, "Test Nearest")
    map("<leader>JT", function()
        run_test(vim.api.nvim_buf_get_name(bufnr))
    end, "Test File")
    map("<leader>Ju", "<cmd>JdtUpdateConfig<cr>", "Update Project Config")
end

local function start(bufnr)
    if
        not vim.api.nvim_buf_is_valid(bufnr)
        or vim.b[bufnr].bigfile
        or vim.bo[bufnr].buftype ~= ""
        or vim.bo[bufnr].filetype ~= "java"
    then
        return
    end

    local command = jdtls_command()
    if not command then
        vim.notify(
            "jdtls is not installed yet. Run :MasonToolsInstall, then reopen the Java file.",
            vim.log.levels.WARN
        )
        return
    end

    local root = root_dir(bufnr)
    local workspace = vim.fn.stdpath("data") .. "/jdtls-workspaces/v2/" .. vim.fn.sha256(root):sub(1, 16)
    vim.fn.mkdir(workspace, "p")

    local lombok = mason_package("jdtls") .. "/lombok.jar"
    if vim.fn.filereadable(lombok) == 1 then
        table.insert(command, "--jvm-arg=-javaagent:" .. lombok)
    end
    vim.list_extend(command, { "-data", workspace })

    local config = {
        name = "jdtls",
        cmd = command,
        root_dir = root,
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        settings = {
            java = {
                eclipse = {
                    downloadSources = true,
                },
                configuration = {
                    updateBuildConfiguration = "interactive",
                },
                implementationsCodeLens = {
                    enabled = true,
                },
                inlayHints = {
                    parameterNames = {
                        enabled = "all",
                    },
                },
                maven = {
                    downloadSources = true,
                },
                referencesCodeLens = {
                    enabled = true,
                },
                signatureHelp = {
                    enabled = true,
                },
            },
        },
        init_options = {
            bundles = java_bundles(),
        },
        on_attach = function(_, attached_bufnr)
            map_java(attached_bufnr)
            local jdtls = require("jdtls")
            pcall(jdtls.setup_dap, { hotcodereplace = "auto" })
            local ok_dap, jdtls_dap = pcall(require, "jdtls.dap")
            if ok_dap then
                pcall(jdtls_dap.setup_dap_main_class_configs)
            end
        end,
    }

    require("jdtls").start_or_attach(config)
end

function M.setup()
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "java",
        callback = function(args)
            start(args.buf)
        end,
    })

    local bufnr = vim.api.nvim_get_current_buf()
    vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_call(bufnr, function()
                start(bufnr)
            end)
        end
    end)
end

return M
