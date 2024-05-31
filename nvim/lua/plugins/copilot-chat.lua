return {
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "canary",
        dependencies = {
            { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
            { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
        },
        opts = {
            debug = false, -- Enable debugging
            show_help = false,
            window = {
                width = 0.7, -- Width of the window
                height = 0.7, -- Height of the window
                border = "single", -- Border of the window
                layout = "float",
            },
            -- See Configuration section for rest
        },
        keys = {
            {"<leader>ct", "<cmd>CopilotChatToggle<cr>", desc="[C]opilotChat [T]ogle"},
            {"<leader>ce", "<cmd>CopilotChatExplain<cr>", desc="[C]opilotChat [E]xplain"},
            {"<leader>ce", "<cmd>CopilotChatExplain<cr>", desc="[C]opilotChat [E]xplain", mode="x"},
        },
        -- See Commands section for default commands if you want to lazy load on them
    },
}
