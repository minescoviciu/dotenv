return {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
        'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
    event = "VeryLazy",
    config = function ()

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "rust",
            callback = function()
                if not vim.b.ts_highlight then
                    vim.cmd("TSBufEnable highlight")
                end
            end,
        })
        -- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
        vim.defer_fn(function()
            -- See `:help nvim-treesitter`
            require('nvim-treesitter.configs').setup({
                -- Add languages to be installed here that you want installed for treesitter
                ensure_installed = { 'c', 'cpp', 'go', 'python', 'rust', 'lua', 'tsx', 'javascript', 'typescript', 'vimdoc', 'vim', 'bash', "tsx", "css" },

                autotag = {
                    enable = true,
                },
                -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
                auto_install = false,

                highlight = { enable = true },
                indent = { enable = true },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = '<c-space>',
                        node_incremental = '<c-space>',
                        scope_incremental = '<c-s>',
                        node_decremental = '<M-space>',
                    },
                },
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                        keymaps = {
                            -- You can use the capture groups defined in textobjects.scm
                            ['aa'] = '@parameter.outer',
                            ['ia'] = '@parameter.inner',
                            ['af'] = '@function.outer',
                            ['if'] = '@function.inner',
                            ['ac'] = '@class.outer',
                            ['ic'] = '@class.inner',
                        },
                    },
                    move = {
                        enable = true,
                        set_jumps = true, -- whether to set jumps in the jumplist
                        goto_next_start = {
                            [']m'] = '@function.outer',
                            [']]'] = '@class.outer',
                        },
                        goto_next_end = {
                            [']M'] = '@function.outer',
                            [']['] = '@class.outer',
                        },
                        goto_previous_start = {
                            ['[m'] = '@function.outer',
                            ['[['] = '@class.outer',
                        },
                        goto_previous_end = {
                            ['[M'] = '@function.outer',
                            ['[]'] = '@class.outer',
                        },
                    },
                    swap = {
                        enable = true,
                        swap_next = {
                            ['<leader>p'] = '@parameter.inner',
                        },
                        swap_previous = {
                            ['<leader>P'] = '@parameter.inner',
                        },
                    },
                },
            })
        end, 0)

        -- Diagnostic keymaps
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
        vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
    end
}

