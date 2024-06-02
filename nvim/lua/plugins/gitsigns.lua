-- Adds git related signs to the gutter, as well as utilities for managing changes
local M = {
    'lewis6991/gitsigns.nvim',
    opts = {
        -- See `:help gitsigns.txt`
        signs = {
            add          = { text = '+' },
            change       = { text = '~' },
            delete       = { text = '_' },
            topdelete    = { text = '‾' },
            changedelete = { text = '~' },
            untracked    = { text = '┆' },
        },
        on_attach = function(bufnr)
            local gs = package.loaded.gitsigns
            vim.keymap.set('n', '<leader>hp', gs.preview_hunk, { buffer = bufnr, desc = '[H]unk [P]review' })
            vim.keymap.set('n', '<leader>hb', function() gs.blame_line({full=true}) end, { desc = '[H]unk [B]lame' })
            vim.keymap.set('n', '<leader>hr', gs.reset_hunk, { desc = '[H]unk [R]eset' })
            vim.keymap.set('n', '<leader>hs', gs.stage_hunk, { desc = '[H]unk [S]tage' })
            vim.keymap.set('n', '<leader>hu', gs.undo_stage_hunk, { desc = '[H]unk [U]ndo last hunk' })
            -- vim.keymap.set('n', '<leader>hd', gs.diffthis, { desc = '[H]unk [D]iff' })
            -- vim.keymap.set('n', '<leader>hD', function() gs.diffthis('~') end, { desc = '[H]unk [D]iff with Base' })

            -- don't override the built-in and fugitive keymaps
            local gs = package.loaded.gitsigns
            vim.keymap.set({ 'n', 'v' }, ']c', function()
                if vim.wo.diff then
                    return ']c'
                end
                vim.schedule(function()
                    gs.next_hunk()
                end)
                return '<Ignore>'
            end, { expr = true, buffer = bufnr, desc = 'Jump to next hunk' })
            vim.keymap.set({ 'n', 'v' }, '[c', function()
                if vim.wo.diff then
                    return '[c'
                end
                vim.schedule(function()
                    gs.prev_hunk()
                end)
                return '<Ignore>'
            end, { expr = true, buffer = bufnr, desc = 'Jump to previous hunk' })
        end,

        current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
            ignore_whitespace = false,
        },
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
    }
}


return M
