-- LSP Configuration for Neovim 0.11+
local M = {}

function M.setup()
    vim.api.nvim_create_user_command('LspInfo', function()
        vim.cmd('checkhealth vim.lsp')
    end, { desc = 'Show LSP health information' })
    vim.lsp.inlay_hint.enable(true)

    local servers = {
        'pyright',
        'ruff',
        'lua_ls',
        'ansiblels',
        'rust_analyzer',
        'ts_ls',
        'biome',
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
            
            -- Navigation (gd, gD, gr, gI, gy defined in snacks.lua with picker)
            
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

end

return M
