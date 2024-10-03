return {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    opts = {
        check_ts = true,
        ts_config = {
            javascript = {'template_string'},
            javascriptreact = {'template_string', 'jsx_element'},
            typescriptreact = {'template_string', 'jsx_element'},
        }
    }
}
