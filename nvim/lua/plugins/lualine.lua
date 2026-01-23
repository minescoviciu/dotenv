return {
    cond=not vim.g.vscode,
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    event = "VeryLazy",
   config = function()
    local opts = {
      options = {
        icons_enabled = true,
        -- theme = 'tokyonight',
        theme = 'catppuccin',
        component_separators = "|",
        section_separators = { right = '', left = '' },
      },
      sections = {
        lualine_a = {
          { 'mode', separator = { left = '', right = '' }, right_padding = 2 },
        },
        lualine_b = { 'branch', 'diff' },
        lualine_c = {
          {
            'filename',
            path = 1,
            file_status = true
          },
                    {
            function()
              return " "
            end,
            color = function()
              local status = require("sidekick.status").get()
              if status then
                return status.kind == "Error" and "DiagnosticError" or status.busy and "DiagnosticWarn" or "Special"
              end
            end,
            cond = function()
              local status = require("sidekick.status")
              return status.get() ~= nil
            end,
          },
          {
            function()
              local status = require("sidekick.status").cli()
              return " " .. (#status > 1 and #status or "")
            end,
            cond = function()
              return #require("sidekick.status").cli() > 0
            end,
            color = function()
              return "Special"
            end,
          },
        },
        lualine_x = {},
        -- lualine_y = { 'searchcount', 'progress', require('codecompanion-lualine')},
        lualine_y = { 'searchcount', 'progress'},
        lualine_z = {
          { 'location', separator = { left = '', right = '' }, left_padding = 1 },
        },
      },
      inactive_sections = {
        lualine_a = { 'filename' },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
    }
    require('lualine').setup(opts)
  end
}
