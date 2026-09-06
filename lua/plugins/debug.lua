return {
    {
        "mfussenegger/nvim-dap",
        keys = {
            { "<F5>", desc = "Debug: Continue" },
            { "<F10>", desc = "Debug: Step Over" },
            { "<F11>", desc = "Debug: Step Into" },
            { "<F12>", desc = "Debug: Step Out" },
            { "<leader>db", desc = "Debug: Toggle Breakpoint" },
            { "<leader>dB", desc = "Debug: Conditional Breakpoint" },
            { "<leader>dr", desc = "Debug: Open REPL" },
            { "<leader>dl", desc = "Debug: Run Last" },
            { "<leader>du", desc = "Debug: Toggle UI" },
        },
        dependencies = {
            "nvim-neotest/nvim-nio",
            "rcarriga/nvim-dap-ui",
            "theHamsta/nvim-dap-virtual-text",
            "mason-org/mason.nvim",
            "jay-babu/mason-nvim-dap.nvim",
            "leoluz/nvim-dap-go",
        },
        config = function()
            require("integrations.dap")
        end,
    },
    {
        "nvim-neotest/neotest",
        cmd = "NeotestSummary",
        keys = {
            { "<leader>nd", desc = "Test: Debug Nearest" },
            { "<leader>nD", desc = "Test: Debug File" },
            { "<leader>nt", desc = "Test: Nearest" },
            { "<leader>nf", desc = "Test: File" },
            { "<leader>nT", desc = "Test: Project" },
            { "<leader>ns", desc = "Test: Summary" },
            { "<leader>no", desc = "Test: Output" },
            { "<leader>nO", desc = "Test: Output Panel" },
            { "<leader>nw", desc = "Test: Watch" },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-neotest/nvim-nio",
            "nvim-treesitter/nvim-treesitter",
            "nvim-neotest/neotest-python",
            "nvim-neotest/neotest-jest",
            "fredrikaverpil/neotest-golang",
            "rcasia/neotest-java",
        },
        config = function()
            require("integrations.neotest")
        end,
    },
}
