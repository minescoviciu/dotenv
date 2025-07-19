local catppuccin = {
    cond=not vim.g.vscode,
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            flavour = "mocha", -- latte, frappe, macchiato, mocha
            background = {   -- :h background
                light = "latte",
                dark = "mocha",
            },
            transparent_background = false, -- disables setting the background color.
            show_end_of_buffer = false,   -- shows the '~' characters after the end of buffers
            term_colors = false,          -- sets terminal colors (e.g. `g:terminal_color_0`)
            dim_inactive = {
                enabled = false,          -- dims the background color of inactive window
                shade = "dark",
                percentage = 0.15,        -- percentage of the shade to apply to the inactive window
            },
            no_italic = false,            -- Force no italic
            no_bold = false,              -- Force no bold
            no_underline = false,         -- Force no underline
            styles = {                    -- Handles the styles of general hi groups (see `:h highlight-args`):
                comments = { "italic" },
                conditionals = { "italic" },
                loops = {},
                functions = {},
                keywords = {},
                strings = {},
                variables = {},
                numbers = {},
                booleans = {},
                properties = {},
                types = {},
                operators = {},
            },
            color_overrides = {},
            custom_highlights = {},
            integrations = {
                telescope = true,
                treesitter_context = true,
                gitsigns = true,
                treesitter = true,
                blink_cmp = true,
                which_key = true,
                snacks = true,
                render_markdown = true,
                indent_blankline = {
                    enabled = true,
                    scope_color = "lavender", -- catppuccin color (eg. `lavender`) Default: text
                    colored_indent_levels = true,
                },
                markdown = true,
                native_lsp = {
                    enabled = true,
                    underlines = {
                        errors = { "undercurl" },
                        hints = { "undercurl" },
                        warnings = { "undercurl" },
                        information = { "undercurl" },
                    },
                },
            },
        })
        vim.cmd [[colorscheme catppuccin]]
    end
}

local tokyo = {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        -- your configuration comes here
        -- or leave it empty to use the default settings
        style = "night", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
        light_style = "day", -- The theme is used when the background is set to light
        transparent = false, -- Enable this to disable setting the background color
        terminal_colors = true, -- Configure the colors used when opening a `:terminal` in [Neovim](https://github.com/neovim/neovim)
        styles = {
          -- Style to be applied to different syntax groups
          -- Value is any valid attr-list value for `:help nvim_set_hl`
          comments = { italic = true },
          keywords = { italic = true },
          functions = {},
          variables = {},
          -- Background styles. Can be "dark", "transparent" or "normal"
          sidebars = "dark", -- style for sidebars, see below
          floats = "dark", -- style for floating windows
        },
        sidebars = { "qf", "help" }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
        day_brightness = 0.3, -- Adjusts the brightness of the colors of the **Day** style. Number between 0 and 1, from dull to vibrant colors
        hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
        dim_inactive = false, -- dims inactive windows
        lualine_bold = false, -- When `true`, section headers in the lualine theme will be bold
      })
      vim.cmd[[colorscheme tokyonight]]
    end
}
-- return tokyo
return catppuccin
