return {
  "sindrets/diffview.nvim",
  cond = not vim.g.vscode,
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gd", function()
        local lib = require("diffview.lib")
        if lib.get_current_view() then
          vim.cmd("DiffviewClose")
        else
          vim.cmd("DiffviewOpen")
        end
      end, desc = "Diffview Toggle" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview File History" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview Branch History" },
  },
  config = function()
    local actions = require("diffview.actions")

    -- Helper to change diff context
    local diff_context = 6
    local function set_diff_context(n)
      diff_context = math.max(0, n)
      vim.opt.diffopt:remove("context:" .. (diff_context + 5))
      vim.opt.diffopt:remove("context:" .. (diff_context - 5))
      vim.opt.diffopt:remove("context:" .. diff_context)
      vim.opt.diffopt:append("context:" .. diff_context)
      vim.cmd("diffupdate")
      vim.notify("Diff context: " .. diff_context)
    end

    require("diffview").setup({
      keymaps = {
        view = {
          { "n", "s", actions.toggle_stage_entry, { desc = "Stage/unstage current file" } },
          { "n", "<leader>+", function() set_diff_context(diff_context + 5) end, { desc = "Increase diff context" } },
          { "n", "<leader>-", function() set_diff_context(diff_context - 5) end, { desc = "Decrease diff context" } },
        },
        file_panel = {
          { "n", "cc", "<cmd>G commit<cr>", { desc = "Commit" } },
        },
      },
      view = {
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
    })
  end,
}
