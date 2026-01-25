-- This is for running a command in a terminal buffer will remove ui after exit
-- Snacks.terminal(cmd, opts)
return {
  cond=not vim.g.vscode,
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    animate = {
      -- disabled in the init
      -- too distracting
      duration = 20, -- ms per step
      easing = "quad",
      fps = 60, -- frames per second. Global setting for all animations
    },
    bigfile = { enabled = true },
    lazygit = {
      configure = true,
      config = {
        os = {
          edit = '[ -z "$NVIM" ] && (nvim -- {{filename}}) || (nvim --server "$NVIM" --remote-send "q<C-\\><C-N>:e {{filename}}<CR>")',
          editAtLine = '[ -z "$NVIM" ] && (nvim +{{line}} -- {{filename}}) || (nvim --server "$NVIM" --remote-send "q<C-\\><C-N>:e +{{line}} {{filename}}<CR>")',
          openDirInEditor = '[ -z "$NVIM" ] && (nvim -- {{dir}}) || (nvim --server "$NVIM" --remote-send "q" && nvim --server "$NVIM" --remote {{dir}})',
        }
      },
      win = {
        style = "lazygit",
      },
    },
    dashboard = { enabled = true },
    explorer = {
      enabled = true,
      replace_netrw = true,
    },
    picker = {
      -- debug = {
      --   scores = true, -- show scores in the list
      --   leaks = true, -- show when pickers don't get garbage collected
      --   explorer = true, -- show explorer debug info
      --   files = true, -- show file debug info
      --   grep = true, -- show file debug info
      --   extmarks = true, -- show extmarks errors
      -- },
      actions = {
        sidekick_send = function(...)
          return require("sidekick.cli.picker.snacks").send(...)
        end,
      },
      formatters = {
        file = {
          filename_first = false, -- display filename before the file path
          truncate = 120, -- truncate the file path to (roughly) this length
          filename_only = false, -- only show the filename
          icon_width = 2, -- width of the icon (in characters)
        },
      },
      sources = {
        files = {
          hidden = true,
        },
        explorer = {
          tree = true,
          hidden = false,
          ignored = false,
          follow_file = true,
          watch = false,
          git_status = true,
          git_status_open = true,
          git_untracked = true,
          auto_close = true,
          jump = { close = true },
          layout = {
            preview = {
              enabled = true,
            },
            layout = {
              position = "right",
              width = 100,
            }
          },
        },
      },
      win = {
        input = {
          keys = {
            ["<c-j>"] = {"list_scroll_down", mode = { "i", "n" }},
            ["<c-k>"] = {"list_scroll_up", mode = { "i", "n" }},
            ["<c-u>"] = {"preview_scroll_up", mode = { "i", "n" }},
            ["<c-d>"] = {"preview_scroll_down", mode = { "i", "n" }},
            ["<c-g>"] = {
              "sidekick_send",
              mode = { "n", "i" },
            },
          },
        },
        list = {
          keys = {
            ["<c-j>"] = {"list_scroll_down", mode = { "i", "n" }},
            ["<c-k>"] = {"list_scroll_up", mode = { "i", "n" }},
            ["<c-u>"] = {"preview_scroll_up", mode = { "i", "n" }},
            ["<c-d>"] = {"preview_scroll_down", mode = { "i", "n" }},
          }
        },
      },
    },
    indent = { enabled = true },
    input = {
      enabled = true,
      win = {
        style = 'above_cursor',
      },
    },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    quickfile = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = {
      notification = {
        -- wo = { wrap = true } -- Wrap notifications
      },
      above_cursor = {
        backdrop = false,
        position = 'float',
        border = 'rounded',
        title_pos = 'left',
        height = 1,
        noautocmd = true,
        relative = 'cursor',
        row = -3,
        col = 0,
        wo = {
          cursorline = false,
        },
        bo = {
          filetype = 'snacks_input',
          buftype = 'prompt',
        },
        --- buffer local variables
        b = {
          completion = true, -- enable/disable blink completions in input
        },
        keys = {
          n_esc = { '<esc>', { 'cmp_close', 'cancel' }, mode = 'n', expr = true },
          i_esc = { '<esc>', { 'cmp_close', 'stopinsert' }, mode = 'i', expr = true },
          i_cr = { '<cr>', { 'cmp_accept', 'confirm' }, mode = 'i', expr = true },
          i_tab = { '<tab>', { 'cmp_select_next', 'cmp', 'fallback' }, mode = 'i', expr = true },
          i_ctrl_w = { '<c-w>', '<c-s-w>', mode = 'i', expr = true },
          i_up = { '<up>', { 'hist_up' }, mode = { 'i', 'n' } },
          i_down = { '<down>', { 'hist_down' }, mode = { 'i', 'n' } },
          q = "cancel",
        },
      },
    },
  },
  keys = {
    { "<leader><leader>", function() Snacks.picker.resume() end, desc = "Resume" },
    -- find
    { "<leader>sf", function() Snacks.picker.files() end, desc = "Smart Find Files" },
    { "<leader>sb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fb", function() Snacks.picker.explorer() end, desc = "Explorer" },
    -- { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    -- git
    { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Git Log Line" },
    { "<leader>gF", function() Snacks.picker.git_log_file() end, desc = "Git Log File" },
    -- Grep
    { "<leader>sB", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    { "<leader>sG", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
    { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
    -- search
    { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
    { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
    { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
    { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sD", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sd", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
    { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
    { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
    { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
    { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
    { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
    { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
    { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    -- LSP
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
    { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },

    { "<leader>gp", function() Snacks.picker.gh_pr({search = [[ is:open is:pr author:aminescu-dn author:bistoc-dn author:amihu-dn author:anstancu author:mburlacu-dn author:colaru-dn author:sbradulet-dn ]]}) end, desc = "GitHub Pull Requests (open)" },

    { "<leader>z",  function() Snacks.zen() end, desc = "Toggle Zen Mode" },
    { "<leader>Z",  function() Snacks.zen.zoom() end, desc = "Toggle Zoom" },
    { "<leader>.",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
    { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File" },
    { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
    { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
    { "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit Current File History" },
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
    { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit Log (cwd)" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    { "<c-/>",      function() Snacks.terminal() end, desc = "Toggle Terminal" },
    { "<c-_>",      function() Snacks.terminal() end, desc = "which_key_ignore" },
    { "]]",         function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
    { "[[",         function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
    {
      "<leader>N",
      desc = "Neovim News",
      function()
        Snacks.win({
          file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = "yes",
            statuscolumn = " ",
            conceallevel = 3,
          },
        })
      end,
    }
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command
        vim.g.snacks_animate = false

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.dim():map("<leader>uD")
      end,
    })
  end,
}
