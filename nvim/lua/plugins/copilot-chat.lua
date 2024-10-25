local my_ask = function()
    local chat = require("CopilotChat")
    local selection = require("CopilotChat.select").visual
    local input = vim.fn.input("Ask Copilot: ")
    if input == "" then
        return
    end
    chat.ask(input, {
        selection = selection,
        filetype = vim.bo.filetype,
        filename = vim.fn.expand("%:t"),
    })
end

return {
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "canary",
        dependencies = {
            { "nvim-telescope/telescope.nvim"},
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
            {"<leader>co", "<cmd>CopilotChatToggle<cr>", desc="[C]opilotChat T[O]ggle"},
            {"<leader>ce", "<cmd>CopilotChatExplain<cr>", desc="[C]opilotChat [E]xplain"},
            {"<leader>ce", "<cmd>CopilotChatExplain<cr>", desc="[C]opilotChat [E]xplain", mode="x"},
            {"<leader>cr", "<cmd>CopilotChatReview<cr>", desc="[C]opilotChat [R]eview", mode="x"},
            {"<leader>cd", "<cmd>CopilotChatFixDiagnostic<cr>", desc="[C]opilotChat Fix [D]iagnostic", mode="x"},
            {"<leader>cl", "<cmd>CopilotChatReset<cr>",         desc = "[C]opilotChat C[l]ear buffer and chat history" },
            {"<leader>cc", my_ask, desc = "[C]opilotChat [A]sk"},
            {"<leader>cc", my_ask, desc = "[C]opilotChat [A]sk", mode="x"},
        },
        -- See Commands section for default commands if you want to lazy load on them
    },
}
