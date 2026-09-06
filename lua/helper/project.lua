local M = {}

-- Resolve from the buffer rather than changing :pwd. Git worktrees use a
-- .git file, so use vim.fs.root instead of assuming .git is a directory.
function M.directory(bufnr)
    bufnr = bufnr or 0
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "" then
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name ~= "" and not name:match("^%a[%w+.-]*://") then
            local directory = vim.fs.dirname(name)
            -- New files can have parents which do not exist yet.
            while directory and vim.fn.isdirectory(directory) ~= 1 do
                local parent = vim.fs.dirname(directory)
                if parent == directory then
                    break
                end
                directory = parent
            end
            if directory and vim.fn.isdirectory(directory) == 1 then
                return directory
            end
        end
    end
    return vim.fn.getcwd()
end

function M.root(bufnr)
    bufnr = bufnr or 0
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return vim.fn.getcwd()
    end
    if
        vim.bo[bufnr].buftype ~= ""
        or vim.api.nvim_buf_get_name(bufnr) == ""
        or vim.api.nvim_buf_get_name(bufnr):match("^%a[%w+.-]*://")
    then
        return vim.fn.getcwd()
    end
    local directory = M.directory(bufnr)
    local home = vim.fs.normalize(vim.uv.os_homedir())
    local start = directory
    local language_root
    local markers = {
        "package.json",
        "pyproject.toml",
        "go.work",
        "go.mod",
        "Cargo.toml",
        "pom.xml",
        "build.gradle",
        "build.gradle.kts",
        "CMakeLists.txt",
        "Makefile",
        ".project-root",
    }
    while directory do
        -- A package.json in the home folder must not absorb unrelated projects.
        if directory:lower() == home:lower() and directory ~= start then
            break
        end
        if vim.uv.fs_stat(vim.fs.joinpath(directory, ".git")) then
            return directory
        end
        if not language_root then
            for _, marker in ipairs(markers) do
                if vim.uv.fs_stat(vim.fs.joinpath(directory, marker)) then
                    language_root = directory
                    break
                end
            end
        end
        local parent = vim.fs.dirname(directory)
        if parent == directory then
            break
        end
        directory = parent
    end
    return language_root or vim.fn.getcwd()
end

return M
