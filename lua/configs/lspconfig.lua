require("nvchad.configs.lspconfig").defaults()

-- Pyright configuration (IntelliSense tuning)
vim.lsp.config("pyright", {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic", -- off | basic | strict
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
      },
    },
  },
})

local servers = {
  "html",
  "cssls",
  "ts_ls",
  "eslint",
  "pyright"
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
