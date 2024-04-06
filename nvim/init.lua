-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.api.nvim_create_autocmd({"FileType"}, {pattern="gitcommit", command="setlocal tw=72"})

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- Git related plugins
  'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  -- 'tpope/vim-sleuth',

  -- Useful plugin to show you pending keybinds.
  { 'folke/which-key.nvim', opts = {} },

  -- {
  --   'windwp/nvim-autopairs',
  --   event = "InsertEnter",
  --   opts = {
  --     check_ts = true,
  --   }
  -- },

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim',
    opts = {
      toggler = {
        line = '<C-_>',
        block = '<C-_>',
      }
    }
  },

  -- 'github/copilot.vim',
  --    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
  { import = 'plugins' },
}, {})


-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank({timeout = 1000})
  end,
  group = highlight_group,
  pattern = '*',
})

-- document existing key chains
require('which-key').register {
  ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
  ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
  ['<leader>g'] = { name = '[G]it', _ = 'which_key_ignore' },
  ['<leader>h'] = { name = 'More git', _ = 'which_key_ignore' },
  ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
  ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
  ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
}

require('vim-options').setup()

-- require('vscode').load()

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
