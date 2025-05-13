return {
    cond=not vim.g.vscode,
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    event = "VeryLazy",
    config = function()
        local null_ls = require("null-ls")
        
        null_ls.setup({
            sources = {
                null_ls.builtins.formatting.stylua,
                null_ls.builtins.completion.spell,
                null_ls.builtins.formatting.black
            },
        })

    end
}
