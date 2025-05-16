local M = {}

M.setup = function()
    local vscode = require('vscode')
    
    local function get_visual_selection()
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local start_row, start_col = start_pos[2], start_pos[3]
        local end_row, end_col = end_pos[2], end_pos[3]
        
        -- Get the visual selection text
        local lines = vim.api.nvim_buf_get_text(
            0,                  -- Current buffer
            start_row - 1,      -- 0-indexed start row
            start_col - 1,      -- 0-indexed start column
            end_row - 1,        -- 0-indexed end row
            end_col,            -- end column (already adjusted for inclusive selection)
            {}                  -- No options needed
        )
        return table.concat(lines, '\n')
    end

    vim.notify = vscode.notify
    -- Add normal mode mapping for opening git panel
    vim.keymap.set('n', '<leader>sg', function()
        vscode.call('workbench.action.findInFiles')
    end, { noremap = true, silent = true, desc = "Search grep", expr = true })

    vim.keymap.set('x', '<leader>sw', function()
        local selection = get_visual_selection()
        vscode.call('workbench.action.moveSideBarRight')
        vscode.call('workbench.action.findInFiles', {
            args = {
                query = selection,
                triggerSearch = true,
            }
        })
    end, { noremap = true, silent = true, desc = "Search selection", expr = true })


    vim.keymap.set('n', '<leader>sw', function()
        local word = vim.fn.expand('<cword>')
        vscode.call('workbench.action.moveSideBarRight')
        vscode.call('workbench.action.findInFiles', {
            args = {
                query = word,
                triggerSearch = true,
                -- replace: { 'type': 'string' },
                -- preserveCase: { 'type': 'boolean' },
                -- filesToInclude: { 'type': 'string' },
                -- filesToExclude: { 'type': 'string' },
                -- isRegex: { 'type': 'boolean' },
                -- isCaseSensitive: { 'type': 'boolean' },
                -- matchWholeWord: { 'type': 'boolean' },
                -- useExcludeSettingsAndIgnoreFiles: { 'type': 'boolean' },
                -- onlyOpenEditors: { 'type': 'boolean' },
            }
        })
    end, { noremap = true, silent = true, desc = "Search word", expr = true })

    vim.keymap.set('n', '<leader>sb', function()
        vscode.call('workbench.action.quickOpen', {
            args = {
                "edt mru "
            }
        })
    end, { noremap = true, silent = true, desc = "Search opened buffers", expr = true })

    vim.keymap.set('n', '<leader>fb', function()
        vscode.call('workbench.action.moveSideBarRight')
        vscode.call('workbench.view.explorer')
    end, { noremap = true, silent = true, desc = "Explorer", expr = true })

    vim.keymap.set('n', '<leader>gc', function()
        vscode.call('editor.action.commentLine')
    end, { noremap = true, silent = true, desc = "Comment line", expr = true })

    vim.keymap.set('n', '<leader>gg', function()
        vscode.call('workbench.action.closeSidebar')
        vscode.call('lazygit-vscode.toggle')
    end, { noremap = true, silent = true, desc = "Lazygit", expr = true })

    vim.api.nvim_create_user_command('Format', function()
        vscode.call('editor.action.formatDocument')
    end, {})
    
    vim.keymap.set('v', '<leader>r', function()
        vscode.call('')
    end, { noremap = true, silent = true, desc = "Rename symbol", expr = true })

    vim.keymap.set('v', '<leader>rt', function()
        vscode.call('workbench.action.tasks.runTask')
    end, { noremap = true, silent = true, desc = "Run task with selection", expr = true })
end

return M
