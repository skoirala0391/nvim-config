local dap = require("dap")
local dapui = require("dapui")

dapui.setup()

-- Always open DAP terminal in a fresh split
dap.defaults.fallback.terminal_win_cmd = "belowright 15split new"

local function dap_cleanup()
  -- close UI + repl
  pcall(dapui.close)
  pcall(dap.repl.close)

  -- terminate session if still alive
  pcall(dap.terminate)
  pcall(dap.close)

  -- delete any leftover dap terminal/repl buffers
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(b)
    -- names are usually like ".../dap-terminal" or "[dap-terminal]"
    if name:match("dap%-terminal") or name:match("dap%-repl") or name:match("%[dap%-terminal%]") then
      pcall(vim.api.nvim_buf_delete, b, { force = true })
    end
  end
end

-- Auto open/close dap-ui (debug sessions)
dap.listeners.after.event_initialized["dapui_auto"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_auto"] = function()
  dap_cleanup()
end
dap.listeners.before.event_exited["dapui_auto"] = function()
  dap_cleanup()
end

-- Optional: expose manual cleanup command
vim.api.nvim_create_user_command("DapReset", dap_cleanup, {})
