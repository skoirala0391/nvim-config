require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", "K", function()
  local winid = require('uikit.lsp.hover').get_preview_window()
  if winid then
    vim.api.nvim_set_current_win(winid)
  else
    vim.lsp.buf.hover()
  end
end, { desc = "LSP: Hover Info" })

-- AI Assistant (Avante)
map("n", "<leader>aa", "<cmd>AvanteToggle<cr>", { desc = "AI: Toggle Assistant" })
map("v", "<leader>ae", "<cmd>AvanteEdit<cr>", { desc = "AI: Edit selection" })

map("n", "<A-j>", "<cmd>m .+1<cr>==current", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==current", { desc = "Move line up" })

-- Visual Mode (Moving blocks)
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move block down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move block up" })

map("n", "<leader>rn", function()
  vim.lsp.buf.rename()
end, { desc = "Java: Rename Symbol" })

-- Refactor (Opens the refactor menu)
map("n", "<leader>rf", function()
  require("jdtls").extract_variable()
end, { desc = "Java: Extract Variable" })

map("v", "<leader>rf", function()
  require("jdtls").extract_method(true)
end, { desc = "Java: Extract Method" })

-- Generate Getters/Setters
-- map("n", "<leader>jg", function()
--   require("jdtls").generate_accessor()
-- end, { desc = "Java: Generate Getters/Setters" })

-- LSP Navigation & Info
map("n", "K", function() vim.lsp.buf.hover() end, { desc = "LSP: Hover Info" })
map("n", "gd", function() vim.lsp.buf.definition() end, { desc = "LSP: Go to Definition" })
map("n", "gi", function() vim.lsp.buf.implementation() end, { desc = "LSP: Go to Implementation" })
map("n", "gr", function() vim.lsp.buf.references() end, { desc = "LSP: Show References" })
map("n", "<leader>ca", function() vim.lsp.buf.code_action() end, { desc = "LSP: Code Action" })
map("n", "<leader>oi", function()
  local status_ok, jdtls = pcall(require, "jdtls")
  if status_ok then
    jdtls.organize_imports()
  else
    print "jdtls not loaded yet!"
  end
end, { desc = "Java: Optimize Imports" })

map("n", "<leader>jM", function()
  require('jdtls.dap').setup_dap_main_class_configs() -- Re-scan for main methods
  require('dap').continue() -- This will trigger the "Select Config" menu automatically
end, { desc = "Java: Pick & Run" })

-- General Diagnostics
map("n", "gl", function()
  vim.diagnostic.open_float(nil, { focus = false })
end, { desc = "Show diagnostic" })

-- Java Testing (JUnit)
map("n", "<leader>tr", function() require("neotest").run.run() end, { desc = "Run Nearest Test" })
map("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "Run File" })
map("n", "<leader>ts", function() require("neotest").summary.toggle() end, { desc = "Toggle Test Summary" })
map("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end, { desc = "Show Test Output" })
map("n", "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, { desc = "Debug Nearest Test" })

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Maven: create module + add to parent pom.xml
vim.api.nvim_create_user_command("MavenNewModule", function()
  require("tools.maven").new_module()
end, {})

vim.api.nvim_create_user_command("MavenPruneModules", function()
  require("tools.maven").prune_modules()
end, {})

vim.keymap.set("n", "<leader>mm", "<cmd>MavenNewModule<cr>", { desc = "Maven: New module" })
vim.keymap.set("n", "<leader>mP", "<cmd>MavenPruneModules<cr>", { desc = "Maven: Prune missing modules" })
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
