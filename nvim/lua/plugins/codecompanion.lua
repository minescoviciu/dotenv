return {
    cond=not vim.g.vscode,
    "olimorris/codecompanion.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    keys = {
        { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n" }, desc = "Toggle CodeCompanion Chat" },
        { "<leader>ae", "<cmd>CodeCompanionChat<cr>", mode = { "n" }, desc = "CodeCompanion New Chat" },
    },
    config = function(_, opts)
        require("codecompanion").setup({
            opts = {
                log_level = "INFO",
            },
            display = {
                action_palette = {
                    width = 95,
                    height = 10,
                    prompt = "> ", -- Prompt used for interactive LLM calls
                    provider = "snacks", -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks". If not specified, the plugin will autodetect installed providers.
                    opts = {
                        show_default_actions = true, -- Show the default actions in the action palette?
                        show_default_prompt_library = true, -- Show the default prompt library in the action palette?
                    },
                },
            },
            adapters = {
                copilot = require("codecompanion.adapters").extend("copilot", {
                    schema = {
                        model = {
                            default = "claude-3.7-sonnet",
                        },
                    },
                }),
                opts = {
                    show_model_choices = true,
                },
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
