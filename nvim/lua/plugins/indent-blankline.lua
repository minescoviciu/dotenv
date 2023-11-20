return {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {},
    config = function ()

        local highlight = {
            "RainbowRed",
            "RainbowOrange",
            "RainbowYellow",
            "RainbowGreen",
            "RainbowBlue",
            "RainbowViolet",
            "RainbowCyan",
        }

        local hooks = require "ibl.hooks"
        -- create the highlight groups in the highlight setup hook, so they are reset
        -- every time the colorscheme changes
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
            vim.api.nvim_set_hl(0, "RainbowRed",    { fg = "#9c6e72" })
            vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#997e65" })
            vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#a3906d" })
            vim.api.nvim_set_hl(0, "RainbowGreen",  { fg = "#779164" })
            vim.api.nvim_set_hl(0, "RainbowBlue",   { fg = "#5e778c" })
            vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#785e80" })
            vim.api.nvim_set_hl(0, "RainbowCyan",   { fg = "#5c7b80" })
        end)

        require("ibl").setup {
            indent = {
                highlight = highlight,
                char = "┆"
            },
            scope = {
                char             = "│",
                enabled          = true,
                show_start       = true,
                show_end         = false,
                show_exact_scope = true,
                highlight        = highlight,
            }
        }

    end
}

