local M = {}

function M.setup()
  require("nvchad.configs.lspconfig").defaults()

  local lspconfig = require("lspconfig")

  -- TS/JS IntelliSense (completion, go-to-def, hover, rename, etc.)
  lspconfig.ts_ls.setup({})

  -- ESLint diagnostics + code actions
  lspconfig.eslint.setup({
    on_attach = function(client, bufnr)
      -- prevent eslint-lsp from formatting (let prettier handle formatting)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end,
  })
end

return M
