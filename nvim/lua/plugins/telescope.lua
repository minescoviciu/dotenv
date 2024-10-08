local M = {}

table.insert(M,
    {
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        dependencies = {
            'nvim-lua/plenary.nvim',
            -- Fuzzy Finder Algorithm which requires local dependencies to be built.
            -- Only load if `make` is available. Make sure you have the system
            -- requirements installed.
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                -- NOTE: If you are having trouble with this installation,
                --       refer to the README for telescope-fzf-native for more instructions.
                build = 'make',
                cond = function()
                    return vim.fn.executable 'make' == 1
                end,
            },
        },
        config = function ()
            local actions = require('telescope.actions')
            local layout_actions = require('telescope.actions.layout')
            require("telescope").setup({
                defaults = {
                    mappings = {
                        i = {
                            -- ["<C-n>"] = telescope_actions.cycle_previewers_next,
                            -- ["<C-m>"] = telescope_actions.cycle_previewers_prev,
                            ["<M-p>"] = layout_actions.toggle_preview,
                        },
                        n = {
                            ["<M-p>"] = layout_actions.toggle_preview,
                        }
                    },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                        file_ignore_patterns = {".git/", ".cache", "%.o", "%.a", "%.out", "%.class", "%.pdf", "%.mkv", "%.mp4", "%.zip"},
                    },
                    git_commit = {
                        git_command = {
                            "git", "log",
                            "--pretty=oneline",
                            "--decorate=short",
                            "--", "."
                        }
                    },
                    live_grep = {
                        mappings = {
                            i = { ["<c-f>"] = actions.to_fuzzy_refine },
                        },
                    },
                    buffers = {
                        mappings = {
                            i = { ["<c-d>"] = actions.delete_buffer + actions.move_selection_next},
                        },
                    },
                    lsp_references = {
                        layout_strategy = 'vertical',
                        layout_config = {
                            height = 0.8,
                            width = 0.8,
                            preview_height = 0.55,
                            mirror = false,
                        },
                    },
                },
                extensions = {
                    file_browser = {
                        theme = "ivy",
                        prompt_path = true,
                        grouped = true,
                        depth = 1,
                        -- disables netrw and use telescope-file-browser in its place
                        hijack_netrw = true,
                        -- mappings = {
                        --     ["i"] = {
                        --         -- your custom insert mode mappings
                        --     },
                        --     ["n"] = {
                        --         -- your custom normal mode mappings
                        --     },
                        -- },
                    },
                },
            })
            -- set keymaps
            local builtin = require('telescope.builtin')

            -- Enable telescope fzf native, if installed
            pcall(require('telescope').load_extension, 'fzf')

            require("telescope").load_extension "file_browser"

            -- See `:help telescope.builtin`
            vim.keymap.set('n', '<leader>?', builtin.oldfiles, { desc = '[?] Find recently opened files' })
            vim.keymap.set('n', '<leader><space>', builtin.resume, { desc = '[ ] Resume last search' })
            vim.keymap.set('n', '<leader>/', function()
                -- You can pass additional configuration to telescope to change theme, layout, etc.
                builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = '[/] Fuzzily search in current buffer' })

            vim.keymap.set('n', '<leader>gf', builtin.git_files,   { desc = 'Search [G]it [F]iles' })
            vim.keymap.set('n', '<leader>sf', builtin.find_files,  { desc = '[S]earch [F]iles' })
            vim.keymap.set('n', '<leader>sh', builtin.help_tags,   { desc = '[S]earch [H]elp' })
            vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
            vim.keymap.set('n', '<leader>sg', builtin.live_grep,   { desc = '[S]earch by [G]rep' })
            vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
            vim.keymap.set('n', '<leader>sb', builtin.buffers,     { desc = '[S]earch [B]uffers' })
            vim.keymap.set('n', '<leader>sc', builtin.quickfix,    { desc = '[S]earch Qui[C]kFix' })

            vim.keymap.set('n', '<leader>sG', function() builtin.live_grep({grep_open_files=true}) end, { desc = '[S]earch [G]rep Open File' })
            vim.keymap.set('n', '<leader>fb', ":Telescope file_browser path=%:p:h select_buffer=true<CR>", {desc = '[F]ile [B]rowser'})

            -- Add git mappings
            vim.keymap.set('n', '<A-g><A-b>',  ':Git blame --date=relative --color-by-age<CR>', {silent = true, desc = '[G]it blame'})
            vim.keymap.set('n', '<A-g><A-g>',  ':Git<CR>',                  {silent = true, desc = '[G]it status'})
            vim.keymap.set('n', '<A-g><A-s>',  require('git').git_commits,  {silent = true, desc = '[G]it [S]how'})
            vim.keymap.set('n', '<A-g><A-B>',  require('git').git_bcommits, {silent = true, desc = '[G]it [B]lame current buffer history of file'})

            local telescope = require('telescope')
            local action_state = require('telescope.actions.state')

            local function grep_in_subfolder()
              builtin.find_files({
                prompt_title = "Select folder for grep",
                find_command = { "find", ".", "-type", "d" },
                attach_mappings = function(prompt_bufnr, map)
                  local function grep_selected_dir()
                    local entry = action_state.get_selected_entry()
                    if entry then
                      actions.close(prompt_bufnr)
                      local dir_path = entry.value
                      if vim.fn.isdirectory(dir_path) == 1 then
                        builtin.live_grep({ search_dirs = {dir_path} })
                      else
                        print("Selected path is not a directory")
                      end
                    end
                  end

                  map('i', '<CR>', grep_selected_dir)
                  map('n', '<CR>', grep_selected_dir)

                  return true
                end
              })
            end

            -- Add this to your keybindings section
            vim.keymap.set('n', '<leader>dg', grep_in_subfolder, { desc = '[D]irectory files [G]rep' })

        end
    }
)

table.insert(M,
    -- Fuzzy Finder (files, lsp, etc)
    {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
  }

)

return M
