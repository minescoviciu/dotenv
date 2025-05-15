local M = {}

M.setup = function()
    local vscode = require('vscode')
    
    vim.notify = vscode.notify
    -- Add normal mode mapping for opening git panel
    vim.keymap.set('n', '<leader>gg', function()
        vscode.call('workbench.view.scm')
    end, { noremap = true, silent = true, desc = "Open Git panel", expr = true })

    vim.api.nvim_create_user_command('Format', function()
        vscode.call('editor.action.formatDocument')
    end, {})
end

return M
