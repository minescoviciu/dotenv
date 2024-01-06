return {
  'nvim-tree/nvim-tree.lua',
  dependencies = {
      "nvim-tree/nvim-web-devicons"
  },
  lazy = false,
  config = function()
        require('nvim-tree').setup({})
        local nvimTreeFocusOrToggle = function ()
            local nvimTree=require("nvim-tree.api")
            local buffPath = vim.api.nvim_buf_get_name(0)
            nvimTree.tree.toggle({path=buffPath, find_file=true, focus=true})
        end
        vim.keymap.set('n', '<leader><C-B>', nvimTreeFocusOrToggle, {silent=true})
  end
}

