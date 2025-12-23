return {
  "folke/sidekick.nvim",
  opts = {
    -- add any options here
    cli = {
      mux = {
        backend = "tmux",
        enabled = true,
        create = "window",
      },
    },
  },
  init = function()
    -- Helper function to prompt and send context to AI
    local function prompt_and_send(opts)
      local Context = require("sidekick.cli.context")
      local context = Context.get()

      -- Highlight the visual selection if in visual mode
      local ns, bufnr, start_line, end_line
      local input_opts = {
        prompt = opts.prompt,
        value = "",
      }

      if context.ctx.range then
        bufnr = context.ctx.buf
        start_line = context.ctx.range.from[1]
        end_line = context.ctx.range.to[1]
        ns = vim.api.nvim_create_namespace("sidekick_selection")

        -- Add highlight to the selected lines
        for line = start_line - 1, end_line - 1 do
          vim.api.nvim_buf_add_highlight(bufnr, ns, "Visual", line, 0, -1)
        end

        -- Position input relative to cursor, offset to be above selection start
        local cursor_line = context.ctx.row
        local row_offset = start_line - cursor_line - 3 -- -3 to place above selection

        input_opts.win = {
          position = 'float',
          relative = 'cursor',
          row = row_offset,
          col = 0,
          border = 'rounded',
          height = 1,
          width = 60,
          title_pos = 'left',
          backdrop = false,
          noautocmd = true,
          wo = { cursorline = false },
          bo = { filetype = 'snacks_input', buftype = 'prompt' },
          b = { completion = false },
        }
      else
        -- No selection, use the above_cursor style
        input_opts.win = { style = 'above_cursor' }
      end

      Snacks.input(input_opts, function(input)
        -- Clear highlight when input is done
        if ns and bufnr then
          vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        end

        -- Don't send if input is nil (user cancelled with Esc)
        if input == nil then return end

        -- Build message: if empty, send only context variable, otherwise add user input
        local msg = (input ~= '') and (opts.context .. "\n\n" .. input) or opts.context

        -- Auto-detect if we need this=true based on context variable
        local use_this = opts.context:match("{this}") ~= nil

        local msg_text = context:render({ msg = msg, this = use_this })
        if msg_text then
          require("sidekick.cli").send({ msg = msg_text })
        end
      end)
    end

    -- Store in a global for use in keymaps
    _G._sidekick_prompt_and_send = prompt_and_send
  end,
  keys = {
    {
      "<tab>",
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if not require("sidekick").nes_jump_or_apply() then
          return "<Tab>" -- fallback to normal tab
        end
      end,
      expr = true,
      desc = "Goto/Apply Next Edit Suggestion",
    },
    {
      "<leader>aa",
      function() require("sidekick.cli").toggle() end,
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>as",
      function()
        _G._sidekick_prompt_and_send({
          prompt = "Add context for selection: ",
          context = "{selection}",
        })
      end,
      mode = { "x" },
      desc = "Prompt with Selection",
    },
    {
      "<leader>at",
      function()
        _G._sidekick_prompt_and_send({
          prompt = "Add context for this: ",
          context = "{this}",
        })
      end,
      mode = { "x", "n" },
      desc = "Prompt with This",
    },
    {
      "<leader>ad",
      function() require("sidekick.cli").close() end,
      desc = "Detach a CLI Session",
    },
    {
      "<leader>af",
      function() require("sidekick.cli").send({ msg = "{file}" }) end,
      desc = "Send File",
    },
    {
      "<leader>av",
      function() require("sidekick.cli").send({ msg = "{selection}" }) end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<leader>ap",
      function() require("sidekick.cli").prompt() end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
    {
      "<leader>ao",
      function() require("sidekick.cli").toggle({ name = "opencode", focus = true }) end,
      desc = "Sidekick Toggle Opencode",
    },
  },
}
