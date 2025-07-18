return {
    cond=not vim.g.vscode,
    'tpope/vim-fugitive',
    dependencies = { 'tpope/vim-rhubarb' },
    event = "VeryLazy",
    config = function()
        -- Set up mapping for Git blame buffer
        local group = vim.api.nvim_create_augroup('FugitiveCustom', { clear = true })
        vim.api.nvim_create_user_command('blame', function()
                vim.cmd('Git blame')
            end, {
              desc = 'Show git blame for current line using Gitsigns'
            })

        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'fugitiveblame',
            group = group,
            callback = function(ev)
                vim.keymap.set('n', 'o', function()
                    -- Get current line and extract first word (commit hash)
                    local line = vim.api.nvim_get_current_line()
                    local commit = line:match('^(%S+)')
                    if commit and commit ~= '^' then
                        vim.cmd('GBrowse ' .. commit)
                    end
                end, { buffer = ev.buf, silent = true, desc = 'Open commit in GitHub' })
            end
        })
    end
}
