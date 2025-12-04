---@brief
---
--- https://github.com/astral-sh/ruff
---
--- `ruff`, an extremely fast Python linter and formatter, written in Rust
---
--- Ruff can be used to replace Flake8 (plus dozens of plugins), Black, isort,
--- pydocstyle, pyupgrade, autoflake, and more, all while executing tens or
--- hundreds of times faster than any individual tool.

return {
  cmd = { 'ruff', 'server', '--preview' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'ruff.toml',
    '.ruff.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  },
  settings = {
    -- Ruff language server settings
    -- See: https://docs.astral.sh/ruff/editors/settings/
    -- Most configuration should be done via pyproject.toml or ruff.toml
    -- These are runtime settings for the language server itself
    configuration = {
      -- Use default Ruff configuration
    },
    -- Enable organize imports capability
    organizeImports = true,
    -- Enable fix all capability
    fixAll = true,
  },
  on_attach = function(_, bufnr)
    -- Create a command to organize imports
    vim.api.nvim_buf_create_user_command(bufnr, 'LspRuffOrganizeImports', function()
      vim.lsp.buf.code_action({
        context = {
          only = { 'source.organizeImports' },
          diagnostics = {},
        },
        apply = true,
      })
    end, {
      desc = 'Ruff: Organize Imports',
    })

    -- Create a command to fix all auto-fixable issues
    vim.api.nvim_buf_create_user_command(bufnr, 'LspRuffFixAll', function()
      vim.lsp.buf.code_action({
        context = {
          only = { 'source.fixAll' },
          diagnostics = {},
        },
        apply = true,
      })
    end, {
      desc = 'Ruff: Fix All',
    })
  end,
}
