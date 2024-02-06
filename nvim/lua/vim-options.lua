local M = {}

M.setup = function ()

    -- Set highlight on search
    vim.o.hlsearch = true
    -- Make line numbers default
    vim.wo.number = true
    -- Enable mouse mode
    vim.o.mouse = 'a'
    -- Sync clipboard between OS and Neovim.
    --  Remove this option if you want your OS clipboard to remain independent.
    --  See `:help 'clipboard'`
    vim.o.clipboard = 'unnamedplus'
    -- Enable break indent
    vim.o.breakindent = true
    -- Save undo history
    vim.o.undofile = true
    -- Case-insensitive searching UNLESS \C or capital in search
    vim.o.ignorecase = true
    vim.o.smartcase = true
    -- Keep signcolumn on by default
    vim.wo.signcolumn = 'yes'
    -- Decrease update time
    vim.o.updatetime = 250
    vim.o.timeoutlen = 300
    -- Set completeopt to have a better completion experience
    vim.o.completeopt = 'menuone,noselect'
    -- NOTE: You should make sure your terminal supports this
    vim.o.termguicolors = true
    -- Show special chars greyed out.
    vim.o.list = true
    vim.o.listchars = 'tab:→\\,space:·'
    vim.cmd('highlight SpecialKey ctermfg=8 guifg=#828282')
    -- X Line above and below the cursorline when possible
    vim.o.scrolloff = 8
    -- Bash like command completion
    vim.o.wildmode = 'longest:full,full'
    
    -- show relative line numbers
    vim.o.relativenumber = true
    -- put the vertical split on the right
    vim.o.splitright = true

    -- tabs options a bit unstable don't know why
    vim.o.tabstop     =4
    vim.o.softtabstop =4
    vim.o.shiftwidth  =4
    vim.o.expandtab = true

    -- set the session options for auto-session
    vim.o.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
    vim.wo.foldenable = false

    -- [[ Basic Keymaps ]]

    -- Add OS shortcuts
    vim.keymap.set('n', '<A-Left>',  'b',  {silent = true})
    vim.keymap.set('v', '<A-Left>',  'b',  {silent = true})
    vim.keymap.set('n', '<A-Right>', 'w',  {silent = true})
    vim.keymap.set('v', '<A-Right>', 'w',  {silent = true})
    vim.keymap.set('n', '<Home>',    '0',  {silent = true})
    vim.keymap.set('v', '<Home>',    '0',  {silent = true})
    vim.keymap.set('n', '<End>',     'g_', {silent = true})
    vim.keymap.set('v', '<End>',     'g_', {silent = true})

    -- Move current line up/down and visual block up/down
    vim.keymap.set('n', '<A-k>', ':m-2<CR>==', {})
    vim.keymap.set('n', '<A-j>', ':m+1<CR>==', {})
    vim.keymap.set('v', '<A-k>', ":m'<-2<CR>gv=gv", {})
    vim.keymap.set('v', '<A-j>', ":m'>+1<CR>gv=gv", {})

    -- Keymaps for better default experience
    -- See `:help vim.keymap.set()`
    vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

    -- Remap for dealing with word wrap
    vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
    vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

    vim.keymap.set('n', 'n',        'nzzzv')
    vim.keymap.set('n', 'U',        'Nzzzv')
    vim.keymap.set('n', '<C-d>',    '<C-d>zz')
    vim.keymap.set('n', '<C-u>',    '<C-u>zz')

    -- Paste without overwriting register
    vim.keymap.set("v", "p", '"_dP')

    -- Make Y behave like C or D
    vim.keymap.set("n", "Y", "y$")

    -- Copy file paths
    vim.keymap.set("n", "<leader>cf", "<cmd>let @+ = expand(\"%\")<CR>", { desc = "[C]opy File Name" })
    vim.keymap.set("n", "<leader>cp", "<cmd>let @+ = expand(\"%:p\")<CR>", { desc = "[C]opy File Path" })

    -- Yank github link
    vim.keymap.set("n", "<leader>cg", ":GBrowse!<CR>", {desc = "[C]opy [G]ithub URL"})
    vim.keymap.set("x", "<leader>cg", ":GBrowse!<CR>", {desc = "[C]opy [G]ithub URL"})

    -- Stay in indent mode
    vim.keymap.set("v", "<", "<gv")
    vim.keymap.set("v", ">", ">gv")
end

return M
