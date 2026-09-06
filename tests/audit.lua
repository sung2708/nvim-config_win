vim.opt.rtp:prepend(vim.fn.getcwd())
vim.g.mapleader = " "
local rows, keys, duplicates = {}, {}, {}
for _, path in ipairs(vim.fn.glob("lua/plugins/*.lua", false, true)) do
    local module = path:gsub("\\", "/"):gsub("^lua/", ""):gsub("%.lua$", ""):gsub("/", ".")
    for _, spec in ipairs(require(module)) do
        if spec.enabled ~= false then
            local mappings = type(spec.keys) == "function" and spec.keys(spec, {}) or spec.keys or {}
            for _, mapping in ipairs(mappings) do
                local modes = type(mapping.mode) == "table" and mapping.mode or { mapping.mode or "n" }
                for _, mode in ipairs(modes) do
                    local lhs = vim.api.nvim_replace_termcodes(
                        mapping[1]:gsub("<leader>", " "):gsub("<space>", " "),
                        true,
                        true,
                        true
                    )
                    for _, expanded in ipairs(mode == "v" and { "x", "s" } or { mode }) do
                        local key = expanded .. lhs
                        if keys[key] then
                            duplicates[#duplicates + 1] = mapping[1] .. ": " .. keys[key] .. " / " .. spec[1]
                        end
                        keys[key] = spec[1]
                    end
                end
            end
            rows[#rows + 1] = {
                plugin = spec[1],
                module = module,
                keys = #mappings,
                activation = spec.event and vim.inspect(spec.event)
                    or spec.ft and vim.inspect(spec.ft)
                    or spec.init and "deferred/custom init"
                    or spec.lazy == false and "startup"
                    or "command/key/dependency",
            }
        end
    end
end
assert(#duplicates == 0, table.concat(duplicates, "\n"))
vim.fn.mkdir(".nvim-data", "p")
vim.fn.writefile({ vim.json.encode(rows) }, ".nvim-data/config-inventory.json")
print(("PASS %d direct plugin specs: no duplicate declared key ownership"):format(#rows))
