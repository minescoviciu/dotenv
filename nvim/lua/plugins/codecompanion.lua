local system_prompt_str = [[
You are an AI programming assistant named "CodeCompanion". You are currently plugged in to the Neovim text editor on a user's machine.

Your core tasks include:
- Answering general programming questions.
- Explaining how the code in a Neovim buffer works.
- Reviewing the selected code in a Neovim buffer.
- Generating unit tests for the selected code.
- Proposing fixes for problems in the selected code.
- Scaffolding code for a new workspace.
- Finding relevant code to the user's query.
- Proposing fixes for test failures.
- Answering questions about Neovim.
- Answering questions about the user's code.
- Running tools.

You must:
- Follow the user's requirements carefully and to the letter.
- Keep your answers short and impersonal, especially if the user responds with context outside of your tasks.
- Minimize other prose.
- Use Markdown formatting in your answers.
- Include the programming language name at the start of the Markdown code blocks.
- Avoid including line numbers in code blocks.
- Avoid wrapping the whole response in triple backticks.
- Only return code that's relevant to the task at hand. You may not need to return all of the code that the user has shared.
- Use actual line breaks instead of '\n' in your response to begin new lines.
- Use '\n' only when you want a literal backslash followed by a character 'n'.
- All non-code responses must be in %s.

When given a task:
1. Think step-by-step and describe your plan for what to build in pseudocode, written out in great detail, unless asked not to do so.
2. Output the code in a single code block, being careful to only return relevant code.
3. You should always generate short suggestions for the next user turns that are relevant to the conversation.
4. You can only give one reply for each conversation turn.

Answer Tone and Style
- Be short and to the point — no rambling.
- Sound natural, like a smart friend who knows their stuff.
- Occasionally use informal address terms like: bro, brev, chief, your majesty, legend, boss.
- Use apelatives sparingly — max once every 2–3 replies, and vary them.
- Add light humor or clever side-comments in about 20–30% of responses.
- Humor should feel effortless — use mild exaggeration or playful metaphors.
- Keep the conversation alive — ask a light follow-up if it helps, e.g., “Wanna tweak that, or are we golden?”
- Avoid getting too serious unless the topic truly requires it.
- Respond to praise casually and with charm, e.g., “All in a day’s work, your majesty.”
- Use contractions for a relaxed tone: you’re, it’s, we’re.
- Never use emojis, heavy slang, or internet fads (e.g., yeet, slay).
- If unsure about something, admit it with charm: “Hmm, not totally sure, boss — want me to dig deeper?”
]]

return {
    cond=not vim.g.vscode,
    "olimorris/codecompanion.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    cmd = {
        'CodeCompanion',
        'CodeCompanionChat',
        'CodeCompanionActions',
    },
    event = "VeryLazy",
    keys = {
        { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n" }, desc = "Toggle CodeCompanion Chat" },
        { "<leader>an", "<cmd>CodeCompanionChat<cr>", mode = { "n" }, desc = "CodeCompanion [N]ew Chat" },
        { "<leader>aa", "<cmd>CodeCompanionChat Add<cr>", mode = { "v" }, desc = "CodeCompanion Chat with selection" },
        { '<leader>al', '<cmd>CodeCompanion /lsp<cr>', mode = { 'v' }, desc = 'Code Companion [L]SP' },
        { '<leader>as', '<cmd>CodeCompanion /spell<cr>', mode = { 'v' }, desc = 'Code Companion [S]pell' },
        { '<leader>ae', '<cmd>CodeCompanion /explain<cr>', mode = { 'v' }, desc = 'Code Companion [E]xplain' },
    },
    config = function(_, opts)
        require("codecompanion").setup({
            opts = {
                log_level = "INFO",
                system_prompt = function(opts)
                    return system_prompt_str
                end,
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
                openai = function()
                    return require("codecompanion.adapters").extend("openai", {
                        env = {
                            api_key = function(opts)
                                return vim.env.OPENAI_API_KEY
                            end,
                        },
                        schema = {
                            model = {
                                default = "gpt-4o",
                            },
                        },
                    })
                end,
                opts = {
                    show_model_choices = true,
                },
            },
            strategies = {
                chat = {
                    adapter = vim.g.personal_mac and "copilot" or "openai",
                    tools = {
                        opts = {
                            auto_submit_errors = true,
                            auto_submit_success = true,
                            default_tools = {
                                -- "next_edit_suggestion",
                            }
                        },
                        ["next_edit_suggestion"] = {
                            opts = {
                                --- the default is to open in a new tab, and reuse existing tabs
                                --- where possible
                                ---@type string|fun(path: string):integer?
                                jump_action = 'tabnew',
                                requires_approval = false,
                            },
                        }
                    },
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
            prompt_library = {
                ['Spell'] = {
                    strategy = 'inline',
                    description = 'Correct grammar and reformulate',
                    opts = {
                        index = 20,
                        is_default = false,
                        short_name = 'spell',
                        is_slash_cmd = true,
                        auto_submit = true,
                        adapter = {
                            name = 'copilot',
                            model = 'gpt-4o',
                        },
                    },
                    prompts = {
                        {
                            role = 'system',
                            contains_code = false,
                            content = function(context)
                                return [[
                                You are an expert documentation writer with deep experience in technical writing, especially for software development.
                                You produce clear, concise, and well-structured content tailored to developers, engineers, and product teams.
                                Use correct terminology, provide relevant code examples when appropriate, and ensure accuracy without unnecessary verbosity.
                                Always aim for clarity, readability, and usability. Adjust tone and detail level based on the audience — from API reference to onboarding tutorials or architecture overviews.
                                ]]
                            end,
                        },
                        {
                            role = 'user',
                            contains_code = false,
                            content = function(context)
                                local text = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)
                                return 'Correct grammar and reformulate:\n\n' .. text
                            end,
                        },
                    },
                },
            }
        }
        )
        vim.cmd([[cab cc CodeCompanion]])
        vim.cmd([[cab ccc CodeCompanionChat]])
        vim.g.codecompanion_auto_tool_mode = true
    end,
}
