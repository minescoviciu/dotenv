return {
  cond=not vim.g.vscode,
  'windwp/nvim-ts-autotag',
  dependencies = 'nvim-treesitter/nvim-treesitter',
  ft = { "html", "xml", "javascript", "javascriptreact", "typescriptreact", "svelte", "vue" },
  main = function()
    require('nvim-ts-autotag').setup({
      enable = true,
      filetypes = { "html", "xml", "javascript", "javascriptreact", "typescriptreact", "svelte", "vue" },
      skip_tags = {
        'area', 'base', 'br', 'col', 'command', 'embed', 'hr', 'img', 'slot',
        'input', 'keygen', 'link', 'meta', 'param', 'source', 'track', 'wbr','menuitem'
      }
    })
  end
}
