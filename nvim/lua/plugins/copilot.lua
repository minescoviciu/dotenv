return {
    cond=not vim.g.vscode,
    "zbirenbaum/copilot.lua",
    event = "VeryLazy",
    config = function()
        require('copilot').setup({
            panel = {
                enabled = false,
                auto_refresh = false,
                keymap = {
                    jump_prev = "[[",
                    jump_next = "]]",
                    accept = "<CR>",
                    refresh = "gr",
                    open = "<M-CR>"
                },
                layout = {
                    position = "bottom", -- | top | left | right
                    ratio = 0.4
                },
            },
            suggestion = {
                enabled = true,
                auto_trigger = true,
                debounce = 75,
                keymap = {
                    -- accept = "<tab>",
                    accept_word = false,
                    accept_line = false,
                    next = "<M-]>",
                    prev = "<M-[>",
                    dismiss = "<C-]>",
                },
            },
            filetypes = {
                yaml = true,
                markdown = false,
                help = false,
                gitcommit = false,
                gitrebase = false,
                hgcommit = false,
                svn = false,
                cvs = false,
                ["."] = false,
            },
            copilot_node_command = 'node', -- Node.js version must be > 18.x
            server_opts_overrides = {},
        })
        vim.keymap.set('i', '<Tab>', function()
            if require('copilot.suggestion').is_visible() then
                require('copilot.suggestion').accept()
            else
                -- Insert a normal Tab if no suggestion is visible
                return "<Tab>"
            end
        end, { expr = true, desc = "Accept Copilot suggestion or normal Tab" })
    end
}

