return {
    'echasnovski/mini.surround',
    -- opts = {
    --     mappings = {
    --         add = "gsa",
    --         delete = "gsd",
    --         find = "gsf",
    --         find_left = "gsF",
    --         highlight = "gsh",
    --         replace = "gsr",
    --         update_n_lines = "gsn",
    --     },
    -- },
    config = function ()
        require('mini.surround').setup({
            mappings = {
                add = "sa",
                delete = "sd",
                find = "sf",
                find_left = "sF",
                highlight = "sh",
                replace = "sr",
                update_n_lines = "sn",
            },
            silent = false,
        })
    end
}
