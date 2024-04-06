return {
    'tpope/vim-fugitive',
    lazy=false,
    keys = {
        {'<leader>gg', ':Git<CR>',     mode='n', desc='[G]it'},
        {'<leader>gl', ':Git log<CR>', mode='n', desc='[G]it [L]og'},
    }
}
