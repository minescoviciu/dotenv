return {
    cond=not vim.g.vscode,
    'tpope/vim-fugitive',
    dependencies = { 'tpope/vim-rhubarb' },
    event = "VeryLazy",
    config = function()
        -- Set up mapping for Git blame buffer
        local group = vim.api.nvim_create_augroup('FugitiveCustom', { clear = true })
        vim.api.nvim_create_user_command('Blame', function()
                vim.cmd('Git blame')
            end, {
              desc = 'Show git blame for current line using Gitsigns'
        })

        -- Open git commit in floating window
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'gitcommit',
            group = group,
            callback = function(ev)
                local buf = ev.buf
                -- Only for fugitive commits (buffer name starts with fugitive://)
                local bufname = vim.api.nvim_buf_get_name(buf)
                if not bufname:match("^fugitive://") and not bufname:match("COMMIT_EDITMSG") then
                    return
                end

                -- Get dimensions
                local width = math.floor(vim.o.columns * 0.7)
                local height = math.floor(vim.o.lines * 0.7)
                local row = math.floor((vim.o.lines - height) / 2)
                local col = math.floor((vim.o.columns - width) / 2)

                -- Create floating window
                local win = vim.api.nvim_open_win(buf, true, {
                    relative = "editor",
                    width = width,
                    height = height,
                    row = row,
                    col = col,
                    style = "minimal",
                    border = "rounded",
                    title = " Commit ",
                    title_pos = "center",
                })

                -- Close the original split window if it exists
                for _, w in ipairs(vim.api.nvim_list_wins()) do
                    if w ~= win and vim.api.nvim_win_get_buf(w) == buf then
                        vim.api.nvim_win_close(w, true)
                        break
                    end
                end
            end
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
