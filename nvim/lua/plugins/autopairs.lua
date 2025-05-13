return {
    'windwp/nvim-autopairs',
    cond=not vim.g.vscode,
    event = "InsertEnter",
    opts = {
        check_ts = true,
        disable_filetype = { "snacks_picker_input"},
        ts_config = {
            javascript = {'template_string'},
            javascriptreact = {'template_string', 'jsx_element'},
            typescriptreact = {'template_string', 'jsx_element'},
        }
    }
}
