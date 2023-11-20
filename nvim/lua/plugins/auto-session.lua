return {
  'rmagatti/auto-session',
  dependencies = {
      "nvim-telescope/telescope.nvim",
  },
  config = function ()
      require("auto-session").setup({
          log_level = "info",
          auto_session_root_dir = "~/.config/nvim-sessions",
          auto_save_enabled = true,
          auto_restore_enabled = true,
          session_lens = {
              -- If load_on_setup is set to false, one needs to eventually call `require("auto-session").setup_session_lens()` if they want to use session-lens.
              buftypes_to_ignore = {}, -- list of buffer types what should not be deleted from current session
              load_on_setup = true,
              previewer = false,
          },
      })
      vim.keymap.set("n", "<leader>ss", require("auto-session.session-lens").search_session, {
          noremap = true,
          desc = "[S]earch [S]ession",
      })

  end
}
