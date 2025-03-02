return {
    "olimorris/codecompanion.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    keys = {
        { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n" }, desc = "Toggle CodeCompanion Chat" },
        { "<leader>aa", "<cmd>CodeCompanionChat<cr>",        mode = { "v" }, desc = "Toggle CodeCompanion Chat" },
    },
    config = function(_, opts)
        require("codecompanion").setup({
            opts = {
                log_level = "INFO",
            },
            adapters = {
                copilot = require("codecompanion.adapters").extend("copilot", {
                    schema = {
                        model = {
                            default = "claude-3.5-sonnet",
                        },
                    },
                }),
            },
            strategies = {
                chat = {
                    adapter = "copilot",
                },
                inline = {
                    adapter = "copilot",
                },
                agent = {
                    adapter = "copilot",
                },
            },
            chat = {
                slash_commands = {
                    ["file"] = {
                        -- Location to the slash command in CodeCompanion
                        callback = "strategies.chat.slash_commands.file",
                        description = "Select a file using Snacks",
                        opts = {
                            provider = "snacks", -- Other options include 'default', 'mini_pick', 'fzf_lua', snacks
                            contains_code = true,
                        },
                    },
                    ['buffer'] = {
                        opts = {
                            provider = 'snacks',
                        },
                    },
                },
            },

        }
        )
        vim.cmd([[cab cc CodeCompanion]])
    end,
}
