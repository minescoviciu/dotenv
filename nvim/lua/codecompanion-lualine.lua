local lualine_require = require('lualine_require')
local M = lualine_require.require("lualine.component"):extend()


local spinner_symbols = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
local spinner_text = ' Thinking '
local req_status_icons = {
  success = "",
  error = "",
  cancelled = "󰜺"
}

function M:start_spinner()
    vim.notify("start_spinner")
    self.processing = true
    self.spinner_index = 1
    self.req_status = nil
end

function M:stop_spinner(request)
    vim.notify("stop_spinner")
    local status = request.data.status
    if status == "success" then
        self.req_status = "success"
    elseif status == "error" then
        self.req_status = "error"
    else
        self.req_status = "cancelled"
    end
    self.processing = false
    vim.defer_fn(function()
        self.req_status = nil
        vim.notify("stop status")
    end, 3000)
end

-- Initializer
function M:init(options)
    M.super.init(self, options)

    local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})
    self.processing = false
    self.spinner_index = 1
    self.req_status = nil

    vim.api.nvim_create_autocmd({"User"}, {
      pattern = "CodeCompanionRequestStarted",
      callback = function()
        self:start_spinner()
      end
    })

    vim.api.nvim_create_autocmd({"User"}, {
      pattern = "CodeCompanionRequestFinished",
      callback = function(request)
        self:stop_spinner(request)
      end
    })

end

function M:update_status()
    if self.processing then
        self.spinner_index = (self.spinner_index % #spinner_symbols) + 1
        return spinner_text .. spinner_symbols[self.spinner_index]
    end
    if self.req_status ~= nil then
        local icon = req_status_icons[self.req_status] or ""
        return icon .. " " .. self.req_status:sub(1,1):upper() .. self.req_status:sub(2)
    end
    return nil
end

return M
