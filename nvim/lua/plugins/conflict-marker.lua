return {
    'rhysd/conflict-marker.vim',
    cond=not vim.g.vscode,
    event = "VeryLazy",
    config = function()
        vim.g.conflict_marker_highlight_group = ''
        vim.cmd([[
            highlight ConflictMarkerBegin guibg=#2f7366
            highlight ConflictMarkerOurs guibg=#2e5049
            highlight ConflictMarkerTheirs guibg=#344f69
            highlight ConflictMarkerEnd guibg=#2f628e
            highlight ConflictMarkerCommonAncestors guibg=#754a81
        ]])

        -- Enable conflict marker highlighting
        vim.g.conflict_marker_enable_highlight = 1
        
        -- Set conflict markers to match Git's default
        vim.g.conflict_marker_begin = '^<<<<<<< .*$'
        vim.g.conflict_marker_common_ancestors = '^||||||| .*$'
        vim.g.conflict_marker_separator = '^=======$'
        vim.g.conflict_marker_end = '^>>>>>>> .*$'

        vim.g.conflict_marker_enable_mappings = 0
        vim.keymap.set('n', '[x', '<cmd>ConflictMarkerPrevHunk<CR>', { silent = true, desc = 'Previous conflict' })
        vim.keymap.set('n', ']x', '<cmd>ConflictMarkerNextHunk<CR>', { silent = true, desc = 'Next conflict' })
        vim.keymap.set('n', '<leader>xo', '<cmd>ConflictMarkerOurselves<CR>', { silent = true, desc = 'Choose [O]urs' })
        vim.keymap.set('n', '<leader>xt', '<cmd>ConflictMarkerThemselves<CR>', { silent = true, desc = 'Choose [T]heirs' })
        vim.keymap.set('n', '<leader>xb', '<cmd>ConflictMarkerBoth<CR>', { silent = true, desc = 'Keep [B]oth' })
        vim.keymap.set('n', '<leader>xn', '<cmd>ConflictMarkerNone<CR>', { silent = true, desc = 'Keep [N]one' })

    end
}
