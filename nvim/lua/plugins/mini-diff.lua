return {
    "echasnovski/mini.diff",
    config = function()
        local diff = require("mini.diff")
        diff.setup({
            view = {
                -- Visualization style. Possible values are 'sign' and 'number'.
                style = 'sign',
                -- Signs used for hunks with 'sign' view
                signs = {
                    add = "▎",
                    change = "▎",
                    delete = "",
                },
                -- Priority of used visualization extmarks
                priority = 199,
            },
            -- Disabled by default
            source = diff.gen_source.none(),
        })
    end,
}
