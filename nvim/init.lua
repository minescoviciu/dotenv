-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Check if we're on a specific machine
local hostname = vim.fn.hostname()
if hostname == 'Andreis-MacBook-Pro-2.local' then
  vim.g.personal_mac = true
else
  vim.g.personal_mac = false
end

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
  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim',
    cond=not vim.g.vscode,
    opts = {
      toggler = {
        line = '<C-_>',
        block = '<C-_>',
      }
    }
  },
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



require('vim-options').setup()
if vim.g.vscode then
  require('vscode-options').setup()
else
  require('lsp').setup()
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
