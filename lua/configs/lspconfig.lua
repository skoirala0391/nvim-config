require("nvchad.configs.lspconfig").defaults()

-- clangd config (recommended)
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--completion-style=detailed",
    "--header-insertion=iwyu",
    "--pch-storage=memory",
  },
})

-- Rust Analyzer configuration (optional but recommended)
vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      cargo = { allFeatures = true },
      checkOnSave = {
        command = "clippy",
      },
    },
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
  "rust_analyzer",
  "clangd"
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
