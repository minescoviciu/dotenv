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
    vim.o.timeoutlen = 1000
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
    vim.o.relativenumber = false
    -- put the vertical split on the right
    vim.o.splitright = true

    -- tabs options a bit unstable don't know why
    vim.o.tabstop     =4
    vim.o.softtabstop =4
    vim.o.shiftwidth  =4
    vim.o.expandtab = true

    vim.opt.laststatus = 3

    -- set the session options for auto-session
    vim.o.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

    -- use treesitter for folding
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
    vim.wo.foldenable = false

    vim.o.winborder = 'rounded'

    -- [[ Basic Keymaps ]]

    -- Add OS shortcuts
    vim.keymap.set('n', '<A-Left>',  'b',  {silent = true})
    vim.keymap.set('v', '<A-Left>',  'b',  {silent = true})
    vim.keymap.set('i', '<A-Left>',  '<C-o>b',  {silent = true})
    vim.keymap.set('n', '<A-Right>', 'w',  {silent = true})
    vim.keymap.set('v', '<A-Right>', 'w',  {silent = true})
    vim.keymap.set('i', '<A-Right>', '<C-o>w',  {silent = true})
    vim.keymap.set('n', '<Home>',    '0',  {silent = true})
    vim.keymap.set('v', '<Home>',    '0',  {silent = true})
    vim.keymap.set('n', '<End>',     'g_', {silent = true})
    vim.keymap.set('v', '<End>',     'g_', {silent = true})
    -- Meta/Alt + Backspace to delete previous word
    vim.keymap.set('i', '<A-BS>', '<C-w>', {silent = true, desc = "Delete previous word"})
     -- C-a and C-e to go to the beginning and end of line in insert mode
    vim.keymap.set('i', '<C-a>', '<C-o>0', {silent = true, desc = "Go to beginning of line"})
    vim.keymap.set('i', '<C-e>', '<C-o>$', {silent = true, desc = "Go to end of line"})

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
    vim.keymap.set('n', 'N',        'Nzzzv')
    vim.keymap.set('n', '<C-d>',    '<C-d>zz')
    vim.keymap.set('n', '<C-u>',    '<C-u>zz')

    -- Paste without overwriting register
    vim.keymap.set("v", "p", '"_dP')
    vim.keymap.set("n", "c", '"_c')

    -- Make Y behave like C or D
    vim.keymap.set("n", "Y", "y$")

    -- Copy file paths
    vim.keymap.set("n", "<leader>cp", "<cmd>let @+ = expand(\"%:p\")<CR>", { desc = "[C]opy File Path" })
    vim.keymap.set("n", "<leader>cr", "<cmd>let @+ = expand(\"%\")<CR>", { desc = "[C]opy File Relative" })
    vim.keymap.set("n", "<leader>cn", "<cmd>let @+ = expand(\"%:t\")<CR>", { desc = '[C]opy File Name' })

    -- Yank github link
    vim.keymap.set("n", "<leader>cg", ":GBrowse<CR>", {desc = "Open [G]ithub URL"})
    vim.keymap.set("x", "<leader>cg", ":GBrowse<CR>", {desc = "Open [G]ithub URL"})

    vim.keymap.set("n", "<leader>cG", ":GBrowse!<CR>", {desc = "[C]opy [G]ithub URL"})
    vim.keymap.set("x", "<leader>cG", ":GBrowse!<CR>", {desc = "[C]opy [G]ithub URL"})


    -- Stay in indent mode
    vim.keymap.set("v", "<", "<gv")
    vim.keymap.set("v", ">", ">gv")

    -- Maximizes the current window vertically and horizontally
    vim.keymap.set('n', 'Zz', '<C-w>_<C-w>|', { noremap = true, desc = "[Z]oom in"})

    -- Makes all windows equal size
    vim.keymap.set('n', 'Zo', '<C-w>=', { noremap = true, desc = "[Z]oom [O]ut" })

    -- This command is used by fugitive to open in browser
    vim.api.nvim_create_user_command(
        'Browse',
        function(opts)
            local cmd = string.format("NVIM=1 ~/.config/scripts/wezterm.py open %s", opts.args)
            local out = vim.fn.system(cmd)
            if not out then
                vim.notify(out)
            end
        end,
        { nargs = 1, desc = "Open a URL with wezterm_open_web" }
    )

    vim.keymap.set('v', '<leader>fx', ":'<,'>!xmllint --format -<CR>", { desc = 'Format XML selection' })
    vim.keymap.set('v', '<leader>fp', ":'<,'>!black -q -<CR>", { desc = 'Format Python selection' })
    vim.keymap.set('v', '<leader>fj', ":'<,'>!jq -M .<CR>", { desc = 'Format JSON selection' })

    vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
        pattern = {"*.yml", "*.yaml"},
        callback = function()
            -- Check if the first line starts with ---
            local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
            if first_line and first_line:match("^---") then
                vim.bo.filetype = "yaml.ansible"
            end
        end,
        desc = "Set filetype to yaml.ansible for YAML files starting with ---"
    })

    vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
      pattern = { "*.yaml.j2"},
      callback = function()
        vim.bo.filetype = "yaml"
      end,
    })

    vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
      pattern = { "*.jenkinsfile", "*.Jenkinsfile", "Jenkinsfile", "jenkinsfile" },
      callback = function()
        vim.bo.filetype = "groovy"
      end,
    })
end

return M
