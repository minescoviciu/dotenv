-- LSP Configuration for Neovim 0.11+
local M = {}

function M.setup()
    vim.api.nvim_create_user_command('LspInfo', function()
        vim.cmd('checkhealth vim.lsp')
    end, { desc = 'Show LSP health information' })

    local servers = {
        'pyright',
        'lua_ls',
        'ansiblels',
        'rust_analyzer'
        -- Add more servers as needed
    }
    vim.lsp.enable(servers)
    
    local get_lsp_clients = function()
        return vim
            .iter(vim.lsp.get_clients())
            :map(function(client)
                return client.name
            end)
            :filter(function(name)
                return name ~= "copilot"
            end)
            :totable()
    end

    vim.api.nvim_create_user_command('LspStart', function(info)
            vim.lsp.enable(servers)
    end, {
            desc = 'Enable and launch a language server',
            nargs = '?',
            complete = complete_config,
        })

    vim.api.nvim_create_user_command('LspRestart', function(info)
        local clients = info.fargs

        -- Default to restarting all active servers
        if #clients == 0 then
            clients = get_lsp_clients()
        end

        for _, name in ipairs(clients) do
            if vim.lsp.config[name] == nil then
                vim.notify(("Invalid server name '%s'"):format(name))
            else
                vim.lsp.enable(name, false)
            end
        end

        local timer = assert(vim.uv.new_timer())
        timer:start(500, 0, function()
            for _, name in ipairs(clients) do
                vim.schedule_wrap(function(x)
                    vim.lsp.enable(x)
                end)(name)
            end
        end)
    end, {
            desc = 'Restart the given client(s)',
            nargs = '*',
            complete = complete_client,
        })
    

    vim.api.nvim_create_user_command('LspStop', function(info)
        local clients = info.fargs

        -- Default to disabling all servers on current buffer
        if #clients == 0 then
            clients = get_lsp_clients()
        end

        for _, name in ipairs(clients) do
            if vim.lsp.config[name] == nil then
                vim.notify(("Invalid server name '%s'"):format(name))
            else
                vim.lsp.enable(name, false)
            end
        end
    end, {
            desc = 'Disable and stop the given client(s)',
            nargs = '*',
            complete = complete_client,
        })

    -- Set up common keymaps when LSP attaches
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
            local bufnr = args.buf
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            local opts = { buffer = bufnr }
            
            -- Navigation
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = 'Go to definition' }))
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = 'Go to declaration' }))
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = 'Go to references' }))
            
            -- Documentation
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover documentation' }))
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = 'Signature help' }))
            
            -- Actions
            vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Rename symbol' }))
            vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'Code action' }))
            vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, vim.tbl_extend('force', opts, { desc = 'Format buffer' }))
            
            -- Diagnostics
            vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, vim.tbl_extend('force', opts, { desc = 'Previous diagnostic' }))
            vim.keymap.set('n', ']d', vim.diagnostic.goto_next, vim.tbl_extend('force', opts, { desc = 'Next diagnostic' }))
            vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, vim.tbl_extend('force', opts, { desc = 'Show diagnostic' }))
            vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, vim.tbl_extend('force', opts, { desc = 'Diagnostic list' }))
        end
    })
    

    vim.lsp.config('lua_ls', {
        on_init = function(client)
            if client.workspace_folders then
                local path = client.workspace_folders[1].name
                if
                    path ~= vim.fn.stdpath('config')
                    and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
                then
                    return
                end
            end

            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                runtime = {
                    -- Tell the language server which version of Lua you're using (most
                    -- likely LuaJIT in the case of Neovim)
                    version = 'LuaJIT',
                    -- Tell the language server how to find Lua modules same way as Neovim
                    -- (see `:h lua-module-load`)
                    path = {
                        'lua/?.lua',
                        'lua/?/init.lua',
                    },
                },
                -- Make the server aware of Neovim runtime files
                workspace = {
                    checkThirdParty = false,
                    library = {
                        vim.env.VIMRUNTIME
                        -- Depending on the usage, you might want to add additional paths
                        -- here.
                        -- '${3rd}/luv/library'
                        -- '${3rd}/busted/library'
                    }
                    -- Or pull in all of 'runtimepath'.
                    -- NOTE: this is a lot slower and will cause issues when working on
                    -- your own configuration.
                    -- See https://github.com/neovim/nvim-lspconfig/issues/3189
                    -- library = {
                    --   vim.api.nvim_get_runtime_file('', true),
                    -- }
                }
            })
        end,
        settings = {
            Lua = {}
        }
    })

end

return M
