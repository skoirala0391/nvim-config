require("nvchad.configs.lspconfig").defaults()

-- clangd config (recommended)
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--completion-style=detailed",
    -- "--header-insertion=iwyu",
    "--header-insertion=never",
    "--pch-storage=memory",
  },
})

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
  "pyright",
  "clangd"
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
