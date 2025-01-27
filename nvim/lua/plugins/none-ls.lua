return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    config = function()
        local null_ls = require("null-ls")
        
        null_ls.setup({
            sources = {
                null_ls.builtins.formatting.stylua,
                null_ls.builtins.completion.spell,
                null_ls.builtins.formatting.black
            },
        })

        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*.py",
            callback = function()
                local line_count = vim.api.nvim_buf_line_count(0)
                if line_count <= 1000 then
                    vim.lsp.buf.format()
                end
            end,
        })
    end
}
