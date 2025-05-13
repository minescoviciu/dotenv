-- highlight text under cursor
return {
    cond=not vim.g.vscode,
    'yamatsum/nvim-cursorline',
    event = "VeryLazy",
    opts = {
      cursorline = {
        enable = true,
        timeout = 1000,
        number = false,
      },
      cursorword = {
        enable = true,
        min_length = 3,
        hl = {
          bg = '#1c3827',
          underline = false
        },
      }
    }
}
