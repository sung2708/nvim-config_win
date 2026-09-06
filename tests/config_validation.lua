vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/blink.cmp")
local opts = require("plugins.completion")[1].opts
require("blink.cmp.config").merge_with(opts)
print("PASS installed Blink config validation")
for _, path in ipairs(vim.fn.glob("lua/**/*.lua", false, true)) do
    assert(loadfile(path), path)
end
print("PASS Lua syntax")
